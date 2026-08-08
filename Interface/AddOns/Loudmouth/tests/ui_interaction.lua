-- Loudmouth UI interaction tests
-- Run headlessly via: wow-sim run-tests Loudmouth
-- These drive the actual config-panel buttons the same way a player click would,
-- asserting the resulting state/behaviour (not just that the widgets exist).

local function findChildButton(prefix)
    if not LoudmouthConfigFrame then return nil end
    local function walk(frame)
        for _, kid in ipairs({ frame:GetChildren() }) do
            if kid.GetText and kid:GetText() and string.find(kid:GetText(), prefix, 1, true) then
                return kid
            end
            if kid.GetChildren then
                local match = walk(kid)
                if match then return match end
            end
        end
    end
    return walk(LoudmouthConfigFrame)
end

local function distinctLineCount(lines)
    local seen, count = {}, 0
    for _, line in ipairs(lines or {}) do
        if not seen[line] then
            seen[line] = true
            count = count + 1
        end
    end
    return count
end

test("config panel starts hidden and slash command toggles it", function()
    assertNotNil(LoudmouthConfigFrame)
    assertTrue(LoudmouthConfigFrame:IsObjectType("Frame"))
    assertFalse(LoudmouthConfigFrame:IsShown())
    SlashCmdList["LOUDMOUTH"]()
    assertTrue(LoudmouthConfigFrame:IsShown())
    SlashCmdList["LOUDMOUTH"]()
    assertFalse(LoudmouthConfigFrame:IsShown())
    SlashCmdList["LOUDMOUTH"]()
end)

test("Debug Mode button toggles state and updates its label", function()
    local btn = findChildButton("Debug Mode")
    assertNotNil(btn)

    -- Normalise to a known starting point (OFF).
    Loudmouth.DebugMode = false
    btn:SetText("Debug Mode: OFF")

    btn:Click()
    assertTrue(Loudmouth.DebugMode)
    assertEquals("Debug Mode: ON", btn:GetText())

    btn:Click()
    assertFalse(Loudmouth.DebugMode)
    assertEquals("Debug Mode: OFF", btn:GetText())
end)

test("Generate Macros button is clickable and handles a valid personality", function()
    local btn = findChildButton("Generate Macros")
    assertNotNil(btn)
    -- Ensure a personality is selected so the handler takes its normal path.
    -- FilterPersonalities() runs in InitUI() and sets CurrentPersonality.
    assertNotNil(Loudmouth.CurrentPersonality)
    -- Clicking must not raise an error.
    local ok, err = pcall(function() btn:Click() end)
    assert(ok, err)
    assertTrue(Loudmouth.GenerateMacros())
end)

test("Copy Errors button invokes the CopyChat module", function()
    local btn = findChildButton("Copy Errors")
    assertNotNil(btn)

    local called = false
    local original = Loudmouth.CopyChat and Loudmouth.CopyChat.Show
    Loudmouth.CopyChat = Loudmouth.CopyChat or {}
    Loudmouth.CopyChat.Show = function() called = true end

    btn:Click()
    assertTrue(called)

    Loudmouth.CopyChat.Show = original -- restore
end)

test("Close button hides the panel", function()
    local close = _G["LoudmouthConfigFrameCloseButton"]
    assertNotNil(close)

    LoudmouthConfigFrame:Show()
    assertTrue(LoudmouthConfigFrame:IsShown())

    close:Click()
    assertFalse(LoudmouthConfigFrame:IsShown())

    LoudmouthConfigFrame:Show() -- leave it visible for any later render checks
end)

