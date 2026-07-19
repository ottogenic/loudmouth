---
name: personality-creator-project
description: Author or edit a Loudmouth personality file under Interface/AddOns/Loudmouth/Personalities/. Use whenever adding a new race/gender/class/personality voice or editing existing dialogue lines, action weights, pet lines, or zone triggers.
---

# Skill: Loudmouth personality creator

A personality is a single drop-in Lua file. Adding a character = adding one file. No
core code changes are required — `Loudmouth.lua` loads whatever is registered in the
`Loudmouth.Personalities` table (and the `.toc`).

## File location & naming (invariant)

- Path: `Interface/AddOns/Loudmouth/Personalities/`
- Name: `<Race><Gender><Class><Personality>.lua` (PascalCase, no spaces), e.g.
  `DwarfFemaleHunterQuirky.lua`, `HumanFemaleWarlockProfessional.lua`.
- The table key inside the file MUST exactly match the filename (minus `.lua`).

## Required file skeleton

Every file starts with these two guard lines so `.toc` load order never wipes data:

```lua
Loudmouth = Loudmouth or {}
Loudmouth.Personalities = Loudmouth.Personalities or {}

Loudmouth.Personalities["<Race><Gender><Class><Personality>"] = {
    actions = {
        ["Spell Name"] = {
            weight = 1/100,           -- probability per macro press (see weights below)
            lines = { "…", "…", "…" } -- 3+ lines, in-character, short
        },
        -- pets are actions too, keyed by pet name:
        ["Imp"]     = { weight = 1, lines = { "…" } },
        ["Generic"] = { weight = 1, lines = { "…" } }, -- REQUIRED fallback
    },
    zones = {
        ["Zone Name"] = { lines = { "…", "…" } }, -- from GetRealZoneText()
    },
}
```

## Authoring rules

1. **Match spell/pet/zone keys to the game exactly.** Action keys must match the spell
   name used in the macro's `/cast`; zone keys must match `GetRealZoneText()`.
2. **Always include a `["Generic"]` action** (weight `1`) as a catch-all voice.
3. **Weights encode frequency** (chance per press):
   - Spammy filler (Auto Shot, Sinister Strike): `1/300`
   - Normal rotational spells: `1/100` to `1/50`
   - Signature / rare cooldowns (Lay on Hands): up to `1`
   - Pets: `1` (summoning is infrequent and characterful)
4. **Lines are short, in-character, and varied.** 3+ per bucket; no duplicates; fit a
   `/say` line. Keep the voice consistent with the personality archetype across all
   buckets (a Professional Warlock never sounds Quirky).
5. **Pet coverage.** Add a bucket per pet the class uses (Hunter: gorilla, cat, bat, …;
   Warlock: imp, voidwalker, …). Long-term goal is all pet types per class.
6. **No API calls in personality files** — they are pure data tables only.

## Wiring a new file in

Add the new file to `Loudmouth.toc` **before** `Loudmouth.lua` (data must load before
the engine). Personality files load in any order relative to each other.

## Definition of done

- File written to disk at the correct path with the matching table key.
- `["Generic"]` bucket present; every bucket has 3+ lines.
- Added to `Loudmouth.toc` before `Loudmouth.lua`.
- `luacheck .` is clean.
