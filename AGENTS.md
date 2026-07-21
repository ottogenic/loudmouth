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

## External directories — present locally, NOT our code (all git-ignored)

These large dirs live in the working tree but are **not part of the Loudmouth addon**.
Never edit them, never lint them, never treat their contents as our implementation.
They exist purely as local tooling/reference and are excluded in `.gitignore`.

- **`_classic_era_/`** — a real **World of Warcraft Classic Era game install** (client
  binaries, `Interface/`, `Fonts/`, CASC `Data/`). Used only as the `WOW_INSTALL_PATH`
  data source so wow-ui-sim can resolve textures/fonts. It is Blizzard's files, not ours.
- **`addon_examples/`** — a library of **other people's published addons** (Details,
  WeakAuras, Plater, Leatrix, WeaponSwingTimer, MavenTweex, etc.) kept for *inspiration*:
  read them to see how a Classic-Era pattern is done in the wild. Our code is NEVER here —
  it lives ONLY under `Interface/AddOns/Loudmouth/`. Do not add a Loudmouth copy here.
- **`tools/`** — local build tooling, two upstream git checkouts (do not commit, do not
  modify):
  - `tools/wow-ui-sim/` — the [Osso/wow-ui-sim](https://github.com/Osso/wow-ui-sim)
    headless UI simulator we build to render/test the panel (see "UI testing" below).
    Note its bundled `Interface/AddOns/` can shadow our addon — see that section's gotchas.
  - `tools/wow-ui-source/` — [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source),
    a read-only mirror of Blizzard's UI Lua/XML. Reference it to confirm real WoW API
    behavior/templates; it is NOT loaded by our addon and must never be linted as ours.

## Working agreement

1. **Never report a file as created without writing it to disk.** Verify with a read/ls
   before claiming completion.
2. **Lint before "done".** Run `luacheck .` from the repo root. Only real bugs and
   warnings should remain (WoW globals are whitelisted in `.luacheckrc`).
3. **Target is Classic Era (1.15.x).** See "Classic-Era gotchas" below.
4. **Validate UI changes headlessly.** Run `./tests/ui-test.sh` before claiming a UI
   change works. See "UI testing (wow-ui-sim)" below. It catches Lua crashes and renders
   a real screenshot so you don't need to launch WoW to smoke-test the config panel.
5. **Work inside the project dir — never `/tmp`.** All artifacts, build tooling, and test
   output stay under the repo (git-ignored where appropriate). Do NOT scatter work into
   `/tmp` or other external dirs.
6. **Run tests yourself; don't hand the user commands.** Execute the lint/harness and
   report PASS/FAIL. Never end a turn by pasting a block of commands for the human to run.

## UI testing (wow-ui-sim)

We render Loudmouth's UI **without** launching WoW using a local build of
[wow-ui-sim](https://github.com/Osso/wow-ui-sim). This is our first line of defense
against broken UI PRs.

**Run it:** `./tests/ui-test.sh` — outputs to `tests/ui-sim-results/` (git-ignored):
- `lua-errors` scan (catches load-time crashes in our code),
- `dump-tree` of `LoudmouthConfigFrame` (proves the panel + children were built),
- `loudmouth-panel.png` — an actual screenshot of the config panel to eyeball.

**One-time local setup** (all git-ignored — the sim and WoW data are NOT committed):
- Clone + build the sim into `tools/wow-ui-sim/` with the Era + GUI features:
  `cargo build --release --bin wow-sim --no-default-features --features "sound,gui,casc,client-era"`
- Drop your Classic-Era WoW data at `_classic_era_/` in the repo root (for CASC textures/fonts).

**Gotchas that cost us hours (do NOT relearn these):**
- **Software Vulkan is mandatory here.** This box (DGX Spark, ARM64) has no working
  hardware Vulkan — freedreno/Turnip aborts on `/dev/dri/renderD128`. The harness forces
  lavapipe via `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`. Without it,
  screenshots fail with `VK_ERROR_INCOMPATIBLE_DRIVER`.
- **`WOW_SIM_LOAD_OUT_OF_DATE_ADDONS=1` is required** — the era binary exact-matches the
  interface version, so our addon is silently dropped without this flag.
- **Point the sim at OUR addon dir** with `WOW_SIM_ADDONS_PATH=Interface/AddOns`. The sim
  also scans a bundled `tools/wow-ui-sim/Interface/AddOns/` — if a stale Loudmouth copy
  lands there it will shadow the repo and your edits will appear to do nothing.
- **Screenshot output paths must be absolute**, and `screenshot` supports `--filter` only
  (not `--filter-key`; that's a `dump-tree`-only flag).
- **What the sim canNOT tell you:** it renders frames/backdrops/buttons but styling gaps
  (missing textures, wrong colors) may render as plain rectangles. A clean `dump-tree` +
  screenshot means "structurally sound," not "pixel-perfect" — humans still verify aesthetics.

**CASC textures (optional, for real backdrop/button pixels):** the sim reads game data
from `<install_root>/Data`. Copy the shared `Data/` folder plus the root `.build.info`
and `.product.db` from a real install into the repo, then symlink:
`ln -sfn $PWD/Data _classic_era_/Data`. Without these, textures render as flat rectangles
(structure is still valid). `tests/ui-test.sh` creates the symlink automatically if
`Data/` is present. `Data/` is git-ignored (multi-GB — never commit).

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

## PR workflow

- The `gh` CLI is authenticated as `ottogenic-bot`. If `git push` returns **403**, use
  `gh` rather than raw git — and do NOT silently proceed as if the PR was created.
- When creating a PR, pass the body via `--body-file` or a single-quoted heredoc.
  NEVER a double-quoted `--body` — backticks and parens get shell-interpreted.
- **Reviewer/Author Collision:** Ensure the bot (`ottogenic-bot`) owns the feature branch
  and PR. If the owner token is used for push/creation, the reviewer cannot formally
  'approve' the PR via `gh` API, though they can still merge.

## Research sources

- Prefer `warcraft.wiki.gg` and `github.com/Gethe/wow-ui-source` for API docs.
- `wowhead.com` returns **403** to bots; `wowpedia.wiki` is defunct. Don't retry them.

## Skill index

- `agent-team-extend` — Loudmouth-specific Team routing: when to architect first vs code directly.
- `agent-architect-extend` — Loudmouth-specific architecture/review scope and Classic-Era checks.
- `agent-code-extend` — Loudmouth-specific coding guardrails for Lua 5.1, UI, macros, and verification.
- `agent-review-extend` — Loudmouth-specific review bar and PR review checks.
- `agent-test-extend` — how agent-test lints + headlessly renders the UI (`./tests/ui-test.sh`).
- `personality-creator-project` — authoring/editing files under `Personalities/`.
