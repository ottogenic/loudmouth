-- Loudmouth UI Implementation

local function InitUI()
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
    local title = Loudmouth.UIFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -PAD)
    title:SetText("Loudmouth Configuration")
    title:Show()

    -- Player Info label — canonical pattern: CreateFontString with explicit font name
    local infoText = Loudmouth.UIFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
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
    -- See: WeaponSwingTimer, MavenTweex, and other Classic-era addons for the pattern.
    local dropdown = CreateFrame("Frame", "LoudmouthPersonalityDropdown", Loudmouth.UIFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOP", infoText, "BOTTOM", 0, -(ROW_GAP + 14))
    UIDropDownMenu_SetWidth(dropdown, CONTENT_W - 24)
    dropdown:Show()

    -- Label above the dropdown so the control reads clearly.
    local dropdownLabel = Loudmouth.UIFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dropdownLabel:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 3)
    dropdownLabel:SetText("Personality")

    local function GetPersonalitySuffix(id)
        if not id then return "None" end
        local s = id
        local prefixes = {
            "Human", "Dwarf", "NightElf", "Undead", "Orc", "Tauren", "Gnome", "Troll",
            "Male", "Female",
            "Warrior", "Paladin", "Hunter", "Rogue", "Mage", "Priest", "Shaman", "Warlock", "Druid"
        }
        for _, p in ipairs(prefixes) do
            s = s:gsub(p, "")
        end
        return s
    end

    -- Build an ordered list of personality keys from the loaded personality table.
    local availablePersonalities = {}
    for personalityId, _ in pairs(Loudmouth.Personalities) do
        table.insert(availablePersonalities, personalityId)
    end
    Loudmouth.AvailablePersonalities = availablePersonalities

    print("|cFFFF8000[Loudmouth Debug]|r Loaded "
        .. #availablePersonalities .. " personality(s):")
    for _, pid in ipairs(availablePersonalities) do
        print("|cFFFF8000[Loudmouth Debug]|r   " .. pid
            .. " -> suffix=\"" .. GetPersonalitySuffix(pid) .. "\"")
    end

    -- Initialize: (self = dropdown frame, level = dropdown level)
    local function InitializeDropDown(_self, level)
        -- CRITICAL: ALWAYS start by calling UIDropDownMenu_CreateInfo() — NEVER pass a bare {} table
        local info = UIDropDownMenu_CreateInfo()

        local playerClassName = string.lower(select(2, UnitClass("player")))

        for _, personalityId in ipairs(Loudmouth.AvailablePersonalities) do
            local lowerId = string.lower(personalityId)
            -- Only include if the character's class appears in the personality filename
            if lowerId:find(playerClassName) then
                info.text = GetPersonalitySuffix(personalityId)
                info.value = personalityId
                info.notCheckable = true
                info.func = function(button)
                    Loudmouth.CurrentPersonality = button.value
                    UIDropDownMenu_SetText(dropdown, GetPersonalitySuffix(button.value))
                    print("|cFFFF8000[Loudmouth]|r Selected:", button.value)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end

    UIDropDownMenu_Initialize(dropdown, InitializeDropDown)
    UIDropDownMenu_SetText(dropdown, GetPersonalitySuffix(Loudmouth.CurrentPersonality) or "Select...")

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

    -- Macro Generator Button — canonical visible-button pattern
    local function GenerateMacros()
        if not Loudmouth.CurrentPersonality then
            -- Try to auto-detect or fallback to first available
            Loudmouth.AutoDetectPersonality()
        end

        local personality = Loudmouth.Personalities[Loudmouth.CurrentPersonality]

        if not personality then
            print("|cFFFFFF00Loudmouth: No personality found for " .. tostring(Loudmouth.CurrentPersonality) .. "!|r")
            return
        end

        print("|cFF00FF00Loudmouth: Creating macros for known spells...|r")

        local createdCount = 0
        for action, _ in pairs(personality.actions) do
            if action ~= "Generic" then
                local _, _, icon, _, _, _, spellID = GetSpellInfo(action)
                if spellID and IsSpellKnown(spellID) then
                    local macroName = "Loudmouth_" .. action
                    local macroBody = string.format("/run Loudmouth.Trigger(\"%s\")\n/cast %s", action, action)

                    -- CreateMacro(iconFileID, body, perCharacter)
                    CreateMacro(macroName, icon or 134400, macroBody, true)
                    createdCount = createdCount + 1
                end
            end
        end

        print(string.format("|cFF00FF00Loudmouth: Successfully created %d macros!|r", createdCount))
    end

    local macroButton = MakeButton("Generate Macros", debugButton, GenerateMacros)

    MakeButton("Copy Errors", macroButton, function()
        if Loudmouth.CopyChat and Loudmouth.CopyChat.Show then
            Loudmouth.CopyChat.Show()
        else
            print("|cFFFF0000Loudmouth: CopyChat module not loaded.|r")
        end
    end)

    UpdatePlayerInfo()

    -- Size the panel to hug its content. Sum the vertical layout deterministically
    -- from the constants (robust — no reliance on live GetTop/GetBottom coords):
    --   pad + title + gap + info + gap + dropdown + (gap+6) + 3 buttons/gaps + pad
    local titleH, infoH, dropdownH = 18, 14, 32
    local contentH = PAD + titleH + ROW_GAP + infoH + (ROW_GAP + 14) + dropdownH
        + (ROW_GAP + 6)                        -- extra space before first button
        + (BUTTON_H * 3) + (ROW_GAP * 2)        -- three stacked buttons + gaps
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
