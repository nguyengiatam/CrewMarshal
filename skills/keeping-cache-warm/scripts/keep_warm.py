#!/usr/bin/env python3
"""One warm-up timer per session, re-armed by rewriting a deadline file.

Any background process that exits — killed included — wakes the coordinator, so
replacing a timer by killing it costs a wasted turn. Here the timer is split in
two: a deadline file the coordinator rewrites at the end of every turn, and one
waiter process per session that sleeps until that deadline and then exits (its
exit is the wake-up).

    keep_warm.py set  <dir> [seconds=3300]  foreground, end of every turn with runs out:
                                            deadline = now + seconds. Prints WAITER_RUNNING
                                            if the waiter is alive, else START_WAITER.
    keep_warm.py wait <dir>                 background, only after START_WAITER: exits at
                                            the deadline, printing KEEP_WARM_DUE.
    keep_warm.py stop <dir>                 removes the deadline: the waiter exits within
                                            one check, and that exit is the last wake-up.

<dir> is per session (the session's scratchpad), so each session has its own timer.
"""
import os
import sys
import time

CHECK_SECONDS = 30
DEFAULT_SECONDS = 3300
DEADLINE_FILE = "keep-warm.deadline"
PID_FILE = "keep-warm.pid"


def read_int(path):
    try:
        with open(path) as f:
            return int(f.read().strip())
    except (OSError, ValueError):
        return None


def alive(pid):
    if pid is None:
        return False
    try:
        os.kill(pid, 0)
        return True
    except PermissionError:
        return True
    except OSError:
        return False


def clock(epoch):
    return time.strftime("%H:%M", time.localtime(epoch))


def main():
    cmd, folder = sys.argv[1], sys.argv[2]
    deadline_path = os.path.join(folder, DEADLINE_FILE)
    pid_path = os.path.join(folder, PID_FILE)
    if cmd == "set":
        seconds = int(sys.argv[3]) if len(sys.argv) > 3 else DEFAULT_SECONDS
        due = int(time.time()) + seconds
        os.makedirs(folder, exist_ok=True)
        with open(deadline_path, "w") as f:
            f.write(str(due))
        state = "WAITER_RUNNING" if alive(read_int(pid_path)) else "START_WAITER"
        print("%s due %s" % (state, clock(due)))
    elif cmd == "wait":
        with open(pid_path, "w") as f:
            f.write(str(os.getpid()))
        while True:
            due = read_int(deadline_path)
            if due is None or time.time() >= due:
                break
            time.sleep(CHECK_SECONDS)
        for path in (pid_path, deadline_path):
            try:
                os.remove(path)
            except OSError:
                pass
        if due is None:
            print("KEEP_WARM_STOPPED %s - arm nothing" % clock(time.time()))
        else:
            print("KEEP_WARM_DUE %s - one line, re-arm, read nothing" % clock(time.time()))
    elif cmd == "stop":
        try:
            os.remove(deadline_path)
        except OSError:
            pass
        print("STOPPING - the waiter exits within %ds; that wake-up arms nothing" % CHECK_SECONDS)
    else:
        sys.exit("usage: keep_warm.py set|wait|stop <dir> [seconds]")


if __name__ == "__main__":
    main()
