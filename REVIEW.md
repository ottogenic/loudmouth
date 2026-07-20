# Review Bar — Loudmouth

All PRs must meet the following criteria before merging:

## Technical Bar
- [ ] **Linting:** `luacheck .` must return 0 errors and 0 warnings. (`.luacheckrc`
      scopes this to `Interface/AddOns/Loudmouth/` — it does NOT lint vendored `tools/`.)
- [ ] **Classic-Era API:** No `UIPanelFrameTemplate`; uses `BackdropTemplate`.
- [ ] **Font Strings:** No 3rd arg in `CreateFontString()`.
- [ ] **State:** Shared tables initialized as `X = X or {}`.
- [ ] **Stability:** `CurrentPersonality` is never left `nil`.

## Product Bar
- [ ] **ToS Compliance:** No automation of protected functions. Chat is triggered by player macros.
- [ ] **Naming:** Personality files follow `<Race><Gender><Class><Personality>.lua`.
- [ ] **Content:** Each personality has a `["Generic"]` bucket with 3+ lines.
