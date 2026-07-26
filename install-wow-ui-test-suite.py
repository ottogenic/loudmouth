#!/usr/bin/env python3
"""Set up (or refresh) the WoW UI test suite for this repo.

Canonical homes live BESIDE the repo (../), so the sim, the UI-source mirror,
and the game data each update independently while every checkout -- the main
repo and any git worktree -- just symlinks to them. Agents keep permission-free
access because the symlinks live inside the project.

    wow-ui-sim/        https://github.com/Osso/wow-ui-sim      (built with cargo)
    wow-ui-source/     https://github.com/Gethe/wow-ui-source  (read-only mirror)
    wow-classic-data/  your WoW Classic Era install copy       (never in git)

Usage:
    ./install-wow-ui-test-suite.py --data /path/to/wow-install   # first run
    ./install-wow-ui-test-suite.py                               # refresh (pull + relink)
    ./install-wow-ui-test-suite.py --target /path/to/worktree    # link-only, for worktrees
    ./install-wow-ui-test-suite.py --build                       # force a sim rebuild
    ./install-wow-ui-test-suite.py --verify                      # run tests/ui-test.sh after

First run migrates any real tools/wow-ui-sim, tools/wow-ui-source, or
_classic_era_ directories out to the canonical homes (a same-filesystem move,
so instant and reversible), then replaces them with symlinks. The data path is
remembered in ../.wow-ui-suite.json so later runs never need --data again.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

REPOS = {
    "wow-ui-sim": "https://github.com/Osso/wow-ui-sim.git",
    "wow-ui-source": "https://github.com/Gethe/wow-ui-source.git",
}
# "sound" needs ALSA dev headers; build falls back without it (headless tests
# never play audio anyway).
FEATURE_SETS = ["sound,gui,casc,client-era", "gui,casc,client-era"]
PATCHES_DIR = "tools-patches"  # local patches applied to the sim after every pull


def run(cmd, cwd=None, check=True):
    print(f"  $ {' '.join(cmd)}" + (f"   (in {cwd})" if cwd else ""))
    return subprocess.run(cmd, cwd=cwd, check=check)


def rev(path):
    try:
        out = subprocess.run(["git", "-C", str(path), "rev-parse", "--short", "HEAD"],
                             capture_output=True, text=True, check=True)
        return out.stdout.strip()
    except (subprocess.CalledProcessError, OSError):
        return "?"


def ensure_symlink(link, target):
    """Make `link` a symlink to `target`, migrating a real dir out of the way."""
    if os.path.islink(link):
        if os.path.realpath(link) == os.path.realpath(target):
            print(f"  ok      {link} -> {target}")
            return
        os.unlink(link)
    elif os.path.isdir(link):
        if os.path.exists(target):
            bak = link + ".pre-suite-bak"
            print(f"  MOVED   existing {link} -> {bak} (canonical already exists)")
            os.rename(link, bak)
        else:
            print(f"  MIGRATE {link} -> {target}")
            shutil.move(link, target)
    os.makedirs(os.path.dirname(link), exist_ok=True)
    os.symlink(target, link)
    print(f"  link    {link} -> {target}")


def apply_patches(repo_root, sim_dir):
    """Re-apply local patches (e.g. WOW_SIM_ADDONS_PATH support in run-tests)
    after a pull. Idempotent: skips patches whose marker is already present."""
    pdir = os.path.join(repo_root, PATCHES_DIR)
    if not os.path.isdir(pdir):
        return
    marker = "WOW_SIM_ADDONS_PATH wins when set"
    target = os.path.join(sim_dir, "src", "addon_tests.rs")
    if os.path.exists(target) and marker in open(target, encoding="utf-8").read():
        print("  patch: already applied")
        return
    for p in sorted(os.listdir(pdir)):
        if p.endswith(".patch"):
            r = subprocess.run(["git", "-C", sim_dir, "apply", os.path.join(pdir, p)])
            print(f"  patch {p}: {'applied' if r.returncode == 0 else 'FAILED -- resolve by hand'}")


def build_sim(sim_dir):
    env = dict(os.environ)
    env["PATH"] = os.path.expanduser("~/.cargo/bin") + os.pathsep + env.get("PATH", "")
    for feats in FEATURE_SETS:
        cmd = ["cargo", "build", "--release", "--bin", "wow-sim",
               "--no-default-features", "--features", feats]
        print(f"  $ {' '.join(cmd)}")
        if subprocess.run(cmd, cwd=sim_dir, env=env).returncode == 0:
            return True
        print(f"  build with '{feats}' failed; trying reduced feature set")
    return False


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", help="path to your WoW Classic Era install copy "
                                   "(required on first run; remembered afterwards)")
    ap.add_argument("--target", help="checkout to provision (default: this repo); "
                                     "link-only mode -- no clone/pull/build")
    ap.add_argument("--build", action="store_true", help="force cargo rebuild of the sim")
    ap.add_argument("--verify", action="store_true", help="run tests/ui-test.sh at the end")
    ap.add_argument("--no-pull", action="store_true", help="skip git pull on existing repos")
    args = ap.parse_args()

    repo_root = os.path.dirname(os.path.abspath(__file__))
    parent = os.path.dirname(repo_root)
    state_file = os.path.join(parent, ".wow-ui-suite.json")
    state = {}
    if os.path.exists(state_file):
        with open(state_file, encoding="utf-8") as f:
            state = json.load(f)

    target_root = os.path.abspath(args.target) if args.target else repo_root
    link_only = bool(args.target)

    # --- canonical repos: clone, migrate, or pull -----------------------------
    if not link_only:
        for name, url in REPOS.items():
            canon = os.path.join(parent, name)
            in_repo = os.path.join(repo_root, "tools", name)
            if not os.path.exists(canon):
                if os.path.isdir(in_repo) and not os.path.islink(in_repo):
                    pass  # ensure_symlink migrates it below
                else:
                    print(f"clone {name} ({url})")
                    run(["git", "clone", url, canon])
            elif not args.no_pull:
                before = rev(canon)
                run(["git", "-C", canon, "pull", "--ff-only"], check=False)
                print(f"  {name}: {before} -> {rev(canon)}")
        if name == "wow-ui-sim" and os.path.exists(canon):
            apply_patches(repo_root, canon)

    # --- game data ------------------------------------------------------------
    data = args.data or state.get("data")
    default_data = os.path.join(parent, "wow-classic-data")
    in_repo_era = os.path.join(repo_root, "_classic_era_")
    if not data:
        if os.path.isdir(in_repo_era) and not os.path.islink(in_repo_era):
            data = default_data  # migrate the in-repo copy to the canonical home
        elif os.path.isdir(default_data):
            data = default_data
        else:
            sys.exit("ERROR: no game data known. First run needs "
                     "--data /path/to/your/wow-install-copy")
    data = os.path.abspath(os.path.expanduser(data))

    # --- symlinks into the target checkout ------------------------------------
    print(f"provisioning {target_root}")
    for name in REPOS:
        ensure_symlink(os.path.join(target_root, "tools", name),
                       os.path.join(parent, name))
    ensure_symlink(os.path.join(target_root, "_classic_era_"), data)
    # optional shared Data dir at repo root (README's CASC texture setup)
    in_repo_data = os.path.join(repo_root, "Data")
    canon_data_sub = os.path.join(data, "Data")
    if os.path.isdir(in_repo_data) and not os.path.islink(in_repo_data) \
            and not os.path.exists(canon_data_sub):
        print(f"  MIGRATE {in_repo_data} -> {canon_data_sub}")
        shutil.move(in_repo_data, canon_data_sub)
    # No repo-root Data symlink: everything reads it via _classic_era_/Data.
    # Clean up one if an older installer version created it.
    stale = os.path.join(target_root, "Data")
    if os.path.islink(stale):
        os.unlink(stale)
        print(f"  removed redundant symlink {stale}")

    if not os.path.exists(os.path.join(data, ".build.info")):
        print(f"  WARNING: {data} has no .build.info -- textures may not render")

    # --- remember the data path ----------------------------------------------
    if state.get("data") != data:
        state["data"] = data
        with open(state_file, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
        print(f"  data path saved to {state_file}")

    # --- build the sim if needed ----------------------------------------------
    sim_bin = os.path.join(parent, "wow-ui-sim", "target", "release", "wow-sim")
    if not link_only and (args.build or not os.path.exists(sim_bin)):
        print("building wow-sim (cargo, first build takes a while)")
        if not build_sim(os.path.join(parent, "wow-ui-sim")):
            sys.exit("ERROR: sim build failed with every feature set")
    print(f"  sim: {sim_bin} ({'present' if os.path.exists(sim_bin) else 'MISSING'})"
          f"  [{rev(os.path.join(parent, 'wow-ui-sim'))}]")

    # --- verify ---------------------------------------------------------------
    if args.verify:
        print("verifying with tests/ui-test.sh")
        r = run(["bash", os.path.join(target_root, "tests", "ui-test.sh")], check=False)
        sys.exit(r.returncode)
    print("done.")


if __name__ == "__main__":
    main()
