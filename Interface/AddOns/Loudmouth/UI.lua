-- Loudmouth UI Implementation

-- ============================================================================
-- GenerateMacros — refactored macro generation engine
-- Uses canonical action order from Loudmouth.ActionOrderByClass
-- ============================================================================

function Loudmouth.GenerateMacros()
    -- Resolve player class to canonical action order
    local _, classFile = UnitClass("player")
    local classKey = classFile and tostring(classFile):lower():gsub("^%l", string.upper)
    local actionOrder = Loudmouth.ActionOrderByClass[classKey]

    if not actionOrder or #actionOrder == 0 then
        print("[Loudmouth] ERROR: No action order configured for class " ..
            tostring(classKey) .. ". Aborting macro generation.")
        return false
    end

    if #actionOrder > 99 then
        print("[Loudmouth] ERROR: Action order exceeds 99-slot limit.")
        return false
    end

    local N = #actionOrder

    -- ========================================================================
    -- B. Cleanup Phase (Deletes Stale Macros — BEFORE capacity check)
    -- ========================================================================

    -- Build the set of desired macro names for this class order
    local desiredNames = {}
    for i = 1, N do
        desiredNames[Loudmouth.MakeMacroName(i)] = true
    end

    -- Collect stale macro names:
    --   1. Positional macros with index > N (e.g., LM_08 when N=5)
    --   2. Legacy abbrev macros (LM_ABCD pattern — no longer valid)
    -- Only delete macros that are NOT in the desired set.
    local stale = {}
    local preCleanupCount = select(1, GetNumMacros())
    for i = 1, preCleanupCount do
        local n = GetMacroInfo(i)
        if n and not desiredNames[n] then
            -- Check for stale positional macro (index > N)
            local slotNum = n:match("^LM_(%d+)$")
            if slotNum then
                local num = tonumber(slotNum)
                if num and num > N then
                    stale[n] = true
                end
            end
        end
    end

    -- Delete all stale macros at once (avoids index-shifting issues)
    for name in pairs(stale) do
        if InCombatLockdown() then
            Loudmouth.pendingMacroUpdate = true -- Queue everything for later
            return false
        end
        DeleteMacro(name)
    end

    -- ========================================================================
    -- C. Capacity Check — REFRESH COUNTS AFTER CLEANUP
    -- ========================================================================

    -- Refresh macro count after deletions so freed slots are reflected.
    local gCount = select(1, GetNumMacros())

    local neededSlots = #actionOrder

    -- Count LM_XX macros that currently exist (managed by Loudmouth)
    local currentManaged = 0
    for i = 1, gCount do
        local n, _, _ = GetMacroInfo(i)
        if n and n:match("^LM_%d%d$") then
            currentManaged = currentManaged + 1
        end
    end

    -- Formula: existing_g_macros - managed_old + new_needed <= 120
    if (gCount - currentManaged + neededSlots) > 120 then
        local free = 120 - (gCount - currentManaged)
        print("[Loudmouth] ERROR: Not enough macro slots! Needed=" .. neededSlots .. " Free=" .. free)
        return false
    end

    -- ========================================================================
    -- D. Reconciliation Loop
    -- ========================================================================

    local created = 0
    local updated = 0
    local skipped = 0

    -- Track slots that could not be resolved so we can delete stale macros
    -- from a previous run (possibly a different class).
    local unresolvable = {}

    for i = 1, N do
        local actionKey = actionOrder[i]
        local macroName = Loudmouth.MakeMacroName(i)
        local icon = 134400 -- default icon (voidwalker's eye)
        local body
        local skip = false

        -- Handle "Healing Items" specially: not a real spell, use pre-built body
        if actionKey == "Healing Items" then
            local healSeq =
                "#showtooltip\n"
                .. "/castsequence reset=combat item:5512,item:5511,item:5509,item:5510,item:9421\n"
                .. "/run Loudmouth.Trigger(\"%s\")"
            body = string.format(healSeq, actionKey)
        else
            -- Resolve spell info via alias map
            local spellName = Loudmouth._ResolveSpellName(actionKey)
            if spellName then
                local _, _, spellIcon = GetSpellInfo(spellName)
                icon = spellIcon or 134400
                body = string.format(
                    "/run Loudmouth.Trigger(\"%s\")\n/cast %s",
                    actionKey, spellName)
            else
                -- Spell not found — mark for deletion (old macro may contain
                -- a different class's spell) and skip creation.
                skipped = skipped + 1
                unresolvable[macroName] = true
                skip = true
            end
        end

        if not skip and body then
            -- Check if macro already exists
            local idx = Loudmouth.MacroIndexByName(macroName)

            if idx == 0 then
                -- Create new macro
                if Loudmouth.SafeCreateMacro(macroName, icon, body) then
                    created = created + 1
                end
            else
                -- Update existing if content differs (idempotency)
                if Loudmouth.SafeEditMacro(idx, macroName, icon, body) then
                    updated = updated + 1
                end
            end
        end
    end

    -- ========================================================================
    -- E. Delete unresolvable slots — stale LM_XX macros from other classes
    -- ========================================================================
    for macroName in pairs(unresolvable) do
        local idx = Loudmouth.MacroIndexByName(macroName)
        if idx > 0 then
            if InCombatLockdown() then
                Loudmouth.pendingMacroUpdate = true
                print(string.format(
                    "[Loudmouth] Cannot delete %s (in combat) — queued for later.",
                    macroName))
                return false
            end
            DeleteMacro(macroName)
        end
    end

    print(string.format(
        "[Loudmouth] Generated %d macros (%d updated, %d created, %d skipped).",
        created + updated, updated, created, skipped))
    return true
end

-- Auto-generate macros on first login. Fires only once per session.
function Loudmouth.AutoGenerateOnLogin()
    if Loudmouth.macroGenerationDone then
        return
    end
    if InCombatLockdown() then
        Loudmouth.pendingMacroUpdate = true
        return
    end

    C_Timer.After(0.35, function()
        if InCombatLockdown() then
            -- Still in combat — defer entirely.  The regen handler will
            -- pick this up after combat ends.
            Loudmouth.pendingMacroUpdate = true
            return
        end
        Loudmouth.GenerateMacros()
        Loudmouth.macroGenerationDone = true

        -- Flush any pending updates that queued during initial login
        if Loudmouth.pendingMacroUpdate then
            Loudmouth.GenerateMacros()
            Loudmouth.pendingMacroUpdate = false
        end
    end)
end

-- Set up the init frame for event-driven macro generation
if not Loudmouth.InitFrame then
    Loudmouth.InitFrame = CreateFrame("Frame")
end
Loudmouth.InitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
Loudmouth.InitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
Loudmouth.InitFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then
        Loudmouth.AutoGenerateOnLogin()
    elseif event == "PLAYER_REGEN_ENABLED" and Loudmouth.pendingMacroUpdate then
        Loudmouth.GenerateMacros()
        Loudmouth.pendingMacroUpdate = false
    end
end)

-- ============================================================================
-- UI Construction
-- ============================================================================

local function InitUI()
    -- ========================================================================
    -- Fix 1: Ensure SavedVariables are initialized BEFORE any reads/writes
    -- ========================================================================
    LoudmouthDB = LoudmouthDB or {}
    if not LoudmouthDB.showZoneDebug then
        LoudmouthDB.showZoneDebug = false
    end

    -- Ensure Loudmouth table exists and run the strict filter pipeline
    -- BEFORE building any frames.
    Loudmouth = Loudmouth or {}
    Loudmouth.db = Loudmouth.db or { showZoneDebug = false }

    -- Restore persisted debug state from SavedVariables
    if LoudmouthDB.showZoneDebug ~= nil then
        Loudmouth.db.showZoneDebug = LoudmouthDB.showZoneDebug
    end
    Loudmouth.ShowZoneDebug = Loudmouth.db.showZoneDebug

    Loudmouth.FilterPersonalities()

    -- ========================================================================
    -- Fix 2: Synchronously set PendingZoneComment on startup so the very first
    -- macro click (before any zone-change event fires) will trigger a zone
    -- comment.  Do NOT rely on timers for this flag.
    -- ========================================================================
    if not Loudmouth.PendingZoneComment then
        Loudmouth.PendingZoneComment = true
    end

    -- Idempotency guard: don't rebuild the UI if it's already visible
    if Loudmouth.UIFrame and Loudmouth.UIFrame:IsObjectType("Frame") and Loudmouth.UIFrame:IsVisible() then
        Loudmouth.UIFrame:Raise()
        return
    end

    -- Layout constants — single source of truth so spacing stays consistent.
    local PANEL_W, PANEL_H = 320, 300
    local PAD = 16                 -- inner padding from panel edges
    local CONTENT_W = PANEL_W - (PAD * 2)
    local BUTTON_H = 26
    local ROW_GAP = 10             -- vertical gap between stacked controls

    -- Main Frame
    -- Using BackdropTemplate for Classic Era compatibility
    Loudmouth.UIFrame = CreateFrame("Frame", "LoudmouthConfigFrame", UIParent, "BackdropTemplate")
    Loudmouth.UIFrame:SetSize(PANEL_W, PANEL_H)
    Loudmouth.UIFrame:SetPoint("CENTER")
    Loudmouth.UIFrame:SetFrameStrata("DIALOG")

    -- Classic-Era safety: the BackdropTemplate mixin (which provides SetBackdrop)
    -- is not always present on the frame at creation time. Mix it in explicitly
    -- if the method is missing, then apply the backdrop.
    if not Loudmouth.UIFrame.SetBackdrop and BackdropTemplateMixin then
        Mixin(Loudmouth.UIFrame, BackdropTemplateMixin)
        if Loudmouth.UIFrame.OnBackdropLoaded then
            Loudmouth.UIFrame:OnBackdropLoaded()
        end
    end
    if Loudmouth.UIFrame.SetBackdrop then
        Loudmouth.UIFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    Loudmouth.UIFrame:SetMovable(true)
    Loudmouth.UIFrame:EnableMouse(true)
    Loudmouth.UIFrame:RegisterForDrag("LeftButton")
    Loudmouth.UIFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    Loudmouth.UIFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Close button (X) — Blizzard's standard close widget, anchored to the corner.
    local closeButton = CreateFrame("Button", "$parentCloseButton", Loudmouth.UIFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function()
        Loudmouth.UIFrame:Hide()
    end)

    -- Title label — canonical pattern: CreateFontString with explicit font name
    local title = Loudmouth.UIFrame:CreateFontString()
    title:SetFontObject("GameFontNormalLarge")
    title:SetPoint("TOP", 0, -PAD)
    title:SetText("Loudmouth Configuration")
    title:Show()

    -- Player Info label — canonical pattern: CreateFontString with explicit font name
    local infoText = Loudmouth.UIFrame:CreateFontString()
    infoText:SetFontObject("GameFontHighlight")
    infoText:SetPoint("TOP", title, "BOTTOM", 0, -ROW_GAP)
    infoText:SetJustifyH("CENTER")
    infoText:Show()

    local function UpdatePlayerInfo()
        local race = Loudmouth.GetRace()
        local class = Loudmouth.GetClass()
        infoText:SetText(string.format("Race: %s | Class: %s", race, class))
    end

    -- Personality Dropdown (Classic Era compatible)
    -- Uses UIDropDownMenuTemplate — the correct frame type for Classic Era dropdowns.
    local dropdown = CreateFrame("Frame", "LoudmouthPersonalityDropdown", Loudmouth.UIFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOP", infoText, "BOTTOM", 0, -(ROW_GAP + 14))
    UIDropDownMenu_SetWidth(dropdown, CONTENT_W - 24)
    dropdown:Show()

    -- Label above the dropdown so the control reads clearly.
    local dropdownLabel = Loudmouth.UIFrame:CreateFontString()
    dropdownLabel:SetFontObject("GameFontNormalSmall")
    dropdownLabel:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 3)
    dropdownLabel:SetText("Personality")

    -- Build an ordered list of personality keys from the engine-filtered table.
    -- The engine already handled all filtering — just display what's available.
    local availablePersonalities = Loudmouth.AvailablePersonalities or {}

    if Loudmouth.DebugMode then
        print("|cFFFF8000[Loudmouth Debug]|r Loaded "
            .. #availablePersonalities .. " personality(s):")
        for _, pid in ipairs(availablePersonalities) do
            print("|cFFFF8000[Loudmouth Debug]|r   " .. pid)
        end
    end

    -- Initialize: (self = dropdown frame, level = dropdown level)
    local function InitializeDropDown(_self, level)
        -- CRITICAL: ALWAYS start by calling UIDropDownMenu_CreateInfo() — NEVER pass a bare {} table
        local info = UIDropDownMenu_CreateInfo()

        if #availablePersonalities == 0 then
            -- Empty case: show a disabled label
            info.text = "No personalities available"
            info.value = nil
            info.notCheckable = true
            info.disabled = true
            info.isNotRadio = true
            UIDropDownMenu_AddButton(info, level)
        else
            for _, personalityId in ipairs(availablePersonalities) do
                info.text = personalityId
                info.value = personalityId
                info.notCheckable = true
                info.func = function(button)
                    Loudmouth.CurrentPersonality = button.value
                    UIDropDownMenu_SetText(dropdown, button.value)
                    print("|cFFFF8000[Loudmouth]|r Selected:", button.value)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropDown)
    if Loudmouth.CurrentPersonality then
        UIDropDownMenu_SetText(dropdown, Loudmouth.CurrentPersonality)
    else
        UIDropDownMenu_SetText(dropdown, "No personalities available")
    end

    -- Button factory: Blizzard's UIPanelButtonTemplate gives us proper, readable
    -- text with built-in normal/hover/pushed states — no hand-rolled textures.
    local function MakeButton(label, anchorTo, onClick)
        local b = CreateFrame("Button", nil, Loudmouth.UIFrame, "UIPanelButtonTemplate")
        b:SetSize(CONTENT_W, BUTTON_H)
        if anchorTo then
            b:SetPoint("TOP", anchorTo, "BOTTOM", 0, -ROW_GAP)
        else
            b:SetPoint("TOP", dropdown, "BOTTOM", 0, -(ROW_GAP + 6))
        end
        b:SetText(label)
        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", onClick)
        return b
    end

    -- Debug Mode Toggle
    local debugButton = MakeButton("Debug Mode: " .. (Loudmouth.DebugMode and "ON" or "OFF"), nil, nil)
    debugButton:SetScript("OnClick", function(self)
        Loudmouth.DebugMode = not Loudmouth.DebugMode
        self:SetText("Debug Mode: " .. (Loudmouth.DebugMode and "ON" or "OFF"))
    end)

    -- Macro Generator Button — calls the refactored engine directly
    local macroButton = MakeButton("Generate Macros", debugButton, function()
        Loudmouth.GenerateMacros()
    end)

    local copyErrorsButton = MakeButton("Copy Errors", macroButton, function()
        if Loudmouth.CopyChat and Loudmouth.CopyChat.Show then
            Loudmouth.CopyChat.Show()
        else
            print("|cFFFF0000Loudmouth: CopyChat module not loaded.|r")
        end
    end)

    -- Zone Debug Toggle Button (Fix 6: persists across /reloadui)
    local zoneDebugButton = MakeButton(
        Loudmouth.ShowZoneDebug and "Disable Zone Debug" or "Enable Zone Debug", copyErrorsButton, nil)
    zoneDebugButton:SetScript("OnClick", function(self)
        Loudmouth.db.showZoneDebug = not Loudmouth.db.showZoneDebug
        Loudmouth.ShowZoneDebug = Loudmouth.db.showZoneDebug
        if LoudmouthDB then
            LoudmouthDB.showZoneDebug = Loudmouth.db.showZoneDebug
        end
        self:SetText(Loudmouth.ShowZoneDebug and "Disable Zone Debug" or "Enable Zone Debug")
    end)

    UpdatePlayerInfo()

    -- Size the panel to hug its content. Sum the vertical layout deterministically
    -- from the constants (robust — no reliance on live GetTop/GetBottom coords):
    --   pad + title + gap + info + gap + dropdown + (gap+6) + 4 buttons/gaps + pad
    local titleH, infoH, dropdownH = 18, 14, 32
    local contentH = PAD + titleH + ROW_GAP + infoH + (ROW_GAP + 14) + dropdownH
        + (ROW_GAP + 6)                         -- extra space before first button
        + (BUTTON_H * 4) + (ROW_GAP * 3)        -- four stacked buttons + gaps
        + PAD
    Loudmouth.UIFrame:SetHeight(contentH)

    Loudmouth.UIFrame:Show()
end

-- Safe Initialization
local status, err = pcall(InitUI)
if not status then
    print("|cFFFF0000Loudmouth UI Error:|r " .. err)
end

-- Slash Commands
SLASH_LOUDMOUTH1 = "/lm"
SLASH_LOUDMOUTH2 = "/loudmouth"
SlashCmdList["LOUDMOUTH"] = function()
    if Loudmouth.UIFrame and Loudmouth.UIFrame:IsShown() then
        Loudmouth.UIFrame:Hide()
    elseif Loudmouth.UIFrame then
        Loudmouth.UIFrame:Show()
    else
            print("|cFFFFFF00Loudmouth: UI failed to initialize. Please reload.|r")
    end
end