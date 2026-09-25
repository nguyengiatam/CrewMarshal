#!/usr/bin/env python3
"""PreToolUse(Edit|Write|MultiEdit|NotebookEdit): remind a lane coordinator that
shared project documents belong to the Chief.

On a multi-lane project (multi-lane-coordination) a lane works on branch
`lane/<name>` and never edits `docs/superpowers/` — the Chief owns it and lanes
receive changes by merging `main`. An edit there is not refused; it only gets one
reminder alongside the tool call. Inert on any other branch. Fails open.
"""
import json
import os
import subprocess
import sys

LANE_BRANCH_PREFIX = "lane/"
CHIEF_OWNED_DIR = "docs/superpowers/"


def git(cwd, *args):
    return subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, check=True
    ).stdout.strip()


def main():
    event = json.load(sys.stdin)
    tool_input = event.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if not path:
        return
    cwd = event.get("cwd") or os.getcwd()
    path = os.path.realpath(os.path.join(cwd, path))
    root = os.path.realpath(git(cwd, "rev-parse", "--show-toplevel"))
    rel = os.path.relpath(path, root)
    if not rel.startswith(CHIEF_OWNED_DIR):
        return
    branch = git(root, "rev-parse", "--abbrev-ref", "HEAD")
    if not branch.startswith(LANE_BRANCH_PREFIX):
        return
    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": (
                "CrewMarshal: you are on %s and %s belongs to the Chief "
                "(multi-lane-coordination). A lane does not edit shared project "
                "documents — write the change you need to your outbox as an "
                "escalation and the Chief will publish it on main." % (branch, rel)
            ),
        }
    }, sys.stdout)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
