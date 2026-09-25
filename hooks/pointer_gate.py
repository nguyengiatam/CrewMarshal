#!/usr/bin/env python3
"""Stop: ask once for a pointer update when work has moved past it.

Blocks the end of a turn when HEAD is at least COMMITS_BEFORE_NUDGE commits past
the last commit that touched the pointer and the pointer has no pending edit.
Nudges at most once per HEAD, so a turn without new progress is never blocked
again. Only runs in projects that keep the pointer at the default path, and never
in a multi-lane lane session (CREWMARSHAL_LANE set, or a `lane/*` branch). Fails open: any error allows the stop.
"""
import json
import os
import subprocess
import sys

POINTER_PATH = "docs/superpowers/STATUS.md"
COMMITS_BEFORE_NUDGE = 3
STATE_DIR_NAME = "crewmarshal"
STATE_FILE_NAME = "pointer-nudged-head"
LANE_BRANCH_PREFIX = "lane/"
LANE_ENV = "CREWMARSHAL_LANE"


def git(cwd, *args):
    return subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, check=True
    ).stdout.strip()


def main():
    event = json.load(sys.stdin)
    if event.get("stop_hook_active"):
        return
    cwd = event.get("cwd") or os.getcwd()
    if os.environ.get(LANE_ENV):
        return  # a lane run: its pointer lives in the shared state dir
    root = git(cwd, "rev-parse", "--show-toplevel")
    if git(root, "rev-parse", "--abbrev-ref", "HEAD").startswith(LANE_BRANCH_PREFIX):
        return  # a lane worktree opened by hand: same reason
    if not os.path.isfile(os.path.join(root, POINTER_PATH)):
        return
    if git(root, "status", "--porcelain", "--", POINTER_PATH):
        return  # pointer is being edited right now
    pointer_commit = git(root, "log", "-1", "--format=%H", "--", POINTER_PATH)
    if not pointer_commit:
        return
    behind = int(git(root, "rev-list", "--count", pointer_commit + "..HEAD"))
    if behind < COMMITS_BEFORE_NUDGE:
        return
    head = git(root, "rev-parse", "HEAD")
    state_dir = os.path.join(root, git(root, "rev-parse", "--git-common-dir"), STATE_DIR_NAME)
    state_file = os.path.join(state_dir, STATE_FILE_NAME)
    if os.path.isfile(state_file) and open(state_file).read().strip() == head:
        return  # already nudged for this HEAD
    os.makedirs(state_dir, exist_ok=True)
    with open(state_file, "w") as f:
        f.write(head)
    json.dump({
        "decision": "block",
        "reason": (
            "CrewMarshal: HEAD is %d commits past the last update of %s. Per "
            "pointer-handoff, update it now with the current state, evidence (SHA, "
            "test counts) and the next action — or, if nothing it says has changed, "
            "tell the user why and stop. This reminder fires once per HEAD."
            % (behind, POINTER_PATH)
        ),
    }, sys.stdout)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
