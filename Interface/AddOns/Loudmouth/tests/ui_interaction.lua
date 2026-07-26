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
