-- Loudmouth Core Logic
Loudmouth = Loudmouth or {}
Loudmouth.CurrentPersonality = Loudmouth.CurrentPersonality or nil
Loudmouth.Cooldowns = Loudmouth.Cooldowns or {}
Loudmouth.CooldownTime = Loudmouth.CooldownTime or 5 -- seconds between messages
Loudmouth.DebugMode = Loudmouth.DebugMode or false
Loudmouth.ShowZoneDebug = Loudmouth.ShowZoneDebug or false
Loudmouth.DefaultZoneChance = Loudmouth.DefaultZoneChance or 0.15
Loudmouth.DefaultTargetChance = Loudmouth.DefaultTargetChance or 0.15
Loudmouth.ResponseSequence = Loudmouth.ResponseSequence or {}

local function ClampChance(value)
    value = tonumber(value) or 0
    return math.min(math.max(value, 0), 1)
end

local function RollChance(chance)
    chance = ClampChance(chance)
    return chance >= 1 or (chance > 0 and math.random() < chance)
end

function Loudmouth.GetProfileSettings(personalityName)
    LoudmouthDB = LoudmouthDB or {}
    LoudmouthDB.profiles = LoudmouthDB.profiles or {}

    local profileName = personalityName or Loudmouth.CurrentPersonality or "Default"
    local profile = LoudmouthDB.profiles[profileName]
    if type(profile) ~= "table" then
        profile = {}
        LoudmouthDB.profiles[profileName] = profile
    end

    profile.spell = type(profile.spell) == "table" and profile.spell or {}
    profile.zone = type(profile.zone) == "table" and profile.zone or {}
    profile.target = type(profile.target) == "table" and profile.target or {}
    return profile
end

function Loudmouth.GetConfiguredChance(kind, key, defaultChance)
    if Loudmouth.DebugMode then return 1 end
    local profile = Loudmouth.GetProfileSettings()
    local bucket = profile[kind]
    local override = type(bucket) == "table" and bucket[key]
    if type(override) == "number" then return ClampChance(override) end
    return ClampChance(defaultChance == nil and 1 or defaultChance)
end

function Loudmouth.SetConfiguredChance(kind, key, chance)
    local profile = Loudmouth.GetProfileSettings()
    if type(profile[kind]) ~= "table" or type(key) ~= "string" then return end
    profile[kind][key] = ClampChance(chance)
end

function Loudmouth.ClearConfiguredChance(kind, key)
    local profile = Loudmouth.GetProfileSettings()
    if type(profile[kind]) == "table" then profile[kind][key] = nil end
end

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
        -- Keep new actions appended so existing LM_01..LM_33 action-bar slots
        -- retain their meaning across addon upgrades.
        "Drain Soul",
        "Demon Skin",
        "Create Healthstone",
        "Health Funnel",
        "Ritual of Summoning",
        "Shadow Ward",
        "Create Firestone",
        "Create Spellstone",
        "Sense Demons",
        "Detect Invisibility",
        "Summon Incubus",
        "Warlock Mount",
        -- Talent-granted castable abilities are skipped unless learned.
        "Amplify Curse",
        "Curse of Exhaustion",
        "Siphon Life",
        "Dark Pact",
        "Fel Domination",
        "Demonic Sacrifice",
        "Soul Link",
        "Shadowburn",
        "Conflagrate",
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

-- ClassicMetadata.lua normally initializes this before the core loads.
Loudmouth.ZoneAliases = Loudmouth.ZoneAliases or {}

-- ============================================================================
-- Context matching helpers -- shared by location and target banter
-- ============================================================================

local function NormalizeContextText(value)
    if type(value) ~= "string" then return "" end
    return string.lower(value)
end

local function HasEntryLines(entry)
    local lines = type(entry) == "table" and entry.lines
    return type(lines) == "table" and #lines > 0
end

