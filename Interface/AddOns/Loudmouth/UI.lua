-- Loudmouth UI and macro generation

Loudmouth.ResponseMacroOrder = { "Yes", "No", "Thank", "RUN", "Rude" }
Loudmouth.ResponseMacroNames = {
    ["Yes"] = "LM_YES",
    ["No"] = "LM_NO",
    ["Thank"] = "LM_THANK",
    ["RUN"] = "LM_RUN",
    ["Rude"] = "LM_RUDE",
}

function Loudmouth.BuildResponseMacroBody(responseKind)
    return string.format('/run Loudmouth.Respond("%s")', responseKind)
end

local function GetAvailableResponseKinds()
    local available = {}
    local personality = Loudmouth.Personalities and Loudmouth.Personalities[Loudmouth.CurrentPersonality]
    for _, responseKind in ipairs(Loudmouth.ResponseMacroOrder) do
        local response = personality and personality.responses and personality.responses[responseKind]
        if type(response) == "table" and type(response.target) == "table" and #response.target > 0
                and type(response.noTarget) == "table" and #response.noTarget > 0 then
            available[#available + 1] = responseKind
        end
    end
    return available
end

local function IsResponseMacroName(name)
    for _, macroName in pairs(Loudmouth.ResponseMacroNames) do
        if name == macroName then return true end
    end
    return false
end

function Loudmouth.BuildMacroBody(actionKey, spellName)
    if actionKey == "Healing Items" then
        local body = "#showtooltip\n/run Loudmouth.Trigger(\"%s\")\n"
            .. "/use Major Healthstone\n/use Greater Healthstone\n/use Healthstone\n"
            .. "/use Lesser Healthstone\n/use Minor Healthstone"
        return string.format(body, actionKey)
    end

    if actionKey == "Soulstone" and spellName then
        local body = "#showtooltip\n/run Loudmouth.Trigger(\"Soulstone\",\"target\")\n"
            .. "/use Major Soulstone\n/use Greater Soulstone\n/use Soulstone\n"
            .. "/use Lesser Soulstone\n/use Minor Soulstone\n/cast %s"
        return string.format(body, spellName)
    end

    if spellName then
        local targetUnit = Loudmouth.TargetedActions[actionKey] and ",\"target\"" or ""
        return string.format("/run Loudmouth.Trigger(\"%s\"%s)\n/cast %s", actionKey, targetUnit, spellName)
    end
end

function Loudmouth.GenerateMacros()
    local _, classFile = UnitClass("player")
    local classKey = classFile and tostring(classFile):lower():gsub("^%l", string.upper)
    local actionOrder = Loudmouth.ActionOrderByClass[classKey]
    local hasActionOrder = type(actionOrder) == "table" and #actionOrder > 0
    if not hasActionOrder then
        actionOrder = {}
        print("[Loudmouth] No spell macros configured for " .. tostring(classKey) .. "; generating responses only.")
    end
    if #actionOrder > 99 then
        print("[Loudmouth] ERROR: Action order exceeds 99-slot limit.")
        return false
    end

    local resolvedSpells, desiredNames = {}, {}
    local responseKinds = GetAvailableResponseKinds()
    local resolvableCount = 0
    for index, actionKey in ipairs(actionOrder) do
        desiredNames[Loudmouth.MakeMacroName(index)] = true
        if actionKey == "Healing Items" then
            resolvableCount = resolvableCount + 1
        else
            local spellName = Loudmouth._ResolveSpellName(actionKey)
            if spellName then
                resolvedSpells[actionKey] = spellName
                resolvableCount = resolvableCount + 1
            end
        end
    end
    for _, responseKind in ipairs(responseKinds) do
        desiredNames[Loudmouth.ResponseMacroNames[responseKind]] = true
    end

    local stale = {}
    local macroCount = select(1, GetNumMacros())
    for index = 1, macroCount do
        local name = GetMacroInfo(index)
        if name and not desiredNames[name] then
            if IsResponseMacroName(name) then
                stale[name] = true
            elseif hasActionOrder then
                local slot = tonumber(name:match("^LM_(%d+)$"))
                if slot and (slot < 1 or slot > #actionOrder) then stale[name] = true end
            end
        end
    end
    for name in pairs(stale) do
        if InCombatLockdown() then
            Loudmouth.pendingMacroUpdate = true
            return false
        end
        DeleteMacro(name)
    end


    -- Remove unresolved managed slots before checking capacity or creating new
    -- macros so their occupied slots are immediately reusable.
    for index, actionKey in ipairs(actionOrder) do
        if actionKey ~= "Healing Items" and not resolvedSpells[actionKey] then
            local macroIndex = Loudmouth.MacroIndexByName(Loudmouth.MakeMacroName(index))
            if macroIndex > 0 then
                if InCombatLockdown() then
                    Loudmouth.pendingMacroUpdate = true
                    return false
                end
                DeleteMacro(macroIndex)
            end
        end
    end

    macroCount = select(1, GetNumMacros())
    local managedCount = 0
    for index = 1, macroCount do
        local name = GetMacroInfo(index)
        if name and ((hasActionOrder and name:match("^LM_%d%d$")) or Loudmouth.ResponseMacroNames.Yes == name
                or Loudmouth.ResponseMacroNames.No == name or Loudmouth.ResponseMacroNames.Thank == name
                or Loudmouth.ResponseMacroNames.RUN == name or Loudmouth.ResponseMacroNames.Rude == name) then
            managedCount = managedCount + 1
        end
    end

    local neededSlots = resolvableCount + #responseKinds
    if macroCount - managedCount + neededSlots > 120 then
        print("[Loudmouth] ERROR: Not enough global macro slots.")
        return false
    end

    local created, updated, skipped = 0, 0, 0
    for index, actionKey in ipairs(actionOrder) do
        local macroName = Loudmouth.MakeMacroName(index)
        local spellName = resolvedSpells[actionKey]
        local body = actionKey == "Healing Items" and Loudmouth.BuildMacroBody(actionKey)
            or (spellName and Loudmouth.BuildMacroBody(actionKey, spellName))
        if body then
            local icon = 134400
            if spellName then
                local _, _, spellIcon = GetSpellInfo(spellName)
                icon = spellIcon or icon
            end
            local macroIndex = Loudmouth.MacroIndexByName(macroName)
            if macroIndex == 0 then
                if Loudmouth.SafeCreateMacro(macroName, icon, body) then created = created + 1 end
            elseif Loudmouth.SafeEditMacro(macroIndex, macroName, icon, body) then
                updated = updated + 1
            end
        else
            skipped = skipped + 1
        end
    end

    for _, responseKind in ipairs(responseKinds) do
        local macroName = Loudmouth.ResponseMacroNames[responseKind]
        local body = Loudmouth.BuildResponseMacroBody(responseKind)
        local macroIndex = Loudmouth.MacroIndexByName(macroName)
        if macroIndex == 0 then
            if Loudmouth.SafeCreateMacro(macroName, 134400, body) then created = created + 1 end
        elseif Loudmouth.SafeEditMacro(macroIndex, macroName, 134400, body) then
            updated = updated + 1
        end
    end

    print(string.format(
        "[Loudmouth] Generated %d macros (%d updated, %d created, %d skipped).",
        created + updated, updated, created, skipped))
    return true
end

function Loudmouth.AutoGenerateOnLogin()
    if Loudmouth.macroGenerationDone then return end
    if InCombatLockdown() then
        Loudmouth.pendingMacroUpdate = true
        return
    end

    C_Timer.After(0.35, function()
        if InCombatLockdown() then
            Loudmouth.pendingMacroUpdate = true
            return
        end
        Loudmouth.GenerateMacros()
        Loudmouth.macroGenerationDone = true
        if Loudmouth.pendingMacroUpdate then
            Loudmouth.GenerateMacros()
            Loudmouth.pendingMacroUpdate = false
        end
    end)
end

if not Loudmouth.InitFrame then Loudmouth.InitFrame = CreateFrame("Frame") end
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

local function EnsureBackdrop(frame)
    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
        if frame.OnBackdropLoaded then frame:OnBackdropLoaded() end
    end
end

local function SetSolidBackdrop(frame, red, green, blue, alpha, borderRed, borderGreen, borderBlue)
    EnsureBackdrop(frame)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(red, green, blue, alpha)
    frame:SetBackdropBorderColor(borderRed or red, borderGreen or green, borderBlue or blue, 1)
end

local function CreateLabel(parent, fontObject, text, anchor, relativeTo, relativePoint, x, y)
    local label = parent:CreateFontString()
    label:SetFontObject(fontObject)
    label:SetPoint(anchor, relativeTo or parent, relativePoint or anchor, x or 0, y or 0)
    label:SetText(text)
    return label
end

local function MakeButton(parent, name, label, width, height, onClick)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(label)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", onClick)
    return button
end

local function FormatPercent(value)
    value = math.floor(value * 10 + 0.5) / 10
    if value == math.floor(value) then return string.format("%d%%", value) end
    return string.format("%.1f%%", value)
end

local function SortedChanceItems(personality, kind)
    local items = {}
    if type(personality) ~= "table" then return items end

    if kind == "spell" then
        local _, classFile = UnitClass("player")
        local classKey = classFile and tostring(classFile):lower():gsub("^%l", string.upper)
        for _, action in ipairs(Loudmouth.ActionOrderByClass[classKey] or {}) do
            local entry = personality.actions and personality.actions[action]
            if type(entry) == "table" then
                items[#items + 1] = { key = action, label = action, default = entry.weight or 1 }
            end
        end
    elseif kind == "zone" then
        for zoneName, entry in pairs(personality.zones or {}) do
            if type(entry) == "table" and type(entry.lines) == "table" then
                items[#items + 1] = {
                    key = zoneName,
                    label = zoneName,
                    default = entry.weight or Loudmouth.DefaultZoneChance,
                }
            end
        end
        for parentName, parentEntry in pairs(personality.subzones or {}) do
            if type(parentEntry) == "table" and type(parentEntry.lines) == "table" then
                items[#items + 1] = {
                    key = parentName,
                    label = parentName,
                    default = parentEntry.weight or Loudmouth.DefaultZoneChance,
                }
            elseif type(parentEntry) == "table" then
                for subzoneName, entry in pairs(parentEntry) do
                    if type(entry) == "table" and type(entry.lines) == "table" then
                        local key = parentName .. " / " .. subzoneName
                        items[#items + 1] = {
                            key = key,
                            label = key,
                            default = entry.weight or Loudmouth.DefaultZoneChance,
                        }
                    end
                end
            end
        end
    elseif kind == "target" then
        local seen = {}
        local function AddTargets(bucket, suffix)
            for targetName, entry in pairs(bucket or {}) do
                if not seen[targetName] and type(entry) == "table" then
                    seen[targetName] = true
                    items[#items + 1] = {
                        key = targetName,
                        label = targetName .. suffix,
                        default = entry.weight or Loudmouth.DefaultTargetChance,
                    }
                end
            end
        end
        AddTargets(personality.hates and personality.hates.entities, " (disliked)")
        AddTargets(personality.likes and personality.likes.entities, " (liked)")
    end

    table.sort(items, function(left, right) return left.label < right.label end)
    return items
end

local function InitUI()
    LoudmouthDB = LoudmouthDB or {}
    if LoudmouthDB.showZoneDebug == nil then LoudmouthDB.showZoneDebug = false end
    if LoudmouthDB.debugMode == nil then LoudmouthDB.debugMode = false end
    if type(LoudmouthDB.cooldownTime) ~= "number" then LoudmouthDB.cooldownTime = 5 end
    Loudmouth.ShowZoneDebug = LoudmouthDB.showZoneDebug
    Loudmouth.DebugMode = LoudmouthDB.debugMode
    Loudmouth.CooldownTime = LoudmouthDB.cooldownTime

    Loudmouth.FilterPersonalities()
    for _, personalityId in ipairs(Loudmouth.AvailablePersonalities or {}) do
        if personalityId == LoudmouthDB.currentPersonality then
            Loudmouth.CurrentPersonality = personalityId
            break
        end
    end
    Loudmouth.GetProfileSettings()
    Loudmouth.PendingZoneComment = true

    if Loudmouth.UIFrame and Loudmouth.UIFrame:IsObjectType("Frame") then
        Loudmouth.UIFrame:Show()
        Loudmouth.UIFrame:Raise()
        return
    end

    local frame = CreateFrame("Frame", "LoudmouthConfigFrame", UIParent, "BackdropTemplate")
    Loudmouth.UIFrame = frame
    frame:SetSize(700, 520)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    SetSolidBackdrop(frame, 0.035, 0.04, 0.055, 0.98, 0.32, 0.27, 0.42)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    local closeButton = CreateFrame("Button", "$parentCloseButton", frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -7, -7)
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    CreateLabel(frame, "GameFontNormalLarge", "LOUDMOUTH", "TOPLEFT", nil, nil, 22, -17)
    local subtitle = CreateLabel(
        frame, "GameFontDisableSmall", "Personality-driven banter controls", "TOPLEFT", nil, nil, 22, -41)
    subtitle:SetTextColor(0.58, 0.60, 0.67)

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 12, -70)
    sidebar:SetPoint("BOTTOMLEFT", 12, 12)
    sidebar:SetWidth(145)
    SetSolidBackdrop(sidebar, 0.055, 0.06, 0.078, 1, 0.11, 0.12, 0.15)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 16, 0)
    content:SetPoint("BOTTOMRIGHT", -18, 18)

    local pages, navButtons = {}, {}
    local function ShowPage(pageName)
        for name, page in pairs(pages) do
            if name == pageName then page:Show() else page:Hide() end
        end
        for name, button in pairs(navButtons) do
            button:SetText((name == pageName and ">  " or "   ") .. name)
        end
    end

    local previousButton
    for _, pageName in ipairs({ "General", "Spell", "Zone", "Target" }) do
        local navName = pageName
        local navButton = MakeButton(
            sidebar, "Loudmouth" .. navName .. "NavButton", "   " .. navName, 125, 36,
            function() ShowPage(navName) end)
        if previousButton then
            navButton:SetPoint("TOP", previousButton, "BOTTOM", 0, -7)
        else
            navButton:SetPoint("TOP", 0, -12)
        end
        previousButton = navButton
        navButtons[navName] = navButton

        local page = CreateFrame("Frame", nil, content)
        page:SetAllPoints(content)
        pages[navName] = page
    end

    local editors = {}
    local refreshChancePages
    local generalPage = pages.General
    CreateLabel(generalPage, "GameFontNormalLarge", "General", "TOPLEFT", nil, nil, 0, -2)
    local playerRace, playerClass = Loudmouth.GetPlayerInfo()
    local playerInfo = CreateLabel(
        generalPage, "GameFontHighlightSmall", playerRace .. "  /  " .. playerClass, "TOPRIGHT", nil, nil, 0, -6)
    playerInfo:SetTextColor(0.65, 0.57, 0.78)

    CreateLabel(generalPage, "GameFontNormalSmall", "Personality", "TOPLEFT", nil, nil, 4, -51)
    local personalityDropdown = CreateFrame(
        "Frame", "LoudmouthPersonalityDropdown", generalPage, "UIDropDownMenuTemplate")
    personalityDropdown:SetPoint("TOPLEFT", -12, -65)
    UIDropDownMenu_SetWidth(personalityDropdown, 445)
    UIDropDownMenu_Initialize(personalityDropdown, function(_, level)
        for _, personalityId in ipairs(Loudmouth.AvailablePersonalities or {}) do
            local selectedId = personalityId
            local info = UIDropDownMenu_CreateInfo()
            info.text = selectedId
            info.value = selectedId
            info.notCheckable = true
            info.func = function()
                Loudmouth.CurrentPersonality = selectedId
                LoudmouthDB.currentPersonality = selectedId
                UIDropDownMenu_SetText(personalityDropdown, selectedId)
                if refreshChancePages then refreshChancePages() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(personalityDropdown, Loudmouth.CurrentPersonality or "No personality available")

    CreateLabel(generalPage, "GameFontNormalSmall", "Message cooldown", "TOPLEFT", nil, nil, 4, -122)
    local cooldownValue = CreateLabel(generalPage, "GameFontHighlightSmall", "", "TOPRIGHT", nil, nil, -4, -122)
    local cooldownSlider = CreateFrame("Slider", "LoudmouthCooldownSlider", generalPage, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", 4, -143)
    cooldownSlider:SetWidth(445)
    cooldownSlider:SetMinMaxValues(0, 30)
    cooldownSlider:SetValueStep(1)
    cooldownSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        Loudmouth.CooldownTime = value
        LoudmouthDB.cooldownTime = value
        cooldownValue:SetText(value .. " seconds")
    end)
    cooldownSlider:SetValue(Loudmouth.CooldownTime)
    if _G.LoudmouthCooldownSliderLow then _G.LoudmouthCooldownSliderLow:SetText("0") end
    if _G.LoudmouthCooldownSliderHigh then _G.LoudmouthCooldownSliderHigh:SetText("30") end
    if _G.LoudmouthCooldownSliderText then _G.LoudmouthCooldownSliderText:SetText("") end

    local debugButton = MakeButton(
        generalPage, "LoudmouthDebugButton", "Debug Mode: " .. (Loudmouth.DebugMode and "ON" or "OFF"), 216, 30, nil)
    debugButton:SetPoint("TOPLEFT", 4, -190)
    debugButton:SetScript("OnClick", function(self)
        Loudmouth.DebugMode = not Loudmouth.DebugMode
        LoudmouthDB.debugMode = Loudmouth.DebugMode
        self:SetText("Debug Mode: " .. (Loudmouth.DebugMode and "ON" or "OFF"))
    end)

    local zoneDebugButton = MakeButton(
        generalPage, "LoudmouthZoneDebugButton", "Zone Debug: " .. (Loudmouth.ShowZoneDebug and "ON" or "OFF"), 216, 30, nil)
    zoneDebugButton:SetPoint("LEFT", debugButton, "RIGHT", 12, 0)
    zoneDebugButton:SetScript("OnClick", function(self)
        Loudmouth.ShowZoneDebug = not Loudmouth.ShowZoneDebug
        LoudmouthDB.showZoneDebug = Loudmouth.ShowZoneDebug
        self:SetText("Zone Debug: " .. (Loudmouth.ShowZoneDebug and "ON" or "OFF"))
    end)

    local macroButton = MakeButton(
        generalPage, "LoudmouthGenerateMacrosButton", "Generate Macros: Spells + Responses", 444, 34,
        function() Loudmouth.GenerateMacros() end)
    macroButton:SetPoint("TOPLEFT", debugButton, "BOTTOMLEFT", 0, -15)

    local macroHelp = CreateLabel(
        generalPage, "GameFontHighlightSmall",
        "Creates LM_YES, LM_NO, LM_THANK, LM_RUN, and LM_RUDE. Each click advances to the next response.",
        "TOPLEFT", macroButton, "BOTTOMLEFT", 2, -10)
    macroHelp:SetWidth(440)
    macroHelp:SetJustifyH("LEFT")
    macroHelp:SetTextColor(0.62, 0.64, 0.70)

    local copyErrorsButton = MakeButton(
        generalPage, "LoudmouthCopyErrorsButton", "Copy Errors", 140, 28, function()
            if Loudmouth.CopyChat and Loudmouth.CopyChat.Show then
                Loudmouth.CopyChat.Show()
            else
                print("|cFFFF0000Loudmouth: CopyChat module not loaded.|r")
            end
        end)
    copyErrorsButton:SetPoint("BOTTOMLEFT", 4, 4)

    local descriptions = {
        spell = "Override how often a specific spell speaks. Target banter uses the Target setting.",
        zone = "Set the chance to comment after entering this zone or subzone.",
        target = "Set the chance to use special banter when this target type is selected.",
    }

    local function BuildChancePage(page, pageName, kind)
        CreateLabel(page, "GameFontNormalLarge", pageName, "TOPLEFT", nil, nil, 0, -2)
        local description = CreateLabel(
            page, "GameFontHighlightSmall", descriptions[kind], "TOPLEFT", nil, nil, 2, -37)
        description:SetWidth(452)
        description:SetJustifyH("LEFT")
        description:SetTextColor(0.62, 0.64, 0.70)

        CreateLabel(page, "GameFontNormalSmall", "Choose " .. string.lower(pageName), "TOPLEFT", nil, nil, 4, -88)
        local previous = MakeButton(page, "Loudmouth" .. pageName .. "PreviousButton", "<", 38, 30, nil)
        previous:SetPoint("TOPLEFT", 4, -108)
        local selectedLabel = CreateLabel(page, "GameFontNormal", "", "LEFT", previous, "RIGHT", 10, 0)
        selectedLabel:SetWidth(345)
        selectedLabel:SetJustifyH("CENTER")
        local nextButton = MakeButton(page, "Loudmouth" .. pageName .. "NextButton", ">", 38, 30, nil)
        nextButton:SetPoint("TOPRIGHT", -4, -108)

        local valueLabel = CreateLabel(page, "GameFontNormalLarge", "", "TOPRIGHT", nil, nil, -4, -177)
        valueLabel:SetTextColor(0.72, 0.56, 0.91)
        local sliderName = "Loudmouth" .. pageName .. "ChanceSlider"
        local slider = CreateFrame("Slider", sliderName, page, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 5, -210)
        slider:SetWidth(440)
        slider:SetMinMaxValues(0, 100)
        slider:SetValueStep(0.1)
        if _G[sliderName .. "Low"] then _G[sliderName .. "Low"]:SetText("0%") end
        if _G[sliderName .. "High"] then _G[sliderName .. "High"]:SetText("100%") end
        if _G[sliderName .. "Text"] then _G[sliderName .. "Text"]:SetText("") end

        local defaultLabel = CreateLabel(page, "GameFontHighlightSmall", "", "TOPLEFT", slider, "BOTTOMLEFT", 0, -17)
        defaultLabel:SetTextColor(0.58, 0.60, 0.67)
        local editor = { kind = kind, slider = slider, loading = false, index = 1 }

        local function SelectIndex(index)
            local itemCount = #editor.items
            if itemCount == 0 then
                editor.selected = nil
                selectedLabel:SetText("No options available")
                valueLabel:SetText("")
                defaultLabel:SetText("")
                slider:Disable()
                return
            end

            editor.index = ((index - 1) % itemCount) + 1
            local item = editor.items[editor.index]
            editor.selected = item
            slider:Enable()
            selectedLabel:SetText(string.format("%s  (%d/%d)", item.label, editor.index, itemCount))
            defaultLabel:SetText("Personality default: " .. FormatPercent(item.default * 100))
            local profile = Loudmouth.GetProfileSettings()
            local override = profile[kind] and profile[kind][item.key]
            editor.loading = true
            slider:SetValue((type(override) == "number" and override or item.default) * 100)
            editor.loading = false
            valueLabel:SetText(FormatPercent(slider:GetValue()))
        end

        previous:SetScript("OnClick", function() SelectIndex(editor.index - 1) end)
        nextButton:SetScript("OnClick", function() SelectIndex(editor.index + 1) end)
        slider:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value * 10 + 0.5) / 10
            valueLabel:SetText(FormatPercent(value))
            if editor.selected and not editor.loading then
                Loudmouth.SetConfiguredChance(kind, editor.selected.key, value / 100)
            end
        end)

        local resetButton = MakeButton(
            page, "Loudmouth" .. pageName .. "ResetButton", "Reset to Personality Default", 220, 30,
            function()
                if not editor.selected then return end
                Loudmouth.ClearConfiguredChance(kind, editor.selected.key)
                SelectIndex(editor.index)
            end)
        resetButton:SetPoint("TOPLEFT", 4, -305)

        function editor:Refresh()
            self.items = SortedChanceItems(Loudmouth.Personalities[Loudmouth.CurrentPersonality], kind)
            self.index = 1
            SelectIndex(1)
        end

        editors[#editors + 1] = editor
        editor:Refresh()
    end

    BuildChancePage(pages.Spell, "Spell", "spell")
    BuildChancePage(pages.Zone, "Zone", "zone")
    BuildChancePage(pages.Target, "Target", "target")
    refreshChancePages = function()
        Loudmouth.GetProfileSettings()
        for _, editor in ipairs(editors) do editor:Refresh() end
    end

    Loudmouth.ConfigPages = pages
    Loudmouth.ShowConfigPage = ShowPage
    Loudmouth.ChanceEditors = editors
    ShowPage("General")
    frame:Hide()
end

local status, err = pcall(InitUI)
if not status then print("|cFFFF0000Loudmouth UI Error:|r " .. err) end

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
