# Testing Loudmouth (agent-test)

You own verification for this repo. Two gates: **lint** and **headless UI render**.
Run both and surface the outcome (with the failing slice on fail) -- never hand the human
raw commands to run themselves.

## 1. Lint
- Run `luacheck .` from the repo root. `.luacheckrc` scopes it to
  `Interface/AddOns/Loudmouth/` -- do NOT lint `tools/` (the vendored wow-ui-sim
  build is git-ignored and full of Blizzard/vendor warnings).
- Bar: **0 warnings / 0 errors**. New WoW globals go in `.luacheckrc`, not inline
  ignores.

## 2. Headless UI render (`./tests/ui-test.sh`)
- This is the ONLY sanctioned way to smoke-test the config panel -- do NOT ask the
  human to launch WoW. The harness runs `lua-errors`, `dump-tree`, and `screenshot`
  via the local wow-ui-sim build and writes to `tests/ui-sim-results/` (git-ignored).
- A run is `PASS` only when: zero Loudmouth Lua errors, the `LoudmouthConfigFrame`
  subtree has its children (>=4 rendered elements), and `loudmouth-panel.png` is
  produced. The script's final `RESULT:` line is authoritative.
- If it fails, quote the `[1/4]`/`[2/4]`/`[3/4]`/`[4/4]` block that failed plus the
  relevant error line. An empty panel with no children almost always means `InitUI()`
  crashed mid-build -- check the `lua-errors` output first.

## Environment (already baked into the harness -- do not re-derive)
- `VK_ICD_FILENAMES=.../lvp_icd.json` -- software Vulkan (lavapipe).
- `WOW_SIM_LOAD_OUT_OF_DATE_ADDONS=1` -- or the addon is silently dropped.
- `WOW_SIM_ADDONS_PATH=Interface/AddOns` -- pins loading to OUR repo copy.
- Screenshot output paths must be absolute; `screenshot` takes `--filter`.
- `--exec-lua` is a global flag: it must come BEFORE the subcommand.

## Interaction (click) tests
Button behaviour is covered by `run-tests Loudmouth` against
`Interface/AddOns/Loudmouth/tests/ui_interaction.lua`. The harness runs this as gate
[4/4]; the pass/fail summary line is written to stderr and may contain ANSI colour codes.

## What the sim CANNOT verify
It renders structure, not aesthetics. A clean render means "structurally sound," not
"pixel-perfect" -- flag that the human still owns the final visual check.

## Evidence to include
In your **EVIDENCE**, quote the exact `luacheck` summary and the `ui-test.sh` `RESULT:`
line -- and, on fail, the smallest failing slice.

## What the harness proves (and what it cannot)

`./tests/ui-test.sh` is our first line of defense against broken UI changes: it scans
for load-time Lua errors, dumps the `LoudmouthConfigFrame` tree to prove the panel and
its children were built, and writes `loudmouth-panel.png` to eyeball. Without CASC game
data present, textures render as flat rectangles -- structure is still valid. A clean
run means "structurally sound", never "pixel-perfect"; the human owns the visual check.

If the sim itself is missing or unbuilt, that is a local setup task for the human (see
README), not something to work around by editing `tools/`.
