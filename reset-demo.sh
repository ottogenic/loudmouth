#!/usr/bin/env bash
#
# reset-demo.sh -- return this repo to a known-good starting state.
#
# By default it resets to the FROZEN demo checkpoint (the `demo/base` tag), NOT to
# whatever main happens to be. That way ongoing project work on main never changes
# what a demo run (or a benchmark run) starts from.
#
# It wipes ALL local changes:
#   * discards edits to tracked files (fixes "local changes would be overwritten")
#   * deletes NEW untracked files the demo created
#
# SAFE: git-ignored files are never touched -- your WoW install (_classic_era_/,
# Data/), the tools/ builds, addon_examples/, and tests/ui-sim-results/ all stay.
#
# Usage:
#   ./reset-demo.sh              reset to the demo checkpoint (detached HEAD)
#   ./reset-demo.sh --main       reset to the latest origin/main instead
#   ./reset-demo.sh --tag NAME   reset to any other tag/ref
#
# Back to normal work afterwards:  git checkout main
#
set -euo pipefail

DEMO_TAG="demo/base"
TARGET="$DEMO_TAG"
MODE="tag"

while [ $# -gt 0 ]; do
  case "$1" in
    --main) TARGET="origin/main"; MODE="branch"; shift ;;
    --tag)  TARGET="${2:?--tag needs a name}"; MODE="tag"; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

# Always operate on the repo root, even if run from a subdirectory.
cd "$(git rev-parse --show-toplevel)"

echo "-> fetching origin (with tags) ..."
# --force: a moved demo/base tag is otherwise silently kept at its OLD commit
git fetch --quiet --force --tags origin

if [ "$MODE" = "tag" ] && ! git rev-parse -q --verify "$TARGET^{commit}" >/dev/null; then
  echo "ERROR: ref '$TARGET' not found. Create it with:" >&2
  echo "  git tag -a $DEMO_TAG <commit> -m 'demo baseline' && git push origin $DEMO_TAG" >&2
  exit 1
fi

echo "-> resetting to $TARGET and discarding local changes ..."
if [ "$MODE" = "branch" ]; then
  git checkout -f -q main
  git reset --hard -q origin/main
else
  git checkout -f -q "$TARGET"      # detached HEAD at the frozen checkpoint
fi

echo "-> removing untracked files (git-ignored files kept) ..."
git clean -fd

echo
echo "OK -- repo is clean at $TARGET:"
git --no-pager log -1 --oneline
if [ "$MODE" = "tag" ]; then
  echo "(detached HEAD -- run 'git checkout main' to get back to normal work)"
fi
