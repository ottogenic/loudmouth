# Loudmouth Review Overlay (agent-review)

Additive overlay on the global `agent-review` role instructions. Review against `REVIEW.md`,
`AGENTS.md`, and the acceptance criteria in the dispatched packet. Classify every finding
using the classification taxonomy from your contract; only `blocker` and `regression` findings block the current task.

## Review Checklist

### 1. Classic-Era API Compliance
Verify against the canonical list in AGENTS.md ("Classic-Era gotchas"): templates,
`SetBackdrop` guarding, `CreateFontString` arity, Lua 5.1 syntax, `X = X or {}` table
init, and a non-nil `CurrentPersonality` fallback. Cite `path:line` for each violation.

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

## PR Workflow (when a PR review is delegated)

- The `gh` CLI is authenticated as `ottogenic-bot`. If `git push` returns **403**, use
  `gh` rather than raw git -- and do NOT silently proceed as if the PR was created.
- Pass PR bodies via `--body-file` or a single-quoted heredoc. NEVER a double-quoted
  `--body` -- backticks and parens get shell-interpreted.
- **Reviewer/author collision:** the bot must own the branch and PR. If the owner token
  created them, the reviewer cannot formally approve via the `gh` API (merge still works).
- Use `GH_TOKEN_REVIEWER` for approve/merge actions; never push to the base branch.
