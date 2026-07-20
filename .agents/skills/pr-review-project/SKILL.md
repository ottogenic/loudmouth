---
name: pr-review-project
description: Review PRs for the Loudmouth addon. Checks for Classic-Era API compliance (BackdropTemplate), ToS-safe macro loops, and personality file naming conventions.
---

# Skill: Loudmouth PR Review

This skill defines the quality bar for all contributions to the Loudmouth addon. The reviewer must verify the PR against the `REVIEW.md` bar and the `AGENTS.md` invariants.

## Review Checklist

### 1. Classic-Era API Compliance
- **Templates:** Ensure `UIPanelFrameTemplate` is NOT used. Use `BackdropTemplate`.
- **Font Strings:** Verify `CreateFontString()` is called without the deprecated 3rd argument.
- **Table Init:** Ensure shared tables are initialized as `X = X or {}` to prevent `.toc` load-order wipes.
- **Stability:** Verify `CurrentPersonality` is never left `nil` (must have a fallback).

### 2. ToS & Automation
- **Trigger Mechanism:** Chat must be emitted via `Loudmouth.Trigger()`.
- **Execution:** The trigger must be called by a player-initiated macro.
- **Protected Functions:** Ensure no protected functions (e.g., `CastSpellByName`) are called directly by Lua scripts during combat.

### 3. Personality Standards
- **Naming:** Files must follow `<Race><Gender><Class><Personality>.lua`.
- **Structure:** Table keys must match the filename.
- **Content:** Every personality must include a `["Generic"]` bucket with at least 3 lines.

### 4. Code Quality
- **Linting:** Run `luacheck .`. The PR is blocked if any errors or warnings remain.
- **Hygiene:** No trailing whitespace, no secrets, and no third-party examples (e.g. `addon_examples/`) committed.

## Review Process
1. **Audit:** Run the checklist.
2. **Report:** If issues are found, provide an itemized list of failures with suggested fixes.
3. **Merge:** Merge only when the `REVIEW.md` bar is fully met.
