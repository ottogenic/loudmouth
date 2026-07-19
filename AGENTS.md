# AGENTS.md — Loudmouth Operating Manual

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
    ├── DwarfFemaleHunterQuirky.lua
    └── HumanFemaleWarlockProfessional.lua
docs/                              <- PRD, CHECKLIST, RESEARCH_NOTES
.luacheckrc                        <- luacheck config (WoW globals whitelisted)
```

**Invariant:** Addon files are under `Interface/AddOns/Loudmouth/`. Do NOT assume repo
root. Personality files are under `Interface/AddOns/Loudmouth/Personalities/` and are
named `<race><gender><class><personality>.lua`.

## Working agreement

1. **Never report a file as created without writing it to disk.** Verify with a read/ls
   before claiming completion.
2. **Lint before "done".** Run `luacheck .` from the repo root. Only real bugs and
   warnings should remain (WoW globals are whitelisted in `.luacheckrc`).
3. **Target is Classic Era (1.15.x).** See "Classic-Era gotchas" below.

## Classic-Era gotchas (these have each bitten us)

- Use `BackdropTemplate`, NOT `UIPanelFrameTemplate` (the latter is missing in Classic).
- Call `frame:CreateFontString()` — do NOT pass a bogus 3rd arg like `(nil, "FONT")`;
  set the font afterward with `SetFontObject(...)`.
- Init shared tables as `X = X or {}` (e.g. `Loudmouth.Personalities`) so `.toc` load
  order never wipes data populated by an earlier-loading file.
- Detection: `UnitRace`, `UnitClass`, `UnitGender`, `GetRealZoneText`. Auto-detect the
  personality on load and fall back to the first available one — never leave
  `CurrentPersonality` nil (it crashes the UI on concatenation).

## PR workflow

- The `gh` CLI is authenticated as `ottogenic-bot`. If `git push` returns **403**, use
  `gh` rather than raw git — and do NOT silently proceed as if the PR was created.
- When creating a PR, pass the body via `--body-file` or a single-quoted heredoc.
  NEVER a double-quoted `--body` — backticks and parens get shell-interpreted.

## Research sources

- Prefer `warcraft.wiki.gg` and `github.com/Gethe/wow-ui-source` for API docs.
- `wowhead.com` returns **403** to bots; `wowpedia.wiki` is defunct. Don't retry them.

## Skill index

- `personality-creator-project` — authoring/editing files under `Personalities/`.
