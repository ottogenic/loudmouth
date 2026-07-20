---
name: agent-test-project
description: Loudmouth's test + lint bar for agent-test. Load when running verification for the Loudmouth addon — headless UI rendering via wow-ui-sim (./tests/ui-test.sh), luacheck linting, and reporting PASS/FAIL back to the lead. This is the canonical "how do I test Loudmouth" reference.
---

# Testing Loudmouth (agent-test)

You own verification for this repo. Two gates: **lint** and **headless UI render**.
Run both, report `PASS`/`FAIL` with the failing slice — never hand the human raw
commands to run themselves.

## 1. Lint
- Run `luacheck .` from the repo root. `.luacheckrc` scopes it to
  `Interface/AddOns/Loudmouth/` — do NOT lint `tools/` (the vendored wow-ui-sim
  build is git-ignored and full of Blizzard/vendor warnings).
- Bar: **0 warnings / 0 errors**. New WoW globals go in `.luacheckrc`, not inline
  ignores.

## 2. Headless UI render (`./tests/ui-test.sh`)
- This is the ONLY sanctioned way to smoke-test the config panel — do NOT ask the
  human to launch WoW. The harness runs `lua-errors`, `dump-tree`, and `screenshot`
  via the local wow-ui-sim build and writes to `tests/ui-sim-results/` (git-ignored).
- A run is `PASS` only when: zero Loudmouth Lua errors, the `LoudmouthConfigFrame`
  subtree has its children (≥4 rendered elements), and `loudmouth-panel.png` is
  produced. The script's final `RESULT:` line is authoritative.
- If it fails, quote the `[1/3]`/`[2/3]`/`[3/3]` block that failed plus the relevant
  error line. An **empty panel with no children** almost always means `InitUI()`
  crashed mid-build — check the `lua-errors` output first (see AGENTS.md Classic-Era
  gotchas, esp. the `SetBackdrop` guard).

## Environment (already baked into the harness — do not re-derive)
The script sets these; know them so you can debug when it breaks:
- `VK_ICD_FILENAMES=…/lvp_icd.json` — software Vulkan (lavapipe). This box has no
  working hardware Vulkan; without it screenshots die with `VK_ERROR_INCOMPATIBLE_DRIVER`.
- `WOW_SIM_LOAD_OUT_OF_DATE_ADDONS=1` — or the addon is silently dropped.
- `WOW_SIM_ADDONS_PATH=Interface/AddOns` — pins loading to OUR repo copy. If edits seem
  to have no effect, a stale copy under `tools/wow-ui-sim/Interface/AddOns/Loudmouth/`
  is shadowing the repo — delete it.
- Screenshot output paths must be **absolute**; `screenshot` takes `--filter` (not
  `--filter-key`).
- `--exec-lua` is a GLOBAL flag: it must come BEFORE the subcommand
  (`wow-sim --exec-lua '...' dump-tree`), and any file/output path must be ABSOLUTE.

## Interaction (click) tests
Button behaviour is covered by `run-tests Loudmouth` against
`Interface/AddOns/Loudmouth/tests/ui_interaction.lua` — it clicks each button and asserts
the resulting state (toggle, close-hides-panel, etc.). The harness runs this as gate
[4/4]; the pass/fail summary line is written to **stderr** and carries ANSI colour codes
(strip them before matching).

## What the sim CANNOT verify
It renders structure, not aesthetics. Missing textures / wrong colors may show as plain
rectangles. A clean render means "structurally sound," not "pixel-perfect" — flag that
the human still owns the final visual check.

## Reporting contract
Return to the lead: `PASS`/`FAIL`, the lint result, the harness `RESULT:` line, and
(on fail) the smallest failing slice. Open a PR only if the lead explicitly asked.
