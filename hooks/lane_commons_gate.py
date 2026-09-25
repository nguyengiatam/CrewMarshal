#!/usr/bin/env python3
"""PreToolUse(Edit|Write|MultiEdit|NotebookEdit): remind a lane coordinator that
shared project documents belong to the Chief.

On a multi-lane project (multi-lane-coordination) a lane never edits the
CrewMarshal documents in the project root's `docs/` (or the older
`docs/superpowers/`) — the Chief owns them. A session is a lane
when the Chief launched it with CREWMARSHAL_LANE (and CREWMARSHAL_PROJECT_ROOT, which
may sit outside the repo being edited, in a workspace of several repos), or — for a
lane worktree opened by hand — when its branch is `lane/<name>`. An edit there is
not refused; it only gets one reminder alongside the tool call. Fails open.
"""
import json
import os
import subprocess
import sys

LANE_ENV = "CREWMARSHAL_LANE"
ROOT_ENV = "CREWMARSHAL_PROJECT_ROOT"
LANE_BRANCH_PREFIX = "lane/"
# The Chief's documents under <project root>/docs/, plus the whole of the
# docs/superpowers/ directory earlier versions used.
CHIEF_OWNED = [
    os.path.join("docs", name)
    for name in ("STATUS.md", "system-profile.md", "working-agreement.md", "team.md",
                 "executor-context.md", "lessons", "specs", "plans", "superpowers")
]


def git(cwd, *args):
    return subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, check=True
    ).stdout.strip()


def lane_and_root(cwd):
    """(lane label, project root) when this session is a lane, else None."""
    lane, root = os.environ.get(LANE_ENV), os.environ.get(ROOT_ENV)
    if lane and root:
        return lane, root
    repo = git(cwd, "rev-parse", "--show-toplevel")
    branch = git(repo, "rev-parse", "--abbrev-ref", "HEAD")
    if branch.startswith(LANE_BRANCH_PREFIX):
        return branch, repo
    return None


def main():
    event = json.load(sys.stdin)
    tool_input = event.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if not path:
        return
    cwd = event.get("cwd") or os.getcwd()
    found = lane_and_root(cwd)
    if not found:
        return
    lane, root = found
    root = os.path.realpath(root)
    path = os.path.realpath(os.path.join(cwd, path))
    owned = [os.path.join(root, rel) for rel in CHIEF_OWNED]
    if not any(os.path.commonpath([path, o]) == o for o in owned):
        return
    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": (
                "CrewMarshal: this session is lane %s and %s belongs to the Chief "
                "(multi-lane-coordination). A lane does not edit shared project "
                "documents — write the change you need to your outbox as an "
                "escalation." % (lane, path)
            ),
        }
    }, sys.stdout)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
