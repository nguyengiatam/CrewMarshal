#!/usr/bin/env python3
"""PreToolUse(Bash): remind the coordinator when it launches an executor in the foreground.

orchestrating-executors requires a real dispatch to run in the background with a
monitor. A foreground launch is not refused — the coordinator may be testing an
executor or pinging its quota — it only gets one reminder alongside the command.
Fails open: any error here lets the command run without a reminder.
"""
import json
import os
import re
import sys

PATTERNS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dispatch-commands.txt")


def load_patterns():
    with open(PATTERNS_FILE, encoding="utf-8") as f:
        lines = [line.strip() for line in f]
    return [re.compile(line) for line in lines if line and not line.startswith("#")]


def main():
    event = json.load(sys.stdin)
    if event.get("tool_name") != "Bash":
        return
    tool_input = event.get("tool_input") or {}
    command = tool_input.get("command") or ""
    if tool_input.get("run_in_background"):
        return
    if not any(p.search(command) for p in load_patterns()):
        return
    reminder = (
        "CrewMarshal: this launches an external executor in the foreground. If it is "
        "a real task dispatch, orchestrating-executors wants it in the background "
        "(run_in_background) with a monitor and the run recorded in the pointer. If "
        "you are testing the executor or checking quota, carry on."
    )
    json.dump({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": reminder,
        }
    }, sys.stdout)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
