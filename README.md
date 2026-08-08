# Loudmouth

A World of Warcraft **Classic Era (Hardcore)** addon that gives your character life
through context-aware, personality-driven banter. Your character comments on their
actions, their pets, and the world around them — turning a silent avatar into a
Loudmouth.

## What it does

- **Personality-driven chat.** Each character speaks in a distinct voice (e.g. a Quirky
  Dwarf Hunter, a Professional Human Warlock) with lines tuned to their race, gender,
  and class.
- **Context awareness.** Lines react to spells cast, pets summoned (gorilla, imp,
  voidwalker, …), and zones entered (first-visit commentary for places like Booty Bay).
- **Tunable frequency.** Spell, zone, and target percentages can be overridden per
  personality, with a global cooldown to prevent chat spam.
- **Quick responses.** Generated `LM_YES`, `LM_NO`, `LM_THANK`, `LM_RUN`, and `LM_RUDE`
  macros rotate through eight responses and automatically use selected-target details.
- **ToS-safe by design.** Chat is triggered by **player-initiated macros** that call an
  addon function, then cast the spell. No gameplay automation.

## How it works

The game blocks addons from auto-casting spells, so Loudmouth rides along with a macro:

```
/run Loudmouth.Trigger("Auto Shot")
/cast Auto Shot
```

`Loudmouth.Trigger()` rolls the probability, respects the global cooldown, picks a line
from the active personality, and sends it to `/say`. The macro then casts the spell.

## Install

Copy the addon folder into your Classic Era AddOns directory:

```
_classic_era_/Interface/AddOns/Loudmouth
```

Enable **Loudmouth** at the character-select AddOns screen, then log in.

## In-game usage

- `/lm` or `/loudmouth` — toggle the config window.
- The window auto-detects your race/class/gender and picks a matching personality.
- **Generate Macros** creates or updates class spell macros plus the five response macros.
- Use the **Spell**, **Zone**, and **Target** pages to adjust individual banter chances.
- **Debug Mode** forces a 100% chat chance so you can audit lines without spamming.

## Development

- Addon code lives under `Interface/AddOns/Loudmouth/` (see `AGENTS.md`).
- Personality files: `Interface/AddOns/Loudmouth/Personalities/<race><gender><class><personality>.lua`.
- Lint with `luacheck .` from the repo root before committing (scoped by `.luacheckrc`
  to our addon; vendored `tools/` and `_classic_era_/` are excluded).
- Smoke-test the UI headlessly with `./tests/ui-test.sh` before pushing UI changes.
- See `docs/` for the PRD, project checklist, and research notes.

### Headless UI test — one-time local setup

`./tests/ui-test.sh` renders the config panel without launching WoW, using a local build
of [wow-ui-sim](https://github.com/Osso/wow-ui-sim). Setup (all git-ignored):

- Clone + build the sim into `tools/wow-ui-sim/` with Era + GUI features:
  `cargo build --release --bin wow-sim --no-default-features --features "sound,gui,casc,client-era"`
- Drop your Classic-Era WoW data at `_classic_era_/` for CASC textures/fonts.
- **Optional, for real pixels:** copy the shared `Data/` folder plus root `.build.info`
  and `.product.db` from a real install into the repo, then
  `ln -sfn $PWD/Data _classic_era_/Data` (the harness symlinks automatically if `Data/`
  is present). Without these, textures render as flat rectangles — structure is still
  valid. `Data/` is multi-GB and git-ignored; never commit it.

On this DGX Spark (ARM64) there is no working hardware Vulkan, so the harness forces
software Vulkan via lavapipe; the environment flags it needs are documented in
`.loom/skills/agent-test-instructions-local.md`.

### Agent instructions

`AGENTS.md` holds what every agent needs (repo layout, external dirs, Classic-Era rules).
Per-role guidance lives in `.loom/skills/agent-<role>-instructions-local.md` and is
injected into each pipeline worker's dispatch packet automatically. An
`agent-<role>-instructions-override.md`, if present, replaces global + local entirely.
