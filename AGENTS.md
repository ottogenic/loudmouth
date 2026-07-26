# AGENTS.md — Loudmouth Operating Manual

Loaded into EVERY agent session, every turn. Keep it to what every role needs:
repo shape, what is ours vs. not, and the Classic-Era rules that constrain all work.
Role-specific procedure belongs in `.loom/skills/agent-<role>-instructions-local.md`.

Loudmouth is a **World of Warcraft Classic Era (Hardcore)** addon that makes your
character speak context-aware, personality-driven banter on actions, pets, and zones.
Chat is triggered by **player-initiated macros** that call an addon function — never by
gameplay automation (ToS compliance).

## Repository layout (MEMORIZE THIS)

```
Interface/AddOns/Loudmouth/        <- ALL addon code lives here, NOT the repo root
├── Loudmouth.toc                  <- load order (Personalities load BEFORE Loudmouth.lua)
├── Loudmouth.lua                  <- core engine: probability, GCD, detection, Trigger()
├── UI.lua                         <- config frame, macro generator, slash commands
├── CopyChat.lua
└── Personalities/                 <- drop-in personality files
    └── HumanFemaleWarlockProfessional.lua
docs/                              <- PRD, CHECKLIST, RESEARCH_NOTES
.luacheckrc                        <- luacheck config (WoW globals whitelisted)
tests/ui-test.sh                   <- headless UI harness (see agent-test instructions)
```

**Invariant:** Addon files are under `Interface/AddOns/Loudmouth/`. Do NOT assume repo
root. Personality files are under `Interface/AddOns/Loudmouth/Personalities/` and are
named `<race><gender><class><personality>.lua`.

## External resources — symlinked in, NOT our code (all git-ignored)

These are symlinks to shared homes beside the repo (managed by
`install-wow-ui-test-suite.py`). Never edit, lint, or treat them as our code:

- **`addon_examples/`** — other people's published addons, reference only. Read them to
  see how a Classic-Era pattern is done in the wild; never add Loudmouth code here.
- **`tools/wow-ui-sim`** — the headless UI simulator (separate repo, cargo-built).
- **`tools/wow-ui-source`** — read-only mirror of Blizzard's UI Lua/XML, for API reference.

WoW game data lives outside the repo entirely; `tests/ui-test.sh` locates it itself.

## Working agreement

1. **Never report a file as created without writing it to disk.** Verify with a read/ls
   before claiming completion.
2. **Target is Classic Era (1.15.x).** See gotchas below.
3. **Work inside the project dir — never `/tmp`.** All artifacts, build tooling, and test
   output stay under the repo (git-ignored where appropriate).

## Classic-Era gotchas (these have each bitten us)

- Use `BackdropTemplate`, NOT `UIPanelFrameTemplate` (the latter is missing in Classic).
- `BackdropTemplate` does not guarantee `SetBackdrop` exists on the frame at creation.
  Guard it: `if not f.SetBackdrop and BackdropTemplateMixin then Mixin(f, BackdropTemplateMixin) end`
  then call `SetBackdrop` only `if f.SetBackdrop`. A bare `SetBackdrop` call aborts `InitUI`
  mid-build, leaving the panel frame present but with ZERO children (this was our
  long-standing "empty/grey panel" bug).
- Call `frame:CreateFontString()` — do NOT pass a bogus 3rd arg like `(nil, "FONT")`;
  set the font afterward with `SetFontObject(...)`.
- Init shared tables as `X = X or {}` (e.g. `Loudmouth.Personalities`) so `.toc` load
  order never wipes data populated by an earlier-loading file.
- Detection: `UnitRace`, `UnitClass`, `UnitGender`, `GetRealZoneText`. Auto-detect the
  personality on load and fall back to the first available one — never leave
  `CurrentPersonality` nil (it crashes the UI on concatenation).
