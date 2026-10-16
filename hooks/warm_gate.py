#!/usr/bin/env python3
"""Stop: remind once when a turn ends with runs still out and no warm-up timer.

orchestrating-executors wants a session that waits on background runs to keep its
prompt cache warm: at the end of every turn with runs still out, one timer due
before this turn's TTL (or a pointer write and a reset before a long wait). This
reads the session transcript: a run is a background Bash command or an async
agent with no completion notification yet (a <status> in its task-notification,
or a TaskStop); a timer is a ScheduleWakeup, CronCreate or Monitor call, or a
background `sleep N`, made in the current turn. Runs out and no timer this turn
→ holds the end of the turn once with a reminder; stop_hook_active means it
already did, so it never holds twice in a row. Inert in projects without a
working agreement (that is where the TTL lives). Fails open: any error allows
the stop.
"""
import json
import os
import re
import subprocess
import sys

AGREEMENT_PATHS = ("docs/working-agreement.md", "docs/superpowers/working-agreement.md")
ROOT_ENV = "CREWMARSHAL_PROJECT_ROOT"
TIMER_TOOLS = ("ScheduleWakeup", "CronCreate", "Monitor")
SLEEP_ONLY = re.compile(r"^\s*sleep\s+\d+[smh]?\s*$")
FINISHED = re.compile(r"<task-id>([\w-]+)</task-id>(?:(?!</task-notification>).)*?<status>")


def project_root(cwd):
    root = os.environ.get(ROOT_ENV)
    if root:
        return root
    return subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=cwd, capture_output=True, text=True, check=True,
    ).stdout.strip()


def blocks(entry):
    content = (entry.get("message") or {}).get("content")
    return content if isinstance(content, list) else []


def is_turn_start(entry):
    """A user prompt or a task notification — not a tool result or injected meta."""
    if entry.get("type") != "user" or entry.get("isMeta"):
        return False
    return not any(b.get("type") == "tool_result" for b in blocks(entry) if isinstance(b, dict))


def is_timer(name, tool_input):
    if name in TIMER_TOOLS:
        return True
    return (name == "Bash" and tool_input.get("run_in_background")
            and bool(SLEEP_ONLY.match(tool_input.get("command") or "")))


def scan(lines):
    """(run ids still out, whether the current turn armed a timer)."""
    calls = {}  # tool_use id -> (name, input)
    runs = []
    finished = set()
    timer_this_turn = False
    for raw in lines:
        finished.update(FINISHED.findall(raw))
        try:
            entry = json.loads(raw)
        except ValueError:
            continue
        if is_turn_start(entry):
            timer_this_turn = False
        for b in blocks(entry):
            if not isinstance(b, dict):
                continue
            if b.get("type") == "tool_use":
                name, tool_input = b.get("name"), b.get("input") or {}
                calls[b.get("id")] = (name, tool_input)
                if is_timer(name, tool_input):
                    timer_this_turn = True
                if name == "TaskStop" and tool_input.get("task_id"):
                    finished.add(tool_input["task_id"])
            elif b.get("type") == "tool_result":
                name, tool_input = calls.get(b.get("tool_use_id"), (None, {}))
                result = entry.get("toolUseResult")
                if not isinstance(result, dict) or is_timer(name, tool_input):
                    continue
                if result.get("backgroundTaskId"):
                    runs.append(result["backgroundTaskId"])
                elif result.get("isAsync") and result.get("agentId"):
                    runs.append(result["agentId"])
    return [r for r in runs if r not in finished], timer_this_turn


def main():
    event = json.load(sys.stdin)
    if event.get("stop_hook_active"):
        return
    root = project_root(event.get("cwd") or os.getcwd())
    agreements = [p for p in AGREEMENT_PATHS if os.path.isfile(os.path.join(root, p))]
    if not agreements:
        return
    with open(event["transcript_path"], encoding="utf-8") as f:
        out, timer = scan(f)
    if not out or timer:
        return
    json.dump({
        "decision": "block",
        "reason": (
            "CrewMarshal: this turn ends with %d background run(s) still out (%s) and "
            "no warm-up timer armed in it. Per orchestrating-executors, arm one "
            "session-wide timer due a few minutes before the cache TTL in %s counts "
            "out from this turn (replacing any earlier one), or write the state to the "
            "pointer and reset before a long wait. If the runs will finish well inside "
            "the TTL, say so and stop."
            % (len(out), ", ".join(out), agreements[0])
        ),
    }, sys.stdout)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
