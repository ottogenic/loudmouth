-- Loudmouth UI interaction tests
-- Run headlessly via: wow-sim run-tests Loudmouth
-- These drive the actual config-panel buttons the same way a player click would,
-- asserting the resulting state/behaviour (not just that the widgets exist).

local function findChildButton(prefix)
    if not LoudmouthConfigFrame then return nil end
    for _, kid in ipairs({ LoudmouthConfigFrame:GetChildren() }) do
        if kid.GetText and kid:GetText() and string.find(kid:GetText(), prefix, 1, true) then
            return kid
        end
    end
end

test("config panel exists after load", function()
    assertNotNil(LoudmouthConfigFrame)
    assertTrue(LoudmouthConfigFrame:IsObjectType("Frame"))
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

test("likes/hates helpers match zone and target context", function()
    local personality = {
        likes = {
            places = {
                Lake = { lines = { "Lake like line" } },
            },
            entities = {
                Gnome = { lines = { "Gnome like line" } },
            },
        },
        hates = {
            places = {
                Ironforge = { lines = { "Ironforge hate line" } },
            },
            entities = {
                Dwarf = { lines = { "Dwarf hate line" } },
            },
        },
    }

    local line = Loudmouth.GetZoneBanterFromTexts(personality, "Ironforge", "")
    assertEquals("Ironforge hate line", line)

    line = Loudmouth.GetZoneBanterFromTexts(personality, "The Great Sea", "Lake Shore")
    assertEquals("Lake like line", line)

    line = Loudmouth.GetTargetBanter(personality, { name = "Dark Iron Dwarf" })
    assertEquals("Dwarf hate line", line)

    line = Loudmouth.GetTargetBanter(personality, { name = "Leper Gnome" })
    assertEquals("Gnome like line", line)
end)

test("likes/hates override broader zone substring matches", function()
    local personality = {
        zones = {
            ["City of Ironforge"] = { lines = { "City line" } },
        },
        hates = {
            places = {
                Ironforge = { lines = { "Ironforge hate line" } },
            },
        },
    }

    local line = Loudmouth.GetZoneBanterFromTexts(personality, "Ironforge", "")
    assertEquals("Ironforge hate line", line)
end)

test("broader zone substring matches still beat subzone keywords", function()
    local personality = {
        zones = {
            ["City of Ironforge"] = { lines = { "City line" } },
        },
        subzones = {
            ["The Commons"] = { lines = { "Subzone line" } },
        },
    }

    local line = Loudmouth.GetZoneBanterFromTexts(personality, "Ironforge", "The Commons")
    assertEquals("City line", line)
end)

test("target-aware macro body passes target to Loudmouth.Trigger", function()
    local body = Loudmouth.BuildMacroBody("Shadow Bolt", "Shadow Bolt")
    assertNotNil(body)
    assertTrue(string.find(body, 'Loudmouth.Trigger("Shadow Bolt", "target")', 1, true) ~= nil)
end)
