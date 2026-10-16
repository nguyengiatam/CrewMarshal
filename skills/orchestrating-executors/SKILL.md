---
name: orchestrating-executors
description: Use when a plan is ready and implementation will be delegated to external coding agents or subagents — covers role separation, one-task checkpoints, asynchronous dispatch with a monitor on every run (no polling), feeding a freed agent the next ready task in the same turn, parallel-run isolation, and the per-task checkpoint protocol; who does each task is managing-workforce, the prompt itself is writing-handoffs.
---

# Orchestrating External Executors

You are the architect and reviewer. External coding agents (the "executors")
implement the plan one task at a time; you gate every task before the next begins.

This covers executors that are **separate tools with their own quotas, quirks, and
failure modes** — as opposed to subagents inside your own harness (on Claude Code,
`superpowers:subagent-driven-development` covers those). `managing-workforce`
covers choosing between the two. Exact invocations live in
[references/executor-roster.md](references/executor-roster.md) — read it before
dispatching. Keep this skill's body agent-agnostic; all machine-specific commands
stay in the roster.

## Roles

Four roles. One agent may hold several — with one exception that is never
negotiable.

| Role | Does | Notes |
|------|------|-------|
| **Coordinator** (you) | Splits work, dispatches, monitors, verifies, decides | Never delegate this |
| **Plan author** | Turns a short spec into a task-by-task plan with real code | Often worth delegating: plans are long to write and cheap to review |
| **Executor** | Implements exactly one task, then stops | May be several in parallel |
| **Adversarial reviewer** | Stress-tests the result — see `adversarial-review-to-go` | Prefer a different agent than the one that wrote the code |

**The non-negotiable: whoever writes the code does not get to certify it.** An
executor that writes both the function and its tests has proven only that the code
matches itself. When accepting such work, compute the expected numbers yourself
from the fixtures and check the output against *those* — not against the
executor's assertions. This is what makes it safe to delegate even business
logic: the rigor moves to verification instead of staying in authorship.

You may write code yourself for foundation, concurrency-critical, or verification
code where precision beats delegation. Also for **purely mechanical work already
spelled out in the plan** — arguing with a weak executor costs more than typing it.

## Choosing and Keeping the Team

Who gets each task, the project's team file, first-time confirmation before a new
source of labor, pausing a failed agent, and quota: `managing-workforce`. At
dispatch you only confirm the plan's assignment still holds.

## Dispatching One Task

A **checkpoint** is the reviewable unit: **one plan task → one commit on a feature
branch → executor stops → you review.** Enforce all of:

1. One task per handoff. The prompt names the single task, the current HEAD, the
   baseline test state, and this repo's safety rules.
2. The executor commits its own work (or stops without committing, if that's your
   convention) and halts.
3. You review before releasing the next task: `checkpoint-verification`, then
   `convention-commit-gate`, on the actual diff — never on the executor's summary.
4. Verification output is real and seen. "Tests pass" without the run output is
   not acceptance — but quote the lines that decide it and point at the log for
   the rest; a pasted full log costs context on every later turn.

If an executor violated the protocol (ran ahead, skipped verification, edited
another repo), stop and reconcile before continuing — do not paper over it.

Write the prompt itself by `writing-handoffs`: it stands on its own, says what to
achieve rather than how, and points at the executor context file.

## Dispatching Asynchronously

**Every dispatch to an external executor runs in the background with a monitor
attached at the moment of launch — and then you go do something else.** The
monitor waits and reports; you decide, verify, and accept. Waiting is the
monitor's job, not yours.

### A dispatch is complete only with evidence of all three

1. **The executor actually started** — the signal the roster lists for that agent
   (a session file, a running job, a first log line). A launched command is not a
   started executor.
2. **The monitor is running** and its notification comes back **to this session,
   for this run** — not "I'll keep an eye on it", not a PID written down.
3. **The run is recorded:** task, executor, run id, BASE commit, where the result
   and log will be. Write it to the pointer now (see `pointer-handoff`) — the
   session may end before the result arrives.

Until all three hold, the task is *dispatched*, not *running*. Say which.

### How to attach the monitor, in order of preference

1. **Harness-tracked background work that notifies you on exit.** Often the launch
   itself can run this way, so the executor exiting *is* the notification.
2. **A watcher script run as harness-tracked background work**, exiting when a
   concrete condition is met: a new commit past BASE, the executor process gone,
   or silence past a threshold. The script may check on a timer internally — the
   point is that *you* are not woken on every cycle.
3. **Neither is available** → the dispatch does **not** meet the async contract.
   Say so plainly. Use the fallback the project has already allowed, or ask the
   user; do not slide silently into checking every turn.

