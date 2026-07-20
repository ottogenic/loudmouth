#!/usr/bin/env bash
#
# Loudmouth UI validation harness (wow-ui-sim)
# --------------------------------------------
# Runs headless checks against the Loudmouth addon using the local wow-ui-sim
# build, WITHOUT needing to launch World of Warcraft.
#
#   1. lua-errors  -> catches Lua crashes on load
#   2. dump-tree   -> verifies our config panel + children are created
#   3. screenshot  -> renders LoudmouthConfigFrame to a PNG for human review
#
# Usage:  ./tests/ui-test.sh
# Output: tests/ui-sim-results/
#
set -uo pipefail

# --- Paths -------------------------------------------------------------------
REPO="/home/otto/Documents/loudmouth"
WSIM="$REPO/tools/wow-ui-sim/target/release/wow-sim"
ADDONS="$REPO/Interface/AddOns"
RESULTS="$REPO/tests/ui-sim-results"
FRAME="LoudmouthConfigFrame"

mkdir -p "$RESULTS"

# --- Environment -------------------------------------------------------------
# WOW_INSTALL_PATH          : the Classic-Era data placed in the repo root, used
#                             for CASC texture/font resolution.
# VK_ICD_FILENAMES=lavapipe : force the CPU software Vulkan driver. This box has
#                             no working hardware Vulkan (freedreno/Turnip aborts
#                             on /dev/dri/renderD128), so lavapipe is required for
#                             screenshots to render.
# WOW_SIM_LOAD_OUT_OF_DATE_ADDONS : the era binary targets a specific interface
#                             version; this bypasses the exact-match filter so our
#                             addon actually loads.
# WOW_SIM_ADDONS_PATH       : point the sim explicitly at OUR repo addon dir so it
#                             never picks up a stale bundled/cached copy.
export WOW_INSTALL_PATH="$REPO/_classic_era_"
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/lvp_icd.json"
export WOW_SIM_LOAD_OUT_OF_DATE_ADDONS=1
export WOW_SIM_ADDONS_PATH="$ADDONS"

# CASC textures: the sim looks for game data at <install_root>/Data. Our shared
# Data/ lives at the repo root (sibling to _classic_era_), so symlink it in. This
# lets Blizzard textures (dialog backdrop, button faces) extract from CASC.
# Requires .build.info + .product.db copied into _classic_era_/ (see AGENTS.md).
if [ -d "$REPO/Data" ] && [ ! -e "$REPO/_classic_era_/Data" ]; then
    ln -sfn "$REPO/Data" "$REPO/_classic_era_/Data"
fi

fail=0

echo "=============================================="
echo " Loudmouth UI Test  (wow-ui-sim, headless)"
echo "=============================================="

# --- 1. Lua errors -----------------------------------------------------------
echo ""
echo "[1/4] Lua error scan..."
"$WSIM" dump-tree 2>&1 \
  | grep -iE "Loudmouth (UI|CopyChat) Error|Loudmouth.*: .*(nil value|must be a number)" \
  > "$RESULTS/lua-errors.txt"
if [ -s "$RESULTS/lua-errors.txt" ]; then
    echo "  FAIL - Loudmouth Lua errors found:"
    sed 's/^/      /' "$RESULTS/lua-errors.txt"
    fail=1
else
    echo "  PASS - no Loudmouth Lua errors."
fi

# --- 2. Frame tree -----------------------------------------------------------
echo ""
echo "[2/4] Frame-tree check ($FRAME + children)..."
"$WSIM" dump-tree --filter-key "$FRAME" 2>/dev/null \
  | grep -A60 "^$FRAME" > "$RESULTS/dump-tree.txt"
child_count=$(grep -cE "\[(Button|FontString|Texture|Frame)\]" "$RESULTS/dump-tree.txt")
echo "  Found $child_count rendered elements in the panel subtree."
if [ "$child_count" -ge 4 ]; then
    echo "  PASS - panel built with children."
else
    echo "  FAIL - panel is empty or missing children (InitUI likely crashed)."
    fail=1
fi

# --- 3. Screenshot -----------------------------------------------------------
echo ""
echo "[3/4] Rendering screenshot..."
"$WSIM" screenshot \
  -o "$RESULTS/loudmouth-panel.webp" \
  --filter "$FRAME" --width 400 --height 450 2>&1 \
  | grep -iE "QuadBatch|Saved" | sed 's/^/      /'
if [ -f "$RESULTS/loudmouth-panel.webp" ]; then
    # Best-effort PNG conversion for easy viewing
    python3 - "$RESULTS/loudmouth-panel.webp" "$RESULTS/loudmouth-panel.png" 2>/dev/null <<'PY'
import sys
try:
    from PIL import Image
    Image.open(sys.argv[1]).save(sys.argv[2])
except Exception:
    pass
PY
    echo "  PASS - screenshot at tests/ui-sim-results/loudmouth-panel.png"
else
    echo "  FAIL - screenshot not produced."
    fail=1
fi

# --- 4. Interaction tests (button clicks) ------------------------------------
echo ""
echo "[4/4] Interaction tests (button clicks)..."
"$WSIM" run-tests Loudmouth > "$RESULTS/interaction.log" 2>&1
# Strip ANSI colour codes, then read the summary ("N tests, N passed, N failed").
clean=$(sed 's/\x1b\[[0-9;]*m//g' "$RESULTS/interaction.log")
result_line=$(echo "$clean" | grep -oE "[0-9]+ tests, [0-9]+ passed, [0-9]+ failed" | tail -1)
if echo "$result_line" | grep -qE ", 0 failed"; then
    echo "  PASS - $result_line"
else
    echo "  FAIL - ${result_line:-no test result found (see interaction.log)}"
    fail=1
fi

echo ""
echo "=============================================="
if [ "$fail" -eq 0 ]; then
    echo " RESULT: PASS"
else
    echo " RESULT: FAIL (see tests/ui-sim-results/)"
fi
echo "=============================================="
exit "$fail"
