#!/usr/bin/env python3
"""Watch a headless lane run's stream-json output and print one line per event
the Chief acts on. Meant as the command of a background monitor.

    watch_lane_run.py <run-output.jsonl> <context-token-threshold> [<pid>]

Prints:
  context <tokens>   once, when the run's context first passes the threshold
  compacted          when the session was compacted
  ended <subtype> turns=<n>   when the run finishes, then exits
  gone               when <pid> is given and exits without a result event, then exits

Reads the file as it grows; tolerates lines that are not JSON (CLI warnings).
"""
import json
import os
import sys
import time

POLL_SECONDS = 5
USAGE_KEYS = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")


def alive(pid):
    if pid is None:
        return True
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        pass
    return True


def events(path, pid=None):
    pos = 0
    buf = ""
    while True:
        running = alive(pid)  # checked before reading, so its last output is read
        if os.path.exists(path):
            with open(path) as f:
                f.seek(pos)
                chunk = f.read()
                pos = f.tell()
            buf += chunk
            *lines, buf = buf.split("\n")
            for line in lines:
                try:
                    yield json.loads(line)
                except ValueError:
                    continue
        if not running:
            return
        time.sleep(POLL_SECONDS)


def main():
    path, threshold = sys.argv[1], int(sys.argv[2])
    pid = int(sys.argv[3]) if len(sys.argv) > 3 else None
    warned = False
    for e in events(path, pid):
        kind = e.get("type")
        if kind == "assistant" and not warned:
            usage = e.get("message", {}).get("usage", {})
            tokens = sum(usage.get(k, 0) for k in USAGE_KEYS)
            if tokens > threshold:
                print("context %d" % tokens, flush=True)
                warned = True
        elif kind == "system" and e.get("subtype") == "compact_boundary":
            print("compacted", flush=True)
        elif kind == "result":
            print("ended %s turns=%s" % (e.get("subtype"), e.get("num_turns")), flush=True)
            return
    print("gone", flush=True)


if __name__ == "__main__":
    main()
