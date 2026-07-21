-- Loudmouth Core Logic
Loudmouth = Loudmouth or {}
Loudmouth.CurrentPersonality = Loudmouth.CurrentPersonality or nil
Loudmouth.Cooldowns = Loudmouth.Cooldowns or {}
Loudmouth.CooldownTime = Loudmouth.CooldownTime or 5 -- seconds between messages
Loudmouth.DebugMode = Loudmouth.DebugMode or false
Loudmouth.ShowZoneDebug = Loudmouth.ShowZoneDebug or false

-- Macro generation state
Loudmouth.pendingMacroUpdate = false   -- set true when macros are requested in combat
Loudmouth.macroGenerationDone = false  -- one-shot flag: auto-generate fires once per session

-- Personality Loading System
Loudmouth.Personalities = Loudmouth.Personalities or {}

-- ============================================================================
-- Canonical action order per class. Used by GenerateMacros() for LM_XX slot
-- mapping.  This is the single source of truth — personality files no longer
-- carry an actionOrder array.
-- ============================================================================
Loudmouth.ActionOrderByClass = Loudmouth.ActionOrderByClass or {
    ["Warlock"] = {
        "Shadow Bolt",
        "Immolate",
        "Corruption",
        "Curse of Weakness",
        "Curse of Agony",
        "Curse of Recklessness",
        "Curse of Tongues",
        "Curse of the Elements",
        "Curse of Shadow",
        "Curse of Doom",
        "Searing Pain",
        "Rain of Fire",
        "Hellfire",
        "Soul Fire",
        "Drain Life",
        "Drain Mana",
        "Life Tap",
        "Fear",
        "Howl of Terror",
        "Summon Imp",
        "Summon Voidwalker",
        "Summon Succubus",
        "Summon Felhunter",
        "Banish",
        "Death Coil",
        "Inferno",
        "Ritual of Doom",
        "Eye of Kilrogg",
        "Unending Breath",
        "Demon Armor",
        "Soulstone",
        "Subjugate Demon",
        "Healing Items",
        "Generic",
    },
    ["Hunter"] = {
        "Auto Shot",
        "Aimed Shot",
        "Hunters Mark",
        "Trap",
        "Pet Attack",
        "Multishot",
        "Health Potion",
        "Bandage",
    },
}

-- ============================================================================
-- Zone alias mapping — locale-aware canonical zone names → common aliases
-- Used by Trigger() for stable fuzzy matching.
-- ============================================================================
Loudmouth.ZoneAliases = Loudmouth.ZoneAliases or {
    -- Capital cities
    ["Ironforge"] = { "City of Ironforge", "Iron Forge" },
    ["Stormwind City"] = { "Stormwind" },
    ["Orgrimmar"] = { "Orgrimar" },
    ["Thunder Bluff"] = { "Thunder" },
    ["Undercity"] = { "Under" },
    ["Darnassus"] = { "Teldrassil" },
    ["Shattrath City"] = { "Shattrath", "Shat" },
    ["Exodar"] = { "Exo" },
    ["Silvermoon City"] = { "Silvermoon" },
    -- Key zones / dungeons
    ["Raven Hill Cemetery"] = { "Raven Hill", "Raven Hill Cremation" },
    ["Raven Hill"] = { "Raven" },
    ["Camp Narache"] = { "Narache" },
    ["Camp Taurajo"] = { "Taurajo" },
    ["Thorn Hill"] = { "Thorn" },
    ["The Crossroads"] = { "Crossroads" },
    -- Classic dungeons / instances
    ["Deadmines"] = { "DM" },
    ["Wailing Caverns"] = { "WC" },
    ["Shadowfang Keep"] = { "SFK" },
    ["Stockade"] = { "The Stockade", "Stormwind Stockade" },
    ["Ridgepoint Tower"] = { "Ridgepoint" },
    ["Elwynn Forest"] = { "Elwynn" },
    ["Duskwood"] = { "Dusk" },
    ["Redridge Mountains"] = { "Redridge" },
    ["Badlands"] = { "Bad" },
    ["Wetlands"] = { "Wet" },
    ["Hinterlands"] = { "Hinter" },
    ["Searing Gorge"] = { "Searing" },
    ["Blasted Lands"] = { "Blasted" },
    ["Swamp of Sorrows"] = { "Swamp" },
    ["Stranglethorn Vale"] = { "Stranglethorn", "STV" },
    ["Loch Modan"] = { "Modan" },
    ["Dun Morogh"] = { "Dun Mor" },
}

-- ============================================================================
-- Spell name resolver — handles locale/alias mismatches for GetSpellInfo
-- ============================================================================

