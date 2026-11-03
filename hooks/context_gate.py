#!/usr/bin/env python3
"""Stop: remind once when the session's context passes the fresh-session threshold.

pointer-handoff wants a session past the fresh-session threshold the working
agreement sets (300k without one) to look for a clean point, write the
pointer and open or suggest a new session. The context size is the last main-thread
model call's input (uncached + cache read + cache write) in the transcript. The
reminder tells the session to open the next one itself when the agreement says
so (`Tự chuyển phiên: ✓ có`), to suggest one otherwise. The
threshold is the number on the agreement line that names a fresh session
(`chuyển phiên`, `phiên mới`, `fresh session`, `session reset`), e.g. `400k`;
without one, 300k. Holds the end of the turn once when the context first passes
it, and once more for every further STEP tokens, so a session that keeps going
is not held every turn. Inert in projects without a working agreement and when
stop_hook_active is set. Fails open: any error allows the stop.
"""
import json
import os
import re
import subprocess
import sys

AGREEMENT_PATHS = ("docs/working-agreement.md", "docs/superpowers/working-agreement.md")
ROOT_ENV = "CREWMARSHAL_PROJECT_ROOT"
DEFAULT_THRESHOLD = 300_000
STEP = 100_000
THRESHOLD_LINE = re.compile(r"chuyển phiên|phiên mới|fresh session|session reset", re.I)
AUTO_OPEN = re.compile(r"tự chuyển phiên[^✓\n]*✓\s*\**\s*(có|yes)|opens? the next session[^✓\n]*✓", re.I)
TOKENS = re.compile(r"(\d+(?:[.,]\d+)?)\s*([kK])\b")
STATE_DIR_NAME = "crewmarshal"
STATE_FILE_NAME = "context-nudged.json"


def git(cwd, *args):
    return subprocess.run(
        ["git", *args], cwd=cwd, capture_output=True, text=True, check=True
    ).stdout.strip()


def threshold(agreement):
    for line in agreement.splitlines():
        if THRESHOLD_LINE.search(line):
            m = TOKENS.search(line)
            if m:
                return int(float(m.group(1).replace(",", ".")) * 1000)
    return DEFAULT_THRESHOLD


def context_size(lines):
    size = 0
    for raw in lines:
        try:
            entry = json.loads(raw)
        except ValueError:
            continue
        if entry.get("type") != "assistant" or entry.get("isSidechain"):
            continue
        usage = (entry.get("message") or {}).get("usage")
        if isinstance(usage, dict):
            size = sum(usage.get(k) or 0 for k in (
                "input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
    return size


def main():
    event = json.load(sys.stdin)
    if event.get("stop_hook_active"):
        return
    cwd = event.get("cwd") or os.getcwd()
    root = os.environ.get(ROOT_ENV) or git(cwd, "rev-parse", "--show-toplevel")
    agreements = [p for p in AGREEMENT_PATHS if os.path.isfile(os.path.join(root, p))]
    if not agreements:
        return
    with open(os.path.join(root, agreements[0]), encoding="utf-8") as f:
        agreement = f.read()
    limit = threshold(agreement)
    auto_open = any(AUTO_OPEN.search(line) for line in agreement.splitlines())
    with open(event["transcript_path"], encoding="utf-8") as f:
        size = context_size(f)
    if size < limit:
        return
    step = (size - limit) // STEP
    session = event.get("session_id") or event["transcript_path"]
    state_dir = os.path.join(root, git(root, "rev-parse", "--git-common-dir"), STATE_DIR_NAME)
    state_file = os.path.join(state_dir, STATE_FILE_NAME)
    state = {}
    if os.path.isfile(state_file):
        with open(state_file) as f:
            state = json.load(f)
    if session in state and state[session] >= step:
        return  # already nudged at this size
    os.makedirs(state_dir, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump({session: step}, f)  # only the current session matters
    if auto_open:
        how = (
            "The agreement says you open the next session yourself (Tự chuyển phiên): "
            "at that point write the pointer and open it — do not ask the user to open "
            "it. Jobs still running are a reason to drain, not to hand over: keep the "
            "waiters and warm-up timers, accept each job as it lands, start no new "
            "task; the turn that commits the last job writes the pointer, opens the "
            "next session, then cancels every warm-up timer and arms nothing."
        )
    else:
        how = (
            "At that point write the pointer and suggest a new session to the user; "
            "the first time, ask whether you may open it yourself and record the "
            "answer in the agreement. Until then, if jobs are still running, accept "
            "them as they land and start no new task."
        )
    json.dump({
        "decision": "block",
        "reason": (
            "CrewMarshal: this session's context is about %dk tokens, past the %dk "
            "fresh-session threshold (%s). Per pointer-handoff, hand over at a clean "
            "point: next action concrete, nothing half-investigated held only in "
            "context, last task accepted and committed, nothing running or waiting. "
            "If this is not that point yet, say what is still open and carry on "
            "toward it. %s"
            % (size // 1000, limit // 1000, agreements[0], how)
        ),
    }, sys.stdout)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
