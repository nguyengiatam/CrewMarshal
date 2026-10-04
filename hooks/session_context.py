#!/usr/bin/env python3
"""SessionStart: load the project's working agreement into context.

Runs on every session start, including after /clear and compaction, so the rules
survive a summarized context. Reads `docs/working-agreement.md` (or
`docs/superpowers/working-agreement.md` in projects set up by earlier versions)
from the project root: CREWMARSHAL_PROJECT_ROOT when a lane run sets it, else the
git top level, else the working directory. Claude Code caps injected context at
10,000 characters and replaces anything longer with a short preview, so a longer
agreement is cut at the last heading that fits and the agent is told to read the
rest from the file. Inert when the file does not exist. Fails open.
"""
import json
import os
import subprocess
import sys

AGREEMENT_PATHS = ("docs/working-agreement.md", "docs/superpowers/working-agreement.md")
ROOT_ENV = "CREWMARSHAL_PROJECT_ROOT"
# Claude Code's cap is 10,000 characters per string; leave room for the framing.
MAX_CHARS = 9500


def project_root(cwd):
    root = os.environ.get(ROOT_ENV)
    if root:
        return root
    try:
        return subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd, capture_output=True, text=True, check=True,
        ).stdout.strip()
    except Exception:
        return cwd


def fit(text):
    """(text that fits, first line number left out or None)."""
    if len(text) <= MAX_CHARS:
        return text, None
    lines = text.splitlines(keepends=True)
    kept, size, cut = 0, 0, 0
    for i, line in enumerate(lines):
        if size + len(line) > MAX_CHARS:
            break
        if line.startswith("#"):
            cut = i  # a cut here keeps every section before it whole
        size += len(line)
        kept = i + 1
    if cut == 0:
        cut = kept  # no heading to cut at: cut at the last whole line
    return "".join(lines[:cut]), cut + 1


def main():
    event = json.load(sys.stdin)
    cwd = event.get("cwd") or os.getcwd()
    root = project_root(cwd)
    found = [p for p in AGREEMENT_PATHS if os.path.isfile(os.path.join(root, p))]
    if not found:
        return
    path = os.path.join(root, found[0])
    with open(path, encoding="utf-8") as f:
        body, rest_from = fit(f.read())
    head = (
        "CrewMarshal: the project's working agreement (%s), loaded at session start. "
        "Lines marked ✓ bind; follow them in this session. If the user changes a rule, "
        "update the file (project-working-agreement).\n\n" % path
    )
    tail = ""
    if rest_from:
        tail = (
            "\n\n[Cut to fit the context limit. Read the rest of %s from line %d "
            "before executing or dispatching work.]" % (path, rest_from)
        )
    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": head + body + tail,
        }
    }, sys.stdout, ensure_ascii=False)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
