# Loudmouth Coding Overlay

Additive overlay on the global `agent-code` role instructions.

## Repo Layout

- Addon code lives under `Interface/AddOns/Loudmouth/`; do not add implementation files at
  the repo root or under `addon_examples/`, `_classic_era_/`, or `tools/`.
- Personality files live under `Interface/AddOns/Loudmouth/Personalities/` and must be added
  to `Loudmouth.toc` before core files when new files are introduced.

## Classic Era Lua/API Rules

- Classic Era uses Lua 5.1: no `goto`, no `::label::`, no Lua 5.2+ syntax.
- The frame/template/table-init rules are in AGENTS.md ("Classic-Era gotchas") and apply
  here in full; do not restate them, follow them.
- Add new WoW globals to `.luacheckrc`; do not use inline luacheck suppressions.

## Macro And Combat Safety

- `CreateMacro`, `EditMacro`, and `DeleteMacro` are combat-restricted. Guard with
  `InCombatLockdown()` and defer work instead of calling them in combat.
- Loudmouth account-wide macros use fixed names `LM_01`..`LM_99`; do not reintroduce
  spell-name or abbreviation macro names without architect approval.
- Do not delete unrelated user macros; cleanup must target Loudmouth-owned names only.

## Lua Structure And Existing Contracts

- Declare `local function` helpers BEFORE the function that calls them. A helper
  declared after `Loudmouth.Trigger()` resolves to a nil global at runtime and
  crashes the feature the first time it fires.
- Trait dialogue must respect the existing cooldown. `Loudmouth.Trigger()` checks
  `Loudmouth.Cooldowns[action]` near the top and writes the same key after speaking.
  If a trait overrides the action, EITHER keep writing `Cooldowns[action]`, OR update
  BOTH the check and the write to your new key. A write whose key is never checked
  means the cooldown silently does nothing.
- New WoW globals (e.g. `UnitName`) must be added to `.luacheckrc` in the same
  change -- `luacheck .` must stay at 0 warnings / 0 errors.

## Verification

- Your sanctioned focused check is `luacheck .` -- it is fast in this repo and an
  explicit exception to the global no-broad-lint rule.
- Leave `./tests/ui-test.sh` to `agent-test`; run it yourself only if the dispatched
  task explicitly asks you to.
- Put the exact command output (PASS/FAIL) and changed files (`path:line`) in your
  **EVIDENCE**. Do not claim success from intent.