Before relaunching after a monitor failure, confirm the executor is not already
running. A broken monitor on a live executor is two facts — record both; a second
launch on top of it is a duplicate dispatch.

The same holds for any re-dispatch of a task: each attempt is a new run with its
own id, and it never shares a worktree with an earlier attempt that may still be
writing. Confirm the old one is gone, or give the new one its own worktree.

### After dispatch: work or wait, never poll

- **Carry on with independent work** inside the scope and cadence the working
  agreement (`project-working-agreement`) allows. If there is none, end the turn and wait for the notification.
- **Do not read logs, check the PID, or ask the executor on a schedule just to
  learn "is it done yet".** Check by hand only when a signal looks wrong, when you
  suspect the monitor has died, or when the user asks for progress.
- Async is not a licence: it does not permit dispatching further tasks or running
  in parallel beyond what was agreed, and a stop-after-each-task rhythm still
  stops after acceptance.

### While waiting: the cache must not expire on a large context

When a run may outlast the prompt-cache TTL, the result must land on a warm cache
or on a context small enough that reloading it is cheap. Keep one warm-up timer
per session, re-armed at the end of every turn with runs out — how, and when it
stops paying: `keeping-cache-warm`.

### When a notification arrives

- **Match it to the task and run.** Drop duplicates and events from an older run;
  a repeated notice must never cause a second acceptance or a second dispatch of
  the next task.
- **Exit code 0, a new commit, changed files are progress — not acceptance.** Move
  the task to awaiting acceptance and run `checkpoint-verification`.
- **Silence past the threshold is a warning to investigate, not a verdict.** It can
  be an agent working, out of quota, or a process holding a pipe waiting for input
  that never comes. Distinguish by evidence: process state, quota, log timestamps,
  changed files. A live process proves nothing about completion; an exited one
  proves nothing about success.

### Task states

| State | Meaning |
|-------|---------|
| Dispatched | Launch issued; not yet evidence that the executor started and the monitor is attached |
| Running | Executor started, monitor attached, run recorded |
| Awaiting acceptance | Executor returned; you have not verified it |
| Done | You verified it and every applicable gate passed |
| Blocked | Missing a decision, information, or precondition |
| Failed | Evidence the run did not meet the task; decide fix or re-dispatch (as a new run) |
| Cancelled | Confirmed stopped, within your authority |

**Only Done is done.** Nothing else counts as a completed task — in the pointer or anywhere else.

### Before ending a turn: nobody idle while work is ready

An executor that finished and sits idle while the next task waits for the user to
say "go on" is throughput thrown away — and it happens exactly at the moment the
coordinator feels done: a notification came in, acceptance passed, a report got
written, the turn ended. **The notification that frees an agent is also the cue to
feed it.** In the same turn, before you stop, check:

1. **Any agent free?** Its last run is Done, Failed, or Cancelled, it has no run in
   Dispatched/Running, and its quota holds.
2. **Any task ready?** Not yet dispatched, every dependency Done, it is in the
   current wave (or the wave just finished — then the next wave is current), and
   it holds nothing a running task holds.
3. **Does the agreement allow it?** Cadence *continue* and the task within the
   agreed scope.

All three yes → **dispatch now**, by the same rules as any dispatch (assignee from
the table, BASE, monitor, pointer). Don't report "task 3 done" and stop while
task 4 is ready and its executor is idle.

Awaiting acceptance counts too: a result you have not verified is the work that
frees the next dispatch, so verify it now rather than leaving it for the next turn.

Ending the turn is right only when one of these holds — **and your message says
which**:

- every free agent has nothing ready (the rest of the wave is still running);
- cadence is *stop after each task* — report and wait, as agreed;
- the next task is Blocked on a decision or permission only the user can give —
  ask that one question;
- quota is out on everyone who could take it.

"Waiting for the user" without one of these reasons is not a state; it is an idle
workforce.

### Rules paid for in lost time

1. **Capture the BASE commit at dispatch and give it to the monitor.** Without a
   baseline, "a new commit appeared" is unanswerable and an old commit looks like
   progress.
2. **Never describe a monitor you did not actually start.** A described-but-unstarted
   monitor once cost half an hour of a dead dispatch — everything *looked* fine
   because nothing was watching.
3. **Never poll to fill the silence.** Every status check spends your context on a
   question the monitor already answers.

## Running Executors in Parallel

Parallel dispatch is where throughput comes from, and where the coordinator's
mistakes get multiplied.

