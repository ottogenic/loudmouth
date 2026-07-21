version = "5.1"
globals = {
    "date",
    "ARG",
    "C_Timer",
    "CreateFrame",
    "Mixin",
    "BackdropTemplateMixin",
    "debugstack",
    "geterrorhandler",
    "GetCallstackHeight",
    "GetErrorCallstackHeight",
    "GetLocale",
    "GetRealZoneText",
    "GetSubZoneText",
    "GetTime",
    "hooksecurefunc",
    "Loudmouth",
    "NUM_CHAT_WINDOWS",
    "Slashes",
    "SendChatMessage",
    "SlashCmdList",
    "UIParent",
    "UnitClass",
    "UnitRace",
    "UnitSex",
    "GetSpellInfo",
    "IsSpellKnown",
    "CreateMacro",
    "wipe",
    "seterrorhandler",
    "SLASH_LOUDMOUTH1",
    "SLASH_LOUDMOUTH2",
    "SLASH_LOUDMOUTHCOPYERRORS1",
    "SLASH_LOUDMOUTHCOPYERRORS2",
    -- UIDropDownMenu API (Classic Era)
    "ToggleDropDownMenu",
    "UIDropDownMenu_CreateInfo",
    "UIDropDownMenu_Initialize",
    "UIDropDownMenu_AddButton",
    "UIDropDownMenu_SetText",
    "UIDropDownMenu_SetWidth",
    "UIDropDownMenu_SetSelectedValue",
    -- Macro API
    "DeleteMacro",
    "EditMacro",
    "GetMacroIndexByName",
    "LoudmouthDB",
    "GetNumMacros",
    "GetMacroInfo",
    "InCombatLockdown",
    "LoudmouthConfigFrame",
}

-- Only lint our addon code. Everything else in this repo is either the
-- git-ignored wow-ui-sim build (tools/), vendored Blizzard UI source, or the
-- Classic-Era data drop (_classic_era_/). Scoping here means `luacheck .` from
-- the repo root Just Works and reports only Loudmouth's own files.
include_files = {
    "Interface/AddOns/Loudmouth/**/*.lua",
}
exclude_files = {
    "tools/",
    "_classic_era_/",
    "addon_examples/",
}

-- The interaction tests run under wow-ui-sim's TestFramework, which injects
-- test() and the assert* helpers as globals. Whitelist them for the tests dir only.
files["Interface/AddOns/Loudmouth/tests/"] = {
    read_globals = {
        "test", "async_test",
        "LoudmouthConfigFrame",
        "assertEquals", "assertNotEquals", "assertTrue", "assertFalse",
        "assertNil", "assertNotNil", "assertError", "assertType",
        "assertAlmostEquals", "assertContains", "assertStartsWith",
        "assertEndsWith", "assertMatches", "assertCount",
        "assertTableEquals", "assertTableContains",
    },
}
