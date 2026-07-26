# Loudmouth Architect Overlay

Additive overlay on the global `agent-architect` role instructions. Preserve the goal,
acceptance criteria, and scope boundary from the dispatched packet.

## Scope Discipline

- Content-only edits (personality dialogue, zone/subzone lines, banter text) need NO new
  automated tests: do not add test-writing steps or test-count acceptance criteria unless
  the caller explicitly asks. The existing `luacheck .` + `./tests/ui-test.sh` gates are
  the verification. (Observed: plans that ordered "focused regression tests" for dialogue
  edits doubled the diff and produced buggy throwaway tests.)
- Classify findings using the classification taxonomy delivered with your Return Contract.
- Treat PRD gaps or broad release-hardening items as `future work` unless the dispatched acceptance
  criteria explicitly include them.
- Do not convert historical REVIEW/PRD concerns into blockers unless the current change
  violates them or the packet requests a full release audit.

## Loudmouth-Specific Checks

For in-scope changes, verify:
- all addon code remains under `Interface/AddOns/Loudmouth/`;
- Classic Era API safety: no `UIPanelFrameTemplate`, no unguarded `SetBackdrop`, no third
  argument to `CreateFontString`, no Lua 5.2 syntax;
- macro APIs are not called in combat and account-wide macro behavior is intentional;
- chat remains player-initiated through macros calling `Loudmouth.Trigger()`;
- personality files register into `_RawPersonalities` and contain `Generic` fallback lines;
- core/UI changes are verified by `luacheck .` and `./tests/ui-test.sh`.

