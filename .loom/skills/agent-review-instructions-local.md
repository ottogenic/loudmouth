# Loudmouth Review Overlay (agent-review)

Additive overlay on the global `agent-review` role instructions. Review against `REVIEW.md`,
`AGENTS.md`, and the acceptance criteria in the dispatched packet. Classify every finding
using the classification taxonomy from your contract; only `blocker` and `regression` findings block the current task.

## Review Checklist

### 1. Classic-Era API Compliance
- **Templates:** Ensure `UIPanelFrameTemplate` is NOT used. Use `BackdropTemplate`.
- **Backdrops:** Guard `SetBackdrop`: mix in `BackdropTemplateMixin` when needed and
  call `SetBackdrop` only if it exists.
- **Font Strings:** Verify `CreateFontString()` is called without a third argument;
  set font objects afterward with `SetFontObject(...)`.
- **Lua version:** No Lua 5.2+ syntax such as `goto` or `::label::`; Classic Era is Lua 5.1.
- **Table Init:** Shared tables must be initialized as `X = X or {}` to prevent `.toc`
  load-order wipes.
- **Stability:** `CurrentPersonality` must have a safe fallback path; no nil concatenation.

### 2. ToS And Protected APIs
- Chat must be emitted via `Loudmouth.Trigger()` from player-initiated macros.
- Do not automate gameplay or protected functions from addon code.
- `CreateMacro`, `EditMacro`, and `DeleteMacro` must be guarded for combat lockdown and
  deferred rather than called in combat.

### 3. Macro System
- Account-wide Loudmouth macros use fixed positional names (`LM_01`, `LM_02`, ...).
- Cleanup must not delete unrelated user macros.
- Capacity checks must account for managed macros reclaimed before creating new ones.

### 4. Personality Standards
- Files follow `<Race><Gender><Class><Personality>.lua`.
- Personality payloads register into `Loudmouth._RawPersonalities`, not directly into
  `Loudmouth.Personalities`.
- Every personality has a `Generic` bucket with at least 3 lines.
- Personality files are pure data; no WoW API calls.

### 5. Verification
- `luacheck .` must report 0 warnings / 0 errors.
- `./tests/ui-test.sh` must report `RESULT: PASS`.