test("every banter line fits the SendChatMessage 255-char game limit", function()
    -- Chat messages beyond 255 chars are truncated by the client: an over-long
    -- banter entry is a real in-game bug, not a style issue. Walk every string
    -- in every personality: zones/subzones/actions lines tables alike.
    local function walk(t, where)
        for k, v in pairs(t) do
            if type(v) == "table" then
                walk(v, where .. "." .. tostring(k))
            elseif type(v) == "string" and k ~= "name" then
                assertTrue(#v <= 255,
                    ("banter line exceeds 255 chars (%d) at %s: %s..."):format(
                        #v, where, v:sub(1, 60)))
            end
        end
    end
    -- The loader consumes _RawPersonalities at startup (Loudmouth.lua sets it
    -- to nil after filtering into Loudmouth.Personalities) -- walk the survivor.
    local reg = Loudmouth.Personalities or Loudmouth._RawPersonalities
    assertNotNil(reg)
    local count = 0
    for name, p in pairs(reg) do
        count = count + 1
        walk(p, name)
    end
    assertTrue(count > 0, "no personalities registered to check")
end)

test("Classic metadata covers Era zones, instances, and parent-scoped subzones", function()
    assertNotNil(Loudmouth.ClassicZones[1411])
    assertEquals("Durotar", Loudmouth.ClassicZones[1411].name)
    assertEquals("Ironforge", Loudmouth.ClassicZones[1455].name)
    assertEquals("Uldaman", Loudmouth.ClassicInstances[1337])
    assertTrue(#Loudmouth.ClassicSubzones["Dun Morogh"] > 10)
    assertTrue(#Loudmouth.ClassicSubzones["Duskwood"] > 10)
    assertEquals(3, Loudmouth.ZoneRaceMetadata["Ironforge"].dwarf)
end)

test("zone preferences match race and vibe metadata", function()
    local personality = {
        likes = { zones = { "graveyard", "cave" } },
        hates = { zones = { "dwarf" } },
    }

    local likes, hates = Loudmouth.GetLocationPreferences(personality, "City of Ironforge", "The Great Forge")
    assertEquals(0, #likes)
    assertEquals("dwarf", hates[1])

    likes, hates = Loudmouth.GetLocationPreferences(personality, "Duskwood", "Raven Hill Cemetery")
    assertEquals("graveyard", likes[1])
    assertEquals(0, #hates)

    likes, hates = Loudmouth.GetLocationPreferences(personality, "Uldaman", "The Map Chamber")
    assertEquals("cave", likes[1])
    assertEquals("dwarf", hates[1])

    likes, hates = Loudmouth.GetLocationPreferences(personality, "Mulgore", "Bloodhoof Village")
    assertEquals(0, #likes)
    assertEquals(0, #hates)

    likes, hates = Loudmouth.GetLocationPreferences(personality, "Mulgore", "Bael'dun Digsite")
    assertEquals(0, #likes)
    assertEquals("dwarf", hates[1])
end)

test("zone traits have no generic dialogue and exact locations own their comments", function()
    local personality = {
        zones = {
            ["City of Ironforge"] = { lines = { "Specific city line" } },
        },
        hates = { zones = { "dwarf" } },
    }

    local line, source = Loudmouth.GetZoneBanterFromTexts(personality, "Ironforge", "The Great Forge")
    assertEquals("Specific city line", line)
    assertEquals("zone", source)
end)

test("parent-scoped subzone comments are selected only for subzone events", function()
    local personality = {
        zones = {
            ["Dun Morogh"] = { lines = { "Zone line" } },
        },
        subzones = {
            ["Dun Morogh"] = {
                ["The Grizzled Den"] = { lines = { "Specific cave and dwarf line" } },
            },
        },
    }

    local line = Loudmouth.GetZoneBanterFromTexts(personality, "Dun Morogh", "The Grizzled Den", "subzone")
    assertEquals("Specific cave and dwarf line", line)

    line = Loudmouth.GetZoneBanterFromTexts(personality, "Dun Morogh", "The Grizzled Den", "zone")
    assertEquals("Zone line", line)
end)

test("literal zone keys beat longer aliases", function()
    local personality = {
        zones = {
            ["City of Ironforge"] = { lines = { "Alias city line" } },
            ["Iron Forge"] = { lines = { "Literal city line" } },
        },
    }

    local line = Loudmouth.GetZoneBanterFromTexts(personality, "Iron Forge", "")
    assertEquals("Literal city line", line)
end)

test("entity preferences inspect name class race and creature type", function()
    local personality = {
        likes = {
            entities = {
                ["gnome"] = { weight = 1 / 20, lines = { "Gnome like" } },
                ["mechanical"] = { lines = { "Machine like" } },
            },
        },
        hates = {
            entities = {
                ["dwarf"] = { lines = { "Dwarf hate" } },
                ["dark iron dwarf"] = { lines = { "Dark Iron hate" } },
            },
        },
    }

    local line, source, key = Loudmouth.GetTargetBanter(personality, { name = "Dark Iron Dwarf" })
    assertEquals("Dark Iron hate", line)
    assertEquals("hate-entity", source)
    assertEquals("dark iron dwarf", key)

    local result = { Loudmouth.GetTargetBanter(personality, { race = "Gnome" }) }
    assertEquals("Gnome like", result[1])
    assertEquals(1 / 20, result[4])

    line = Loudmouth.GetTargetBanter(personality, { creatureType = "Mechanical" })
    assertEquals("Machine like", line)

    line = Loudmouth.GetTargetBanter(personality, { name = "Gnome Dwarf" })
    assertEquals("Dwarf hate", line)
end)

test("macro target context is limited to spells that act on selected units", function()
    local drainBody = Loudmouth.BuildMacroBody("Drain Life", "Drain Life")
    assertContains(drainBody, 'Loudmouth.Trigger("Drain Life","target")')

    local armorBody = Loudmouth.BuildMacroBody("Demon Armor", "Demon Armor")
    assertContains(armorBody, 'Loudmouth.Trigger("Demon Armor")')
    assertFalse(string.find(armorBody, '"target"', 1, true) ~= nil)

    local createBody = Loudmouth.BuildMacroBody("Create Healthstone", "Create Healthstone (Major)")
    assertContains(createBody, 'Loudmouth.Trigger("Create Healthstone")')
    assertFalse(string.find(createBody, '"target"', 1, true) ~= nil)
end)

test("healthstone and soulstone macro bodies handle every Classic tier", function()
    local healingBody = Loudmouth.BuildMacroBody("Healing Items")
    assertContains(healingBody, "/use Major Healthstone")
    assertContains(healingBody, "/use Minor Healthstone")
    assertFalse(string.find(healingBody, "/castsequence", 1, true) ~= nil)
    assertTrue(#healingBody <= 255)

    local soulstoneBody = Loudmouth.BuildMacroBody("Soulstone", "Create Soulstone (Major)")
    assertContains(soulstoneBody, "/use Major Soulstone")
    assertContains(soulstoneBody, "/use Minor Soulstone")
    assertContains(soulstoneBody, "/cast Create Soulstone (Major)")
    assertContains(soulstoneBody, 'Loudmouth.Trigger("Soulstone","target")')
    assertTrue(#soulstoneBody <= 255)
end)

test("Warlock macro order and personality actions remain in parity", function()
    local order = Loudmouth.ActionOrderByClass.Warlock
    local ordered = {}
    for _, action in ipairs(order) do ordered[action] = true end

    assertTrue(ordered["Drain Life"])
    assertTrue(ordered["Drain Soul"])
    assertTrue(ordered["Create Healthstone"])
    assertFalse(ordered["Generic"] == true)

    local personality = Loudmouth.Personalities["HumanFemaleWarlockProfessional"]
    assertNotNil(personality)
    assertEquals(1 / 20, personality.likes.entities.gnome.weight)
    assertEquals(1 / 20, personality.hates.entities.dwarf.weight)
    for _, action in ipairs(order) do
        local entry = personality.actions[action]
        assertNotNil(entry, "missing personality action: " .. action)
        assertTrue(type(entry.lines) == "table" and #entry.lines > 0, "empty personality action: " .. action)
    end
    for action in pairs(personality.actions) do
        assertTrue(action == "Generic" or ordered[action] == true, "action has no generated macro: " .. action)
    end
end)

test("warlock spells and zones each have five distinct comments", function()
    local personality = Loudmouth.Personalities["HumanFemaleWarlockProfessional"]
    for action, entry in pairs(personality.actions) do
        assertTrue(distinctLineCount(entry.lines) >= 5, "fewer than five distinct action lines: " .. action)
    end
    for zone, entry in pairs(personality.zones) do
        assertTrue(distinctLineCount(entry.lines) >= 5, "fewer than five distinct zone lines: " .. zone)
    end
end)

test("chance controls persist personality-scoped overrides", function()
    local originalPersonality = Loudmouth.CurrentPersonality
    Loudmouth.SetConfiguredChance("spell", "Shadow Bolt", 0.73)
    assertAlmostEquals(0.73, Loudmouth.GetConfiguredChance("spell", "Shadow Bolt", 0.01), 0.001)
    Loudmouth.ClearConfiguredChance("spell", "Shadow Bolt")
    assertAlmostEquals(0.01, Loudmouth.GetConfiguredChance("spell", "Shadow Bolt", 0.01), 0.001)
    Loudmouth.CurrentPersonality = originalPersonality
end)

test("sidebar pages and chance sliders are available", function()
    assertNotNil(Loudmouth.ConfigPages.General)
    assertNotNil(Loudmouth.ConfigPages.Spell)
    assertNotNil(Loudmouth.ConfigPages.Zone)
    assertNotNil(Loudmouth.ConfigPages.Target)
    Loudmouth.ShowConfigPage("Spell")
    assertTrue(Loudmouth.ConfigPages.Spell:IsShown())
    assertFalse(Loudmouth.ConfigPages.General:IsShown())
    assertNotNil(_G.LoudmouthSpellChanceSlider)
    assertNotNil(_G.LoudmouthZoneChanceSlider)
    assertNotNil(_G.LoudmouthTargetChanceSlider)

    local spellEditor = Loudmouth.ChanceEditors[1]
    _G.LoudmouthSpellChanceSlider:SetValue(0.5)
    assertAlmostEquals(0.5, _G.LoudmouthSpellChanceSlider:GetValue(), 0.0001)
    spellEditor:Refresh()
    Loudmouth.ShowConfigPage("General")
end)

test("generic response macros provide eight sequential target-aware responses", function()
    local personality = Loudmouth.Personalities["HumanFemaleWarlockProfessional"]
    for _, responseKind in ipairs(Loudmouth.ResponseMacroOrder) do
        local response = personality.responses[responseKind]
        assertEquals(8, #response.target)
        assertEquals(8, #response.noTarget)
        assertContains(Loudmouth.BuildResponseMacroBody(responseKind), 'Loudmouth.Respond("' .. responseKind .. '")')
    end

    local targeted = Loudmouth.GetResponseMessage(personality, "Yes", { name = "Mira", class = "Mage" }, 1)
    assertContains(targeted, "Mage")
    assertFalse(string.find(targeted, "<target", 1, true) ~= nil)
    local untargeted = Loudmouth.GetResponseMessage(personality, "Yes", nil, 1)
    assertContains(untargeted, "friend")
    local wrapped, index = Loudmouth.GetResponseMessage(personality, "Yes", nil, 9)
    assertEquals(1, index)
    assertEquals(untargeted, wrapped)
end)

test("zone comments are complete utterances rather than split continuations", function()
    local personality = Loudmouth.Personalities["HumanFemaleWarlockProfessional"]
    local fragments = {
        "An entire city preserved in undeath.",
        "A chaotic masterpiece perfectly suited for my craft.",
        "However, Zul'Farrak offers plenty of ancient curses to study.",
    }
    for _, zone in pairs(personality.zones) do
        for _, line in ipairs(zone.lines or {}) do
            for _, fragment in ipairs(fragments) do
                assertNotEquals(fragment, line)
            end
        end
    end
end)
