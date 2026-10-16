---
name: keeping-cache-warm
description: Use when a turn is about to end while background runs are still out (executors, long commands, async agents) and one may outlast the prompt-cache TTL — keeps one warm-up timer per session that is re-armed by rewriting a deadline file instead of killing and relaunching, so the coordinator's large context is read back cheaply instead of rewritten when the result lands, without wasted wake-ups.
---

# Keeping the Cache Warm

Your prompt cache lives for one TTL after your last request. A run that outlasts
it means its notification lands on a cold cache and the whole context is written
again — about 1.25× its input price on a 5-minute TTL, 2× on a 1-hour TTL. A turn
inside the TTL reads it back at about 0.1× and restarts the clock.

What the wait must satisfy: **when a run may outlast the TTL, the result arrives
either on a warm cache or on a context small enough that reloading it is cheap.**

The TTL is a fact of the user's setup (plan, API key, harness), not a guess: read
it from the working agreement; if it is not there, ask once and record it.

## One timer per session, never one per run

The TTL counts from your last turn, whatever woke it — a short task's
notification, an acceptance, a dispatch. So at the end of every turn with runs
still out, the session has **exactly one** timer, due a few minutes before *this
turn's* TTL runs out. A turn something else woke has already warmed the cache; the
timer fires only when nothing else came inside the TTL.

**Re-arming must not wake you.** In Claude Code every background process that
exits — killed included — wakes the coordinator. Replacing a timer by killing the
old one therefore costs a turn of its own. Re-arm by moving the deadline, not by
replacing the process: [scripts/keep_warm.py](scripts/keep_warm.py) splits the
timer into a deadline file and one waiter process per session.

| When | Command | How |
|------|---------|-----|
| End of every turn with runs out | `python3 <this skill dir>/scripts/keep_warm.py set <scratchpad> <seconds>` | Foreground. `<seconds>` = TTL minus a few minutes (3300 for 1 hour, 240 for 5 minutes). Prints `WAITER_RUNNING` or `START_WAITER`. |
| Only after `START_WAITER` | `python3 <this skill dir>/scripts/keep_warm.py wait <scratchpad>` | Background (`run_in_background`), in the same turn. Exits at the deadline with `KEEP_WARM_DUE`; that exit is the wake-up. |
| Stopping the session's waiting | `python3 <this skill dir>/scripts/keep_warm.py stop <scratchpad>` | Foreground. The waiter exits within 30 s; that exit wakes you once more — arm nothing on it. |

`<scratchpad>` is the session's own scratch directory, so each session has its own
timer. On a harness where a process's exit does not wake you, use whatever timer
it offers instead — the rule is the same: one per session, moved, not replaced.

## The warm-up turn

Woken by `KEEP_WARM_DUE`: one short line ("still waiting") and `set` again (it
prints `START_WAITER`, so launch `wait` again). No file reads, no log checks,
nothing that grows the context. This is not polling: the wake is for the cache,
not to ask whether a run is done.

## When warming stops paying

Warm-up turns pay while there are fewer of them in a row than the cost of one
rewrite — roughly under 20 on a 1-hour TTL, under 12 on 5 minutes. Past that, stop
re-arming (`stop`) and let the result reload the context once; or, before a wait
you know will be long, write the state to the pointer and shrink the context
first (`pointer-handoff`), so the reload is cheap.

## Ending the session

A session that hands over or stops leaves no timer behind: `stop`, answer the
waiter's last wake-up with nothing, and arm nothing after it (`pointer-handoff`,
*Opening the next session yourself*). Other timers — a `Monitor`, a cron, a
background `sleep` — are stopped with `TaskStop` or `CronDelete` the same way.

## Red Flags

| Thought | Reality |
|---------|---------|
| "It'll take hours, the cache will just reload when it's back" | That reload costs 1.25–2× the whole context. Keep one timer due before the TTL from your last turn. |
| "New turn, so kill the old timer and start a fresh one" | The kill wakes you for nothing. `set` moves the deadline; the waiter keeps running. |
| "One timer per run, to be safe" | The TTL is the session's. Two timers mean two wake-ups for one cache. |
| "Woken by the timer — let me check how the runs are doing" | The warm-up turn is one line and a re-arm. Checking grows the context the timer exists to protect. |