local function PickEntryLine(entry)
    if not HasEntryLines(entry) then return nil end
    local lines = entry.lines
    return lines[math.random(#lines)]
end

local function CollectSortedKeys(bucket)
    local keys = {}
    if type(bucket) ~= "table" then return keys end

    for key, entry in pairs(bucket) do
        if type(key) == "string" and key ~= "" and HasEntryLines(entry) then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(a, b)
        if #a == #b then return a < b end
        return #a > #b
    end)
    return keys
end

local function FindKeywordMatch(bucket, texts)
    for _, key in ipairs(CollectSortedKeys(bucket)) do
        local needle = NormalizeContextText(key)
        for _, text in ipairs(texts or {}) do
            local haystack = NormalizeContextText(text)
            if haystack ~= "" and string.find(haystack, needle, 1, true) then
                return PickEntryLine(bucket[key]), key, bucket[key]
            end
        end
    end
end

local ZoneNameIndex

local function BuildZoneNameIndex()
    local index = {}
    for _, data in pairs(Loudmouth.ClassicZones or {}) do
        if type(data) == "table" and type(data.name) == "string" then
            index[NormalizeContextText(data.name)] = data.name
        end
    end
    for _, name in pairs(Loudmouth.ClassicInstances or {}) do
        if type(name) == "string" then
            index[NormalizeContextText(name)] = name
        end
    end
    for canonical, aliases in pairs(Loudmouth.ZoneAliases or {}) do
        index[NormalizeContextText(canonical)] = canonical
        for _, alias in ipairs(aliases) do
            index[NormalizeContextText(alias)] = canonical
        end
    end
    return index
end

function Loudmouth.GetCanonicalZoneName(zoneName)
    if not ZoneNameIndex then ZoneNameIndex = BuildZoneNameIndex() end
    return ZoneNameIndex[NormalizeContextText(zoneName)]
end

local function AddContextTerm(terms, seen, value)
    local normalized = NormalizeContextText(value)
    if normalized ~= "" and not seen[normalized] then
        terms[#terms + 1] = value
        seen[normalized] = true
    end
end

local function AddTagList(terms, seen, tags, minimumStrength)
    if type(tags) ~= "table" then return end
    for key, value in pairs(tags) do
        if type(key) == "number" then
            AddContextTerm(terms, seen, value)
        elseif value and (type(value) ~= "number" or not minimumStrength or value >= minimumStrength) then
            AddContextTerm(terms, seen, key)
        end
    end
end

local function FindSubzoneTags(metadata, canonicalZone, subZone)
    local zoneData = type(metadata) == "table" and metadata[canonicalZone]
    if type(zoneData) ~= "table" then return nil end

    local normalizedSubzone = NormalizeContextText(subZone)
    for name, tags in pairs(zoneData) do
        if NormalizeContextText(name) == normalizedSubzone then return tags end
    end
end

function Loudmouth.GetLocationContextTerms(realZone, subZone)
    local terms, seen = {}, {}
    local canonicalZone = Loudmouth.GetCanonicalZoneName(realZone) or realZone

    AddContextTerm(terms, seen, realZone)
    AddContextTerm(terms, seen, subZone)
    AddContextTerm(terms, seen, canonicalZone)
    -- Strength-1 race tags describe a local camp or ruin, not the whole zone.
    AddTagList(terms, seen, (Loudmouth.ZoneRaceMetadata or {})[canonicalZone], 2)
    AddTagList(terms, seen, (Loudmouth.ZoneVibeMetadata or {})[canonicalZone])
    AddTagList(terms, seen, FindSubzoneTags(Loudmouth.SubzoneRaceMetadata, canonicalZone, subZone))
    AddTagList(terms, seen, FindSubzoneTags(Loudmouth.SubzoneVibeMetadata, canonicalZone, subZone))

    return terms, canonicalZone
end

local function CollectPreferenceTraits(bucket)
    local traits = {}
    if type(bucket) ~= "table" then return traits end

    for key, value in pairs(bucket) do
        local trait
        if type(key) == "number" and type(value) == "string" then
            trait = value
        elseif type(key) == "string" and value == true then
            trait = key
        end
        if trait and trait ~= "" then traits[#traits + 1] = trait end
    end
    table.sort(traits, function(a, b)
        if #a == #b then return a < b end
        return #a > #b
    end)
    return traits
end

local function FindPreferenceTraits(bucket, contextTerms)
    local matches = {}
    for _, trait in ipairs(CollectPreferenceTraits(bucket)) do
        local needle = NormalizeContextText(trait)
        for _, term in ipairs(contextTerms) do
            if string.find(NormalizeContextText(term), needle, 1, true) then
                matches[#matches + 1] = trait
                break
            end
        end
    end
    return matches
end

function Loudmouth.GetLocationPreferences(personality, realZone, subZone)
    if type(personality) ~= "table" then return {}, {} end
    local contextTerms = Loudmouth.GetLocationContextTerms(realZone, subZone)
    local likes = personality.likes and personality.likes.zones
    local hates = personality.hates and personality.hates.zones
    return FindPreferenceTraits(likes, contextTerms), FindPreferenceTraits(hates, contextTerms)
end

local function FindAuthoredZoneLine(personality, realZone)
    if type(personality.zones) ~= "table" then return nil end

    local realCanonical = Loudmouth.GetCanonicalZoneName(realZone)
    local exactEntry = personality.zones[realZone]
    if HasEntryLines(exactEntry) then
        return PickEntryLine(exactEntry), "zone", realZone, exactEntry.weight
    end

    for _, zoneName in ipairs(CollectSortedKeys(personality.zones)) do
        if NormalizeContextText(zoneName) == NormalizeContextText(realZone) then
            local entry = personality.zones[zoneName]
            return PickEntryLine(entry), "zone", zoneName, entry.weight
        end
    end

    for _, zoneName in ipairs(CollectSortedKeys(personality.zones)) do
        local zoneCanonical = Loudmouth.GetCanonicalZoneName(zoneName)
        if realCanonical and zoneCanonical == realCanonical then
            local entry = personality.zones[zoneName]
            return PickEntryLine(entry), "zone", zoneName, entry.weight
        end
    end

    if realZone ~= "" then
        for _, zoneName in ipairs(CollectSortedKeys(personality.zones)) do
            local zoneNeedle = NormalizeContextText(zoneName)
            local haystack = NormalizeContextText(realZone)
            if string.find(haystack, zoneNeedle, 1, true) or string.find(zoneNeedle, haystack, 1, true) then
                local entry = personality.zones[zoneName]
                return PickEntryLine(entry), "zone", zoneName, entry.weight
            end
        end
    end
end

local function FindAuthoredSubzoneLine(personality, realZone, subZone)
    if type(personality.subzones) ~= "table" or subZone == "" then return nil end

    local canonicalZone = Loudmouth.GetCanonicalZoneName(realZone) or realZone
    local scoped = personality.subzones[canonicalZone]
    local line, key, entry = FindKeywordMatch(scoped, { subZone })
    if line then return line, "subzone", canonicalZone .. " / " .. key, entry.weight end

    -- Flat keys remain available for broad features such as inns.
    line, key, entry = FindKeywordMatch(personality.subzones, { subZone })
    if line then return line, "subzone", key, entry.weight end
end


function Loudmouth.GetZoneBanterFromTexts(personality, realZone, subZone, locationKind)
    if type(personality) ~= "table" then return nil end

    realZone = type(realZone) == "string" and realZone or ""
    subZone = type(subZone) == "string" and subZone or ""

    if locationKind == "subzone" then
        return FindAuthoredSubzoneLine(personality, realZone, subZone)
    end
    if locationKind == "zone" then
        return FindAuthoredZoneLine(personality, realZone)
    end

    local line, source, key = FindAuthoredSubzoneLine(personality, realZone, subZone)
    if line then return line, source, key end
    return FindAuthoredZoneLine(personality, realZone)
end

function Loudmouth.GetEntityTexts(targetUnit)
    local texts = {}
    local function add(value)
        if type(value) == "string" and value ~= "" then texts[#texts + 1] = value end
    end

    -- A table context keeps the matcher deterministic and directly testable.
    if type(targetUnit) == "table" then
        for _, value in ipairs(targetUnit.texts or {}) do add(value) end
        add(targetUnit.name)
        add(targetUnit.class)
        add(targetUnit.race)
        add(targetUnit.creatureType)
        return texts
    end

    if type(targetUnit) ~= "string" or targetUnit == "" then return texts end
    if type(UnitExists) == "function" and not UnitExists(targetUnit) then return texts end

    if type(UnitName) == "function" then add(UnitName(targetUnit)) end
    if type(UnitCreatureType) == "function" then add(UnitCreatureType(targetUnit)) end
    if type(UnitRace) == "function" then
        local raceName, raceFile = UnitRace(targetUnit)
        add(raceName)
        add(raceFile)
    end
    if type(UnitClass) == "function" then
        local className, classFile = UnitClass(targetUnit)
        add(className)
        add(classFile)
    end
    return texts
end

function Loudmouth.GetEntityBanterFromTexts(personality, texts)
    if type(personality) ~= "table" then return nil end

    local hateEntities = personality.hates and personality.hates.entities
    local likeEntities = personality.likes and personality.likes.entities
    local line, key, entry = FindKeywordMatch(hateEntities, texts)
    if line then return line, "hate-entity", key, entry.weight end
    line, key, entry = FindKeywordMatch(likeEntities, texts)
    if line then return line, "like-entity", key, entry.weight end
end

function Loudmouth.GetTargetBanter(personality, targetUnit)
    return Loudmouth.GetEntityBanterFromTexts(personality, Loudmouth.GetEntityTexts(targetUnit))
end

-- ============================================================================
-- Spell name resolver — handles locale/alias mismatches for GetSpellInfo
-- ============================================================================

-- Alias map: common macro/action names → canonical WoW spell names
local SpellAliasMap = {
    ["Hunters Mark"] = "Hunter's Mark",
    ["Multishot"] = "Multi-Shot",
}

-- Classic stone, detection, and mount spells use separately trained names
-- rather than ranks of one spell. Resolve the highest learned variant.
local SpellCandidateMap = {
    ["Soulstone"] = {
        "Create Soulstone (Major)", "Create Soulstone (Greater)", "Create Soulstone",
        "Create Soulstone (Lesser)", "Create Soulstone (Minor)",
    },
    ["Create Healthstone"] = {
        "Create Healthstone (Major)", "Create Healthstone (Greater)", "Create Healthstone",
        "Create Healthstone (Lesser)", "Create Healthstone (Minor)",
    },
    ["Create Firestone"] = {
        "Create Firestone (Major)", "Create Firestone (Greater)", "Create Firestone", "Create Firestone (Lesser)",
    },
    ["Create Spellstone"] = {
        "Create Spellstone (Major)", "Create Spellstone (Greater)", "Create Spellstone",
    },
    ["Detect Invisibility"] = {
        "Detect Greater Invisibility", "Detect Invisibility", "Detect Lesser Invisibility",
    },
    ["Warlock Mount"] = { "Summon Dreadsteed", "Summon Felsteed" },
}

-- Only these actions meaningfully act on the selected unit. Self, pet, area,
-- ground-targeted, and item-creation spells must not produce target banter.
Loudmouth.TargetedActions = {
    ["Shadow Bolt"] = true,
    ["Immolate"] = true,
    ["Corruption"] = true,
    ["Curse of Weakness"] = true,
    ["Curse of Agony"] = true,
    ["Curse of Recklessness"] = true,
    ["Curse of Tongues"] = true,
    ["Curse of the Elements"] = true,
    ["Curse of Shadow"] = true,
    ["Curse of Doom"] = true,
    ["Searing Pain"] = true,
    ["Soul Fire"] = true,
    ["Drain Life"] = true,
    ["Drain Mana"] = true,
    ["Drain Soul"] = true,
    ["Fear"] = true,
    ["Banish"] = true,
    ["Death Coil"] = true,
    ["Soulstone"] = true,
    ["Subjugate Demon"] = true,
    ["Unending Breath"] = true,
    ["Ritual of Summoning"] = true,
    ["Detect Invisibility"] = true,
    ["Curse of Exhaustion"] = true,
    ["Siphon Life"] = true,
    ["Shadowburn"] = true,
    ["Conflagrate"] = true,
}

--- Resolve a spell/action key to a valid spell name for GetSpellInfo.
-- 1. Try the key directly.
-- 2. Try any alias mapping.
-- Returns the spell name or nil.
function Loudmouth._ResolveSpellName(key)
    local candidates = SpellCandidateMap[key]
    if candidates then
        for _, candidate in ipairs(candidates) do
            local name = GetSpellInfo(candidate)
            if name then return name end
        end
        return nil
    end

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

local function ReplaceResponseTokens(template, context)
    local values = {
        ["<target name>"] = context.name or "friend",
        ["<target class>"] = context.class or context.creatureType or "friend",
        ["<target race>"] = context.race or "friend",
    }
    local result = template
    for token, value in pairs(values) do
        result = string.gsub(result, token, function() return value end)
    end
    return result
end

function Loudmouth.GetResponseTargetContext(targetUnit)
    if type(targetUnit) == "table" then return targetUnit end
    if type(targetUnit) ~= "string" or targetUnit == "" then return nil end
    if type(UnitExists) == "function" and not UnitExists(targetUnit) then return nil end

    local context = {}
    if type(UnitName) == "function" then context.name = UnitName(targetUnit) end
    if type(UnitClass) == "function" then context.class = UnitClass(targetUnit) end
    if type(UnitRace) == "function" then context.race = UnitRace(targetUnit) end
    if type(UnitCreatureType) == "function" then context.creatureType = UnitCreatureType(targetUnit) end
    if not context.name and not context.class and not context.race and not context.creatureType then return nil end
    return context
end

function Loudmouth.GetResponseMessage(personality, responseKind, targetContext, sequenceIndex)
    local response = type(personality) == "table" and personality.responses and personality.responses[responseKind]
    if type(response) ~= "table" then return nil end

    local context = Loudmouth.GetResponseTargetContext(targetContext)
    local pool = context and response.target or response.noTarget
    if type(pool) ~= "table" or #pool == 0 then return nil end

    local index = ((tonumber(sequenceIndex) or 1) - 1) % #pool + 1
    return ReplaceResponseTokens(pool[index], context or {}), index, #pool
end

function Loudmouth.Respond(responseKind)
    local personality = Loudmouth.Personalities[Loudmouth.CurrentPersonality]
    if type(personality) ~= "table" then return end

    local nextIndex = Loudmouth.ResponseSequence[responseKind] or 1
    local context = Loudmouth.GetResponseTargetContext("target")
    local message, usedIndex, poolSize = Loudmouth.GetResponseMessage(personality, responseKind, context, nextIndex)
    if not message then return end

    SafeSendChat(message, "SAY")
    Loudmouth.ResponseSequence[responseKind] = usedIndex % poolSize + 1
end

function Loudmouth.Trigger(action, targetUnit)
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
        local pendingKind = Loudmouth.PendingZoneComment and "zone"
            or (Loudmouth.PendingSubzoneComment and "subzone" or "none")
        local likes, hates = Loudmouth.GetLocationPreferences(personality, realZone, subZone)
        print(string.format(
            "|cFF99CCFF[LM ZDebug]|r Zone='%s' | Sub='%s' | Pending=%s | Likes=%s | Hates=%s",
            realZone or "", subZone or "",
            pendingKind, table.concat(likes, ","), table.concat(hates, ",")
        ))
    end

    -- ========================================================================
    -- Pending Zone Comment -- resolve on the first macro call after a location
    -- event. Explicit zone comments and preference metadata are both eligible.
    -- ========================================================================
    local pendingKind = Loudmouth.PendingZoneComment and "zone"
        or (Loudmouth.PendingSubzoneComment and "subzone" or nil)
    if pendingKind then
        local realZone = GetRealZoneText()
        local subZone = GetSubZoneText() or ""

        local line, _, zoneKey, zoneWeight = Loudmouth.GetZoneBanterFromTexts(personality, realZone, subZone, pendingKind)
        local zoneChance = Loudmouth.GetConfiguredChance("zone", zoneKey, zoneWeight or Loudmouth.DefaultZoneChance)
        local sentZoneLine = line and RollChance(zoneChance)
        if sentZoneLine then
            SafeSendChat(line, "SAY")
        end

        if not line and Loudmouth.ShowZoneDebug then
            print(string.format(
                "|cFFFF8800[Dev Alert]|r Missing zone data for '%s' (sub: '%s'). Please add entries!",
                realZone or "", subZone
            ))
        end

        if pendingKind == "zone" then
            Loudmouth.PendingZoneComment = false
        else
            Loudmouth.PendingSubzoneComment = false
        end

        if sentZoneLine then
            return
        end
    end

    local now = GetTime()
    if Loudmouth.Cooldowns[action] and (now - Loudmouth.Cooldowns[action] < Loudmouth.CooldownTime) then
        return
    end

    local actions = type(personality.actions) == "table" and personality.actions or {}
    local actionData = actions[action]
    local genericData = actions["Generic"]
    local phrases = actionData and actionData.lines

    if type(phrases) ~= "table" or #phrases == 0 then phrases = genericData and genericData.lines end

    -- Target preferences replace the normal action phrase, but retain the
    -- action's probability and cooldown so rotational spells do not spam chat.
    local targetLine, _, targetKey, targetWeight = Loudmouth.GetTargetBanter(personality, targetUnit)
    if targetLine then phrases = { targetLine } end

    if type(phrases) == "table" and #phrases > 0 then
        -- Probability check
        local chance = 1.0
        if not Loudmouth.DebugMode then
            local actionWeight = (actionData and actionData.weight) or (genericData and genericData.weight) or 1
            if targetLine then
                chance = Loudmouth.GetConfiguredChance("target", targetKey, targetWeight or Loudmouth.DefaultTargetChance)
            else
                chance = Loudmouth.GetConfiguredChance("spell", action, actionWeight)
            end
        end

        if RollChance(chance) then
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
    Loudmouth.ZoneFrame:SetScript("OnEvent", function(_, event)
        if event == "ZONE_CHANGED_NEW_AREA" then
            Loudmouth.PendingZoneComment = true
        else
            Loudmouth.PendingSubzoneComment = true
        end
    end)
end