-- Alias map: common macro/action names → canonical WoW spell names
local SpellAliasMap = {
    ["Hunters Mark"] = "Hunter's Mark",
    ["Multishot"] = "Multi-Shot",
}

--- Resolve a spell/action key to a valid spell name for GetSpellInfo.
-- 1. Try the key directly.
-- 2. Try any alias mapping.
-- Returns the spell name or nil.
function Loudmouth._ResolveSpellName(key)
    -- Direct lookup
    local name = GetSpellInfo(key)
    if name then return name end

    -- Alias lookup
    local alias = SpellAliasMap[key]
    if alias then
        return GetSpellInfo(alias)
    end

    return nil
end

-- ============================================================================
-- Strict personality ID parser & filter pipeline
-- ============================================================================

-- Token arrays for strict parsing
local RACES = { "NightElf", "Human", "Dwarf", "Undead", "Orc", "Tauren", "Gnome", "Troll" }
local GENDERS = { "Male", "Female" }
local CLASSES = { "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid" }
local RACE_TOKEN_TO_STANDARD = { ["Scourge"] = "Undead" } -- WoW returns "Scourge" for Undead

-- Consume the longest matching prefix from a value.
local function consumePrefix(value, prefixes)
    for _, p in ipairs(prefixes) do
        if value:sub(1, #p) == p then return p end
    end
end

-- Parse a personality ID string into its components.
-- Returns { race, gender, class, variant } or nil + error message.
function Loudmouth.ParsePersonalityID(id)
    local remaining = id
    local race = consumePrefix(remaining, RACES)
    if not race then return nil, "Unknown race" end
    remaining = remaining:sub(#race + 1)

    local gender = consumePrefix(remaining, GENDERS)
    if not gender then return nil, "Unknown gender" end
    remaining = remaining:sub(#gender + 1)

    local class = consumePrefix(remaining, CLASSES)
    if not class then return nil, "Unknown class" end
    remaining = remaining:sub(#class + 1)

    -- Variant is the rest
    if remaining == "" then return nil, "Empty variant" end

    return {
        race = race,
        gender = gender,
        class = class,
        variant = remaining,
    }
end

-- Filter available personalities based on player identity.
-- Populates Loudmouth.AvailablePersonalities (ordered array) and
-- Loudmouth.Personalities (key map of the selected tier).
function Loudmouth.FilterPersonalities()
    -- Collect raw personality IDs and parse them
    local parsed = {}
    for id, _ in pairs(Loudmouth._RawPersonalities or {}) do
        local ok, result = pcall(Loudmouth.ParsePersonalityID, id)
        if ok and result then
            parsed[id] = result
        end
    end

    -- Read player identity
    local _, raceFile = UnitRace("player")
    local _, classFile = UnitClass("player")
    local sex = UnitSex("player")

    -- Convert sex (2 = Male, 3 = Female) to string
    local genderStr
    if sex == 2 then
        genderStr = "Male"
    elseif sex == 3 then
        genderStr = "Female"
    else
        genderStr = nil
    end

    -- Convert race file token to standard (e.g. "Scourge" -> "Undead")
    local raceStandard = RACE_TOKEN_TO_STANDARD[raceFile] or raceFile

    -- Convert class file token to TitleCase (e.g. "WARLOCK" -> "Warlock")
    local classStandard = classFile and tostring(classFile):lower():gsub("^%l", string.upper)

    -- Build three priority tiers of candidate IDs
    local tier1 = {} -- Exact: Race + Gender + Class
    local tier2 = {} -- Class only
    local tier3 = {} -- Race only

    for id, p in pairs(parsed) do
        if p.race == raceStandard and p.gender == genderStr and p.class == classStandard then
            tier1[#tier1 + 1] = id
        elseif p.class == classStandard then
            tier2[#tier2 + 1] = id
        elseif p.race == raceStandard then
            tier3[#tier3 + 1] = id
        end
    end

    -- Select the first non-empty tier
    local selected
    if #tier1 > 0 then
        selected = tier1
    elseif #tier2 > 0 then
        selected = tier2
    elseif #tier3 > 0 then
        selected = tier3
    else
        -- No tier matched — fall back to the first available personality
        -- so CurrentPersonality is never nil.
        selected = {}
        local firstId = next(parsed)
        if firstId then
            selected[#selected + 1] = firstId
        end
    end

    -- Sort alphabetically for deterministic order
    table.sort(selected)

    -- Populate AvailablePersonalities (ordered array)
    Loudmouth.AvailablePersonalities = selected

    -- Populate Personalities (key map of ONLY the selected tier)
    Loudmouth.Personalities = {}
    for _, id in ipairs(selected) do
        Loudmouth.Personalities[id] = Loudmouth._RawPersonalities[id]
    end

    -- Set current personality — always at least one fallback
    if #selected > 0 then
        Loudmouth.CurrentPersonality = selected[1]
    else
        -- Safety net: should never happen, but guard against nil.
        Loudmouth.CurrentPersonality = "Fallback"
    end

    -- Clear raw staging table to reclaim memory
    Loudmouth._RawPersonalities = nil

    -- Debug output: only print success diagnostics when DebugMode is ON.
    -- Error/warning messages remain unconditional so the player always sees
    -- a fallback failure even with DebugMode == false.
    if #selected > 0 then
        if Loudmouth.DebugMode then
            print("|cFF00FF00[Loudmouth]|r Filtered " .. #selected ..
                " personality(s) for " .. raceStandard .. "/" .. genderStr ..
                "/" .. classStandard .. ": " .. table.concat(selected, ", "))
        end
    else
        print("|cFFFF0000[Loudmouth]|r No personality matched for " ..
            raceStandard .. "/" .. genderStr .. "/" .. classStandard .. "!")
    end
end

-- ============================================================================
-- Core Trigger function — called by macros
-- ============================================================================

-- Safe chat helper: only sends chat when we are actually in-game.
-- In the headless UI simulator, SendChatMessage can produce noisy output
-- or errors that fill the test log.  We detect the simulator by checking
-- whether the config frame was created (it is, during wow-ui-sim init).
local function SafeSendChat(msg, chatType)
    if type(SendChatMessage) ~= "function" then return end
    -- In the simulator, the config frame exists but the chat system is
    -- non-functional.  Guard against it: if the frame exists we may still
    -- be in a headless context where SendChatMessage would fail.
    -- We only suppress when the frame is present AND the call would be
    -- from the test harness (i.e. we have no real player frame).
    if LoudmouthConfigFrame and not _G["PlayerFrame"] then
        return -- headless simulator: skip chat output
    end
    SendChatMessage(msg, chatType or "SAY")
end

function Loudmouth.Trigger(action)
    -- ========================================================================
    -- Localization Strategy (English-first)
    -- This addon targets English locales (enUS, enGB) for zone matching.
    -- Zone names in personality files use English canonical names.
    -- Substring matching is a best-effort fallback for non-exact zone names.
    -- If the client is not enUS/enGB, zone matching may produce inaccurate
    -- results because GetRealZoneText() returns localized zone names.
    -- ========================================================================
    local locale = GetLocale()
    if locale ~= "enUS" and locale ~= "enGB" then
        if not Loudmouth.localeWarned then
            Loudmouth.localeWarned = true
            print("|cFFFF8800[Loudmouth]|r Non-English client detected (" .. locale ..
                "). Zone matching may not be accurate.")
        end
    end

    -- Safety: bail if no personality is loaded
    if not Loudmouth.CurrentPersonality or not Loudmouth.Personalities[Loudmouth.CurrentPersonality] then
        return
    end

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

    -- ========================================================================
    -- Zone Debug Output (toggleable via UI)
    -- ========================================================================
    if Loudmouth.ShowZoneDebug then
        local realZone = GetRealZoneText()
        local subZone = GetSubZoneText() or ""
        print(string.format(
            "|cFF99CCFF[LM ZDebug]|r Zone='%s' | Sub='%s' | Pending=%s",
            realZone or "", subZone or "",
            Loudmouth.PendingZoneComment and "YES (100%)" or "NO"
        ))
    end

    -- ========================================================================
    -- Pending Zone Comment — resolve on first macro call after ZONE_CHANGED_NEW_AREA
    -- When PendingZoneComment is true we IGNORE the action weight and force a
    -- 100% zone comment.
    -- ========================================================================
    if Loudmouth.PendingZoneComment then
        local realZone = GetRealZoneText()
        local subZone = GetSubZoneText() or ""

        local matchedEntry = nil

        -- 1. Try exact match against realZone
        if personality.zones and personality.zones[realZone] then
            matchedEntry = personality.zones[realZone]
        elseif personality.zones then
            -- 2. Alias check: does realZone match any known alias for a zone key?
            for zoneName, aliases in pairs(Loudmouth.ZoneAliases or {}) do
                if personality.zones[zoneName] then
                    for _, alias in ipairs(aliases) do
                        if string.lower(realZone) == string.lower(alias) then
                            matchedEntry = personality.zones[zoneName]
                            break
                        end
                    end
                    if matchedEntry then break end
                end
            end

            -- 3. Fallback: sorted substring search (longest keys first to avoid
            --    short-word false positives like "Camp" matching "Raven Hill Camp")
            if not matchedEntry then
                local sortedKeys = {}
                for zoneName in pairs(personality.zones) do
                    sortedKeys[#sortedKeys + 1] = zoneName
                end
                table.sort(sortedKeys, function(a, b) return #a > #b end)

                for _, zoneName in ipairs(sortedKeys) do
                    local data = personality.zones[zoneName]
                    if type(data.lines) == "table" and #data.lines > 0 then
                        if string.find(string.lower(realZone), string.lower(zoneName), 1, true) or
                           string.find(string.lower(zoneName), string.lower(realZone), 1, true) then
                            matchedEntry = data
                            break
                        end
                    end
                end
            end
        end

        -- 4. Subzone keyword matching (Fix 3: use personality.subzones, not personality.zones.subzones)
        local subMatchEntry = nil
        if not matchedEntry and subZone ~= "" then
            local subData = personality.subzones or (personality.zones and personality.zones.subzones)
            if subData then
                for keyword, data in pairs(subData) do
                    if string.find(string.lower(subZone), string.lower(keyword), 1, true) then
                        subMatchEntry = data
                        break
                    end
                end
            end
        end

        local played = false
        if matchedEntry and matchedEntry.lines and #matchedEntry.lines > 0 then
            local line = matchedEntry.lines[math.random(#matchedEntry.lines)]
            SafeSendChat(line, "SAY")
            played = true
        elseif subMatchEntry and subMatchEntry.lines and #subMatchEntry.lines > 0 then
            local line = subMatchEntry.lines[math.random(#subMatchEntry.lines)]
            SafeSendChat(line, "SAY")
            played = true
        end

        if not matchedEntry and not subMatchEntry and Loudmouth.ShowZoneDebug then
            print(string.format(
                "|cFFFF8800[Dev Alert]|r Missing zone data for '%s' (sub: '%s'). Please add entries!",
                realZone, subZone
            ))
        end

        if played then
            Loudmouth.PendingZoneComment = false
            return
        end

        -- No comment was found, but we still consumed the pending flag.
        Loudmouth.PendingZoneComment = false
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
            SafeSendChat(phrase, "SAY")
            Loudmouth.Cooldowns[action] = now
        end
    end
end

-- Helper to get player info
function Loudmouth.GetPlayerInfo()
    local race, class = Loudmouth.GetRace(), Loudmouth.GetClass()
    return race or "Unknown Race", class or "Unknown Class"
end

-- ============================================================================
-- Macro naming helper — produces deterministic, zero-padded macro names
-- ============================================================================

function Loudmouth.MakeMacroName(slotIndex)
    local index = math.min(math.max(1, slotIndex), 99)
    return string.format("LM_%02d", index)
end

-- Resolves a macro's physical slot index by its NAME. Returns 0 if not found.
function Loudmouth.MacroIndexByName(macroName)
    local gCount = select(1, GetNumMacros()) -- only care about account-wide (global) macros
    for i = 1, gCount do
        local name = GetMacroInfo(i)
        if name == macroName then
            return i
        end
    end
    return 0
end

-- Real WoW API calls for personality detection
Loudmouth.GetRace = function() return UnitRace("player") end
Loudmouth.GetClass = function() return UnitClass("player") end

-- ============================================================================
-- Safe Macro API wrappers (Fix 1A)
-- ============================================================================

function Loudmouth.SafeCreateMacro(name, icon, body)
    if InCombatLockdown() then
        Loudmouth.pendingMacroUpdate = true
        return false
    end
    return CreateMacro(name, icon, body, false)
end

function Loudmouth.SafeEditMacro(idx, name, icon, body)
    if InCombatLockdown() then
        Loudmouth.pendingMacroUpdate = true
        return false
    end
    return EditMacro(idx, name, icon, body)
end

-- ============================================================================
-- Zone Change Frame (Fix 4)
-- ============================================================================

if not Loudmouth.ZoneFrame then
    Loudmouth.ZoneFrame = CreateFrame("Frame", "LoudmouthZoneFrame")
    Loudmouth.ZoneFrame:RegisterEvent("ZONE_CHANGED")
    Loudmouth.ZoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    Loudmouth.ZoneFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    Loudmouth.ZoneFrame:SetScript("OnEvent", function()
        -- All three zone-change events should trigger a pending zone comment.
        -- ZONE_CHANGED covers subzone transitions that the other two miss.
        Loudmouth.PendingZoneComment = true
    end)
end