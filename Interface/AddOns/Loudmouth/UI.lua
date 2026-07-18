-- Loudmouth UI Implementation

local frame = CreateFrame("Frame", "LoudmouthConfigFrame", UIParent, "UIPanelFrameTemplate")
frame:SetSize(300, 250)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Title
local title = frame:CreateFontString(nil, "FONT")
title:SetFontObject("GameFontNormal")
title:SetPoint("TOP", 0, -10)
title:SetText("Loudmouth Configuration")

-- Player Info Display
local infoText = frame:CreateFontString(nil, "FONT")
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
local dropdown = CreateDropdownMenu() -- This is a simplified representation of WoW's dropdown system
-- In real WoW, dropdowns are more complex (UIDropDownMenu_Create). 
-- For a "classic" feel and simplicity in this prototype, I will use a simple button that toggles or a basic list.
-- However, I'll implement a mock-up of the dropdown logic.

local personalityButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
personalityButton:SetSize(120, 20)
personalityButton:SetPoint("CENTER", 0, 10)
personalityButton:SetText("Personality: Quirky")

personalityButton:SetScript("OnClick", function()
    -- For the pilot, we only have 'Quirky'. 
    -- In a full version, this would open a menu.
    Loudmouth.CurrentPersonality = "Quirky"
    personalityButton:SetText("Personality: " .. Loudmouth.CurrentPersonality)
end)

-- Macro Generator Button
local macroButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
macroButton:SetSize(150, 30)
macroButton:SetPoint("CENTER", 0, -40)
macroButton:SetText("Generate Macros")

local function GenerateMacros()
    local personality = Loudmouth.CurrentPersonality
    local dialogues = Loudmouth.Dialogues[personality]
    
    if not dialogues then
        print("|cFFFF00Loudmouth: No dialogues found for this personality!|r")
        return
    end

    print("|cFF00FF00Loudmouth: Copy the following macros into your macro menu:|r")
    
    -- List of actions to generate macros for
    local actions = {
        "Aimed Shot",
        "Auto Shot",
        "Hunters Mark",
        "Health Potion",
        "Bandage"
    }

    for _, action in ipairs(actions) do
        -- Format: /run Loudmouth.Trigger("ActionName") \n /cast ActionName
        -- We use \n for the visual representation, but in a real macro, it's a new line.
        local macroText = string.format("/run Loudmouth.Trigger(\"%s\")\n/cast %s", action, action)
        
        -- Print to chat for the user to copy
        print(string.format("|cFFFFFF00[%s]:|r %s", action, macroText))
    end
    
    print("|cFF00FF00Loudmouth: Macro generation complete!|r")
end

macroButton:SetScript("OnClick", GenerateMacros)

-- Initialize
UpdatePlayerInfo()
frame:Show()
