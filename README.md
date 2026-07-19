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
- **Tunable frequency.** Every action has a probability weight — spammy abilities speak
  rarely (e.g. 1/300), signature abilities speak often — plus a global cooldown to
  prevent chat spam.
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
- **Generate Macros** prints ready-to-paste macros for your class spells and utilities.
- **Debug Mode** forces a 100% chat chance so you can audit lines without spamming.

## Development

- Addon code lives under `Interface/AddOns/Loudmouth/` (see `AGENTS.md`).
- Personality files: `Interface/AddOns/Loudmouth/Personalities/<race><gender><class><personality>.lua`.
- Lint with `luacheck .` from the repo root before committing.
- See `docs/` for the PRD, project checklist, and research notes.