- **Run the waves the plan drew** — which tasks run together was settled in the
  assignment table, not improvised at dispatch. If the agreement says *prefer
  parallel* and the plan runs everything one at a time with no reasons given, send
  the plan back through `planning-for-delegation` before dispatching — don't
  quietly run it as a queue, and don't widen it on the fly either.
- **Partition by file, and say so explicitly in every prompt** — list the files
  each other executor is holding, with "do not touch, not even to fix an error."
- **Isolate shared resources**: ports, databases, fixture directories. Two
  executors sharing a test database will produce failures that belong to neither.
- **Warn that repo-wide lint/typecheck will show foreign errors.** Tell them to
  scope their own check to their files and to report which errors came from
  outside their scope — otherwise they will "helpfully" fix someone else's file
  and destroy the isolation.
- **Keep the checkpoint discipline per executor.** Parallel dispatch means several
  one-task handoffs at once, not one executor running several tasks.
- **Two tasks may share a contract only when it was laid down and reviewed first**
  and is read-only for both (`planning-for-delegation`). Say so in each prompt: the
  contract files, and "if it is wrong, stop and report — do not edit it". A
  contract still being shaped belongs to one task; the others wait.

## The Loop

```
read working agreement → cadence + execution mode + role limits (set it up if missing)
read team.md → who is assigned what here; ask the user if a role is unfilled
read the plan's assignment table → waves, assignees, what each task holds
  (no plan file, e.g. T1 → one task, one wave; pick the assignee from team.md)
for each wave:
  for each task in the wave:
    check quota and Tạm dừng → confirm the assignee (swap within the approved source; record it)
    capture BASE commit
    dispatch ONE task in the background (prompt → context file + task + area lessons
      + files the rest of the wave holds)
    attach monitor immediately (exit: new commit / process gone / silence) → record run in pointer
  do independent work, or end the turn and wait for notifications — never poll
  runs still out at end of turn → keeping-cache-warm (one session-wide timer, re-armed, never replaced)
  per notification → match task + run → awaiting acceptance
    checkpoint-verification   (call-site + real runtime path; recompute expected numbers yourself)
    convention-commit-gate    (enums, no magic literals, commit style)
    fix or re-dispatch if a gate fails
    record any lesson learned  → lessons-ledger
    update team.md if an agent surprised you either way
    an agent is free → a task ready and allowed? dispatch it now, same turn
  next wave only when every task in this one is Done — then start it at once
before ending any turn: free agent + ready task + cadence continue → dispatch, don't stop
when a risky area is complete, before merge:
    adversarial-review-to-go  (converge findings to GO)
then:
    finish/merge the branch (superpowers:finishing-a-development-branch on Claude Code)
```

## Red Flags

| Thought | Reality |
|---------|---------|
| "The executor said tests pass, ship it" | Run `checkpoint-verification` yourself. Summaries hide skipped links. |
| "Its tests are green, the logic is right" | It wrote both. Recompute the expected values from fixtures and check against those. |
| "Let it do the next task too, this one looks fine" | One task per checkpoint. Unreviewed work compounds. |
| "I'll check on it in a while" | Attach a monitor at dispatch, with a real exit condition and a BASE commit. |
| "I've got a watcher on it" (but didn't start one) | Say "no monitor — dispatch doesn't meet the async contract." A described-but-unstarted watch costs you the whole idle period. |
| "Let me peek at the log, see if it's done" | The monitor will tell you. Check by hand only on a wrong-looking signal, a suspected dead monitor, or a user request. |
| "Nothing else to do, I'll check every minute" | End the turn and wait for the notification. |
| "It'll take hours, the cache will just reload when it's back" | That reload costs 1.25–2× the whole context. `keeping-cache-warm`. |
| "Task accepted, report to the user and stop" | Free agent + ready task + cadence continue → dispatch it in this turn. Stop only with a stated reason. |
| "I'll accept that result next turn" | Unverified work holds up the next dispatch. Verify it now. |
| "Exit 0 and a new commit — mark it done" | That's progress. It's awaiting acceptance until `checkpoint-verification` passes. |
| "Monitor failed, relaunch the whole thing" | Check whether the executor is already running first. Two launches = a duplicate dispatch. |
| "It's been quiet, it must be working" | Silence is ambiguous. Check quota, process state, and whether any file changed. |
| "Process is still alive, so it's still working" | Liveness proves nothing. Check the data it should have produced. |
| "This tiny mechanical change — delegate it" | If it's fully specified, you're faster than the round-trip. |
| "The executor is wrong, override it" | When an executor stops to question the plan, it's often right. Verify against source before dismissing. |
| "It hit the same trap as last phase" | The lesson never reached it. Promote it into the executor context file — you are the constant in that pattern. |
