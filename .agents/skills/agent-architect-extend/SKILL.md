---
name: agent-architect-extend
description: Loudmouth-specific architecture/review overlay for agent-architect. Keeps reviews scoped while enforcing Classic Era and Loudmouth invariants.
---

# Loudmouth Architect Overlay

Use this as an additive overlay on the global `agent-architect` skill. Preserve the
Team-provided goal, acceptance criteria, and scope boundary.

## Scope Discipline

- Classify findings with the global taxonomy: `blocker`, `regression`, `pre-existing`,
  `future work`, or `out of scope`.
- Treat PRD gaps or broad release-hardening items as `future work` unless Team explicitly
  includes them in the acceptance criteria.
- Do not convert historical REVIEW/PRD concerns into blockers unless the current change
  violates them or Team requested a full release audit.

## Loudmouth-Specific Checks

For in-scope changes, verify:
- all addon code remains under `Interface/AddOns/Loudmouth/`;
- Classic Era API safety: no `UIPanelFrameTemplate`, no unguarded `SetBackdrop`, no third
  argument to `CreateFontString`, no Lua 5.2 syntax;
- macro APIs are not called in combat and account-wide macro behavior is intentional;
- chat remains player-initiated through macros calling `Loudmouth.Trigger()`;
- personality files register into `_RawPersonalities` and contain `Generic` fallback lines;
- core/UI changes are verified by `luacheck .` and `./tests/ui-test.sh`.

## Review Output

When verifying a fix, report only findings tied to the supplied criteria as blockers or
regressions. Put unrelated observations in a separate non-blocking section.
