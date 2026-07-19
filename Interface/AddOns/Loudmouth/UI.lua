-- Loudmouth UI Implementation

local function InitUI()
    -- Main Frame
    -- Using BackdropTemplate for Classic Era compatibility
    Loudmouth.UIFrame = CreateFrame("Frame", "LoudmouthConfigFrame", UIParent, "BackdropTemplate")
    Loudmouth.UIFrame:SetSize(300, 300)
    Loudmouth.UIFrame:SetPoint("CENTER")
    Loudmouth.UIFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        centerSized = true,
    })
    Loudmouth.UIFrame:SetMovable(true)
    Loudmouth.UIFrame:EnableMouse(true)
    Loudmouth.UIFrame:RegisterForDrag("LeftButton")
    Loudmouth.UIFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    Loudmouth.UIFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Title
    local title = Loudmouth.UIFrame:CreateFontString()
    title:SetFontObject("GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Loudmouth Configuration")

    -- Player Info Display
    local infoText = Loudmouth.UIFrame:CreateFontString()
    infoText:SetFontObject("GameFontHighlight")
    infoText:SetPoint("TOP", 0, -40)
    infoText:SetJustifyH("CENTER")

    local function UpdatePlayerInfo()
        local race = Loudmouth.GetRace()
        local class = Loudmouth.GetClass()
        local gender = Loudmouth.GetGender()
        infoText:SetText(string.format("Race: %s | Class: %s | Gender: %s", race, class, gender))
    end

    -- Personality Dropdown
    local personalityButton = CreateFrame("Button", nil, Loudmouth.UIFrame, "UIPanelButtonTemplate")
    personalityButton:SetSize(150, 20)
    personalityButton:SetPoint("CENTER", 0, 10)
    
    local function UpdatePersonalityButtonText()
        local text = "Personality: " .. (Loudmouth.CurrentPersonality or "None")
        personalityButton:SetText(text)
    end
    
    UpdatePersonalityButtonText()

    personalityButton:SetScript("OnClick", function()
        local keys = {}
        for k, _ in pairs(Loudmouth.Personalities) do keys[#keys+1] = k end
        
        if #keys == 0 then
            print("|cFFFF00Loudmouth: No personalities loaded!|r")
            return
        end

        if not personalityButton.currentPos then personalityButton.currentPos = 0 end
        personalityButton.currentPos = personalityButton.currentPos + 1
        if personalityButton.currentPos > #keys then personalityButton.currentPos = 1 end
        
        Loudmouth.CurrentPersonality = keys[personalityButton.currentPos]
        UpdatePersonalityButtonText()
    end)

    -- Debug Mode Toggle (Replaced CheckButton with Button for compatibility)
    local debugButton = CreateFrame("Button", nil, Loudmouth.UIFrame, "UIPanelButtonTemplate")
    debugButton:SetSize(150, 20)
    debugButton:SetPoint("CENTER", 0, -30)
    debugButton:SetText("Debug Mode: " .. (Loudmouth.DebugMode and "ON" or "OFF"))

    debugButton:SetScript("OnClick", function(self)
        Loudmouth.DebugMode = not Loudmouth.DebugMode
        self:SetText("Debug Mode: " .. (Loudmouth.DebugMode and "ON" or "OFF"))
    end)

    -- Macro Generator Button
    local macroButton = CreateFrame("Button", nil, Loudmouth.UIFrame, "UIPanelButtonTemplate")
    macroButton:SetSize(150, 30)
    macroButton:SetPoint("CENTER", 0, -70)
    macroButton:SetText("Generate Macros")

    local function GenerateMacros()
        if not Loudmouth.CurrentPersonality then
            -- Try to auto-detect or fallback to first available
            Loudmouth.AutoDetectPersonality()
        end

        local personality = Loudmouth.Personalities[Loudmouth.CurrentPersonality]
        
        if not personality then
            print("|cFFFF00Loudmouth: No personality found for " .. tostring(Loudmouth.CurrentPersonality) .. "!|r")
            return
        end
        
        print("|cFF00FF00Loudmouth: Copy the following macros into your macro menu:|r")
        
        local actions = {}
        for action, _ in pairs(personality.actions) do
            table.insert(actions, action)
        end
        
        for _, action in ipairs(actions) do
            local macroText = string.format("/run Loudmouth.Trigger(\"%s\")\n/cast %s", action, action)
            print(string.format("|cFFFFFF00[%s]:|r %s", action, macroText))
        end
        
        print("|cFF00FF00Loudmouth: Macro generation complete!|r")
    end


    macroButton:SetScript("OnClick", GenerateMacros)

    -- Copy Errors Button (opens the CopyChat window: errors then chat)
    local copyErrorsButton = CreateFrame("Button", nil, Loudmouth.UIFrame, "UIPanelButtonTemplate")
    copyErrorsButton:SetSize(150, 30)
    copyErrorsButton:SetPoint("CENTER", 0, -110)
    copyErrorsButton:SetText("Copy Errors")
    copyErrorsButton:SetScript("OnClick", function()
        if Loudmouth.CopyChat and Loudmouth.CopyChat.Show then
            Loudmouth.CopyChat.Show()
        else
            print("|cFFFF0000Loudmouth: CopyChat module not loaded.|r")
        end
    end)

    UpdatePlayerInfo()
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
        print("|cFFFF00Loudmouth: UI failed to initialize. Please reload.|r")
    end
end
