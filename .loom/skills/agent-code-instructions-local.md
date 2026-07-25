# Loudmouth Coding Overlay

Additive overlay on the global `agent-code` role instructions.

## Repo Layout

- Addon code lives under `Interface/AddOns/Loudmouth/`; do not add implementation files at
  the repo root or under `addon_examples/`, `_classic_era_/`, or `tools/`.
- Personality files live under `Interface/AddOns/Loudmouth/Personalities/` and must be added
  to `Loudmouth.toc` before core files when new files are introduced.

## Classic Era Lua/API Rules

- Classic Era uses Lua 5.1: no `goto`, no `::label::`, no Lua 5.2+ syntax.
- Use `BackdropTemplate`; never use `UIPanelFrameTemplate`.
- Guard `SetBackdrop`: mix in `BackdropTemplateMixin` when needed and call only if present.
- Call `frame:CreateFontString()` with no third argument; then call `SetFontObject(...)`.
- Initialize shared tables as `X = X or {}`.
- Add new WoW globals to `.luacheckrc`; do not use inline luacheck suppressions.

## Macro And Combat Safety

- `CreateMacro`, `EditMacro`, and `DeleteMacro` are combat-restricted. Guard with
  `InCombatLockdown()` and defer work instead of calling them in combat.
- Loudmouth account-wide macros use fixed names `LM_01`..`LM_99`; do not reintroduce
  spell-name or abbreviation macro names without architect approval.
- Do not delete unrelated user macros; cleanup must target Loudmouth-owned names only.

## Verification

- Your sanctioned focused check is `luacheck .` -- it is fast in this repo and an
  explicit exception to the global no-broad-lint rule.
- Leave `./tests/ui-test.sh` to `agent-test`; run it yourself only if the dispatched
  task explicitly asks you to.
- Put the exact command output (PASS/FAIL) and changed files (`path:line`) in your
  **EVIDENCE**. Do not claim success from intent.
