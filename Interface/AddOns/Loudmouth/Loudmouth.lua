-- Loudmouth Core Logic
Loudmouth = Loudmouth or {}
Loudmouth.CurrentPersonality = Loudmouth.CurrentPersonality or nil
Loudmouth.Cooldowns = Loudmouth.Cooldowns or {}
Loudmouth.CooldownTime = Loudmouth.CooldownTime or 5 -- seconds between messages
Loudmouth.DebugMode = Loudmouth.DebugMode or false

-- Personality Loading System
Loudmouth.Personalities = Loudmouth.Personalities or {}

function Loudmouth.LoadPersonalities()
    -- In a real WoW environment, we cannot scan folders at runtime.
    -- We must list the files in the TOC.
    -- However, for this modular system, we'll assume the files are loaded by the TOC.
    -- The personality files themselves populate Loudmouth.Personalities.
end

-- Initialize auto-detection on load
-- Trigger function called by macros
function Loudmouth.Trigger(action)
    local now = GetTime()
    if Loudmouth.Cooldowns[action] and (now - Loudmouth.Cooldowns[action] < Loudmouth.CooldownTime) then
        return
    end

    local personalityName = Loudmouth.CurrentPersonality
    local personality = Loudmouth.Personalities[personalityName]

    if not personality then
        print("|cFFFFFF00Loudmouth: Personality " .. tostring(personalityName) .. " not found!|r")
        return
    end

    local actionData = personality.actions[action]
    local phrases = actionData and actionData.lines

    if not phrases then
        local genericData = personality.actions["Generic"]
        phrases = genericData and genericData.lines
    end

    if phrases and #phrases > 0 then
        -- Probability check
        local chance = 1.0
        if not Loudmouth.DebugMode then
            local weight = actionData and actionData.weight
                or (personality.actions["Generic"] and personality.actions["Generic"].weight or 1.0)
            chance = weight
        end

        if math.random() <= chance then
            local phrase = phrases[math.random(#phrases)]
            SendChatMessage(phrase, "SAY")
            Loudmouth.Cooldowns[action] = now
        end
    end
end

-- Helper to get player info
function Loudmouth.GetPlayerInfo()
    local race, class, gender = Loudmouth.GetRace(), Loudmouth.GetClass(), Loudmouth.GetGender()
    return race or "Unknown Race", class or "Unknown Class", gender or "Unknown Gender"
end

-- Real WoW API calls for personality detection
Loudmouth.GetRace = function() return UnitRace("player") end
Loudmouth.GetClass = function() return UnitClass("player") end
Loudmouth.GetGender = function() return ({ [2]="Male", [3]="Female" })[UnitGender("player")] end

function Loudmouth.AutoDetectPersonality()
    local race = Loudmouth.GetRace()
    local class = Loudmouth.GetClass()
    local gender = Loudmouth.GetGender()

    -- Simple mapping logic
    if race == "Human" and class == "Warlock" and gender == "Female" then
        Loudmouth.CurrentPersonality = "HumanFemaleWarlockProfessional"
    elseif race == "Dwarf" and class == "Hunter" and gender == "Female" then
        Loudmouth.CurrentPersonality = "DwarfFemaleHunterQuirky"
    else
    -- Default to first available personality if no match
    local firstPersonality = next(Loudmouth.Personalities)
    Loudmouth.CurrentPersonality = firstPersonality
    end

    if Loudmouth.CurrentPersonality then
        print("|cFF00FF00Loudmouth: Auto-detected personality: " .. Loudmouth.CurrentPersonality .. "|r")
    else
        print("|cFFFF0000Loudmouth: No personality could be auto-detected!|r")
    end
end
Loudmouth.AutoDetectPersonality()


