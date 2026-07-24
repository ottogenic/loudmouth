#!/usr/bin/env bash
#
# reset-demo.sh -- return this repo to a clean origin/main.
#
# For re-running a live demo from a fresh start. It wipes ALL local changes:
#   * discards edits to tracked files (fixes "local changes would be overwritten")
#   * deletes NEW untracked files the demo created
#   * fast-forwards to the latest origin/main
#
# SAFE: git-ignored files are never touched -- your WoW install (_classic_era_/,
# Data/), the tools/ builds, addon_examples/, and tests/ui-sim-results/ all stay.
#
# Usage:  ./reset-demo.sh      (or)   bash reset-demo.sh
#
set -euo pipefail

# Always operate on the repo root, even if run from a subdirectory.
cd "$(git rev-parse --show-toplevel)"

echo "-> fetching origin ..."
git fetch --quiet origin

echo "-> switching to main and discarding local changes ..."
git checkout -f -q main
git reset --hard -q origin/main

echo "-> removing untracked files (git-ignored files kept) ..."
git clean -fd

echo
echo "OK -- repo is clean and up to date:"
git --no-pager log -1 --oneline
