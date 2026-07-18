-- Loudmouth Core Logic
Loudmouth = {}
Loudmouth.CurrentPersonality = "Quirky"
Loudmouth.Cooldowns = {}
Loudmouth.CooldownTime = 5 -- seconds between messages

-- Dialogue Library (Simplified for Pilot)
Loudmouth.Dialogues = {
    ["Quirky"] = {
        ["Aimed Shot"] = {
            "Hold still, you beauty!",
            "Right in the kisser!",
            "Don't blink, or you'll miss it!",
        },
        ["Auto Shot"] = {
            "Pew pew pew!",
            "Just keeping them honest.",
            "Ticking away like a clock!",
        },
        ["Hunters Mark"] = {
            "I've got my eye on you!",
            "Nowhere to hide!",
            "Marked for greatness (or death)!",
        },
        ["Health Potion"] = {
            "Tastes like cherries and magic!",
            "A quick sip for the road.",
            "Refreshing!",
        },
        ["Bandage"] = {
            "Hold still, I'm a professional!",
            "A bit of gauze and a lot of hope.",
            "Stop squirming!",
        },
        ["Generic"] = {
            "What was I saying?",
            "Is it lunchtime yet?",
            "I love the smell of gunpowder in the morning!",
        }
    }
}

-- Trigger function called by macros
function Loudmouth.Trigger(action)
    local now = GetTime()
    if Loudmouth.Cooldowns[action] and (now - Loudmouth.Cooldowns[action] < Loudmouth.CooldownTime) then
        return
    end

    local personality = Loudmouth.CurrentPersonality
    local phrases = Loudmouth.Dialogues[personality] and Loudmouth.Dialogues[personality][action]
    
    if not phrases then
        phrases = Loudmouth.Dialogues[personality] and Loudmouth.Dialogues[personality]["Generic"]
    end

    if phrases and #phrases > 0 then
        -- Probability check (e.g., 70% chance to trigger)
        if math.random() <= 0.7 then
            local phrase = phrases[math.random(#phrases)]
            -- Use /say for the effect
            SendChatMessage(phrase, "SAY")
            Loudmouth.Cooldowns[action] = now
        end
    end
end

-- Helper to get player info
function Loudmouth.GetPlayerInfo()
    local race, class, gender = GetRace(), GetClass(), GetGender() -- Note: These are placeholders for the actual WoW API calls
    -- In Classic Era, we might need to use UnitCharacteristics or similar
    -- For now, let's use a helper that attempts to find them
    
    -- Actual WoW API for race/class/gender is tricky in Classic. 
    -- Often requires looking up by English localization or using specific functions.
    -- For the sake of the UI, we'll provide a way to fetch them.
    
    -- Placeholder for real API implementation
    return race or "Unknown Race", class or "Unknown Class", gender or "Unknown Gender"
end

-- Mocking API calls that might not be directly available as simple functions in all versions
-- In a real environment, these would be the actual WoW API calls.
local function GetRace() return "Dwarf" end
local function GetClass() return "Hunter" end
local function GetGender() return "Male" end

-- Override the helpers with the mocks for the prototype
Loudmouth.GetRace = GetRace
Loudmouth.GetClass = GetClass
Loudmouth.GetGender = GetGender
