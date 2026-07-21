---
name: agent-team-extend
description: Loudmouth-specific routing overlay for agent-team. Defines when Team must use architect before coder and when direct coder edits are acceptable.
---

# Loudmouth Team Overlay

Use this as an additive overlay on the global `agent-team` skill. Do not weaken the
global scope-control, task-id reuse, review, or finding-classification rules.

## Architect First

Send `agent-architect` before `agent-code` for changes touching:
- macro generation, macro naming, macro cleanup, or slot capacity;
- account-wide vs per-character macro behavior;
- combat/protected WoW APIs (`CreateMacro`, `EditMacro`, `DeleteMacro`, protected UI calls);
- WoW event lifecycle (`PLAYER_ENTERING_WORLD`, `ZONE_CHANGED`, `PLAYER_REGEN_ENABLED`, etc.);
- SavedVariables or reload persistence;
- UI frame construction, backdrops, font strings, or config-panel layout;
- personality loading/filtering or `.toc` load order;
- zone/subzone commentary engine or location matching;
- Classic Era API compatibility where behavior is uncertain.

When architect is used for a feature, reuse the same architect `task_id` for all re-reviews
of that feature and preserve the original acceptance criteria.

## Coder Direct Is Acceptable

`agent-code` may be used directly for narrow, low-risk edits:
- dialogue text changes;
- trigger weight adjustments;
- spelling/typo fixes;
- adding verified spell/action lines to an existing personality;
- small docs/template updates.

If a direct edit causes a Lua error, UI harness failure, macro-generation bug, or scope
uncertainty, stop coding and escalate to `agent-architect` before further implementation.

## Verification Routing

After core or UI changes, delegate verification to `agent-test`; it will auto-load
`agent-test-extend` and run the Loudmouth gates.
