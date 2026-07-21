---
name: agent-code-extend
description: Loudmouth-specific implementation guardrails for agent-code: Classic Era Lua/API gotchas, macro safety, file layout, and required verification.
---

# Loudmouth Coding Overlay

Use this as an additive overlay on the global `agent-code` skill.

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

- Run `luacheck .` after code changes.
- Run `./tests/ui-test.sh` after UI/core behavior changes.
- Report exact PASS/FAIL output and changed files. Do not claim success from intent.
