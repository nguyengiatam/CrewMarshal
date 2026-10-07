---
name: multi-lane-coordination
description: Use when the working agreement sets coordination mode to multi-lane, or when design finds two or more services or large independent areas that could each carry their own coordinator — in one repo or a workspace of several — covers the lane test, what the Chief owns versus each lane, the project root and shared state directory, opening a lane, headless lane runs that always start fresh from the lane pointer, the interactive alternative where each lane runs in its own terminal window the user can watch and answer in, when a lane run should stop for a clean reset, and how the Chief integrates.
---

# Multi-Lane Coordination

One coordinator runs out of room on a project with many services: every task's
review, every executor's report and every open question pile into one context.
Multi-lane splits the **execution** across several coordinators while keeping one
place that designs, integrates and talks to the user.

This runs only when the working agreement says `Chế độ điều phối: nhiều lane` ✓
(`project-working-agreement`). Without that line the project is single-coordinator
and nothing here applies — small projects keep the arc exactly as it is.

## Roles

| Role | Does | Never does |
|------|------|------------|
| **Chief** (the user's session) | Design, system profile, working agreement, team file, cross-service spec and contracts, splitting lanes, launching lane runs, answering lane questions (asking the user when needed), integration | Re-review a lane's individual tasks; edit a lane's files |
| **Lane coordinator** (one per lane, headless or interactive) | Plans, dispatches and accepts the tasks of one lane, inside its charter, with the normal arc (`planning-for-delegation`, `orchestrating-executors`, `checkpoint-verification`) | Talk to the user (headless) or settle anything beyond its charter with them (interactive); edit outside its owned paths; edit commons |
| **Executor** | One task, as today | — |

**The user talks to the Chief only.** A lane that needs a decision stops its run
and asks the Chief in writing; the Chief batches questions to the user and writes
the answers back. It costs more tokens than letting lanes ask directly — the price
of the user dealing with one agent. *Interactive Lanes* below relax this, inside
the charter only.

## The Lane Test

An area becomes a lane only if **all** of these hold:

- **Own repo or own directory** it alone writes — a service, or a feature folder
  large enough to matter.
- **Own tests and build** that run without the other lanes' code changing.
- **No file written by two lanes.** Anything two lanes would both touch is
  *commons* (below), not part of either lane.
- **Enough work to pay for a coordinator** — at least two waves in its plan.
  Smaller areas merge into a neighbouring lane or stay with the Chief.

Fewer than two areas pass → stay single. The coordination-mode question is not
even asked.

## Who Owns What

Everything project-wide stays with the Chief; a lane gets a thin layer in its
charter. **One writer per file** — that rule is what lets several sessions run at
once without overwriting each other.

| Resource | Project tier — Chief writes | Lane tier — in the charter |
|----------|-----------------------------|-----------------------------|
| `system-profile.md` | Scale, trade-offs, hard boundaries | Only what differs for this service |
| `working-agreement.md` | Cadence, modes, conventions | May **tighten** (e.g. adversarial review on every task), never loosen |
| `team.md` | Every agent and its proven record | The lane's executor pool — a subset the Chief assigns |
| Executor context | Project-wide conventions | Scope dirs, test and build commands of this service |
| Roadmap, cross-service spec, contracts | Written and frozen before lanes open | Which contracts the lane provides and consumes |
| Plan | — | The lane coordinator writes its own, inside the charter, in `.crewmarshal/lanes/<name>/plans/` |
| `lessons-ledger` | One shared ledger | Lanes **propose** lessons in their outbox; the Chief records them |

**Commons** — lockfiles, root manifests, CI config, compose files, migration
numbering, shared libraries, contract files and the project's CrewMarshal documents in `docs/` (pointer,
profile, agreement, team, executor context, lessons, specs, plans) — belong to the
Chief. A lane that needs a change there asks for it.

**Contracts are frozen while lanes run**, the same rule `planning-for-delegation`
applies to a wave, one level up. A lane that finds a contract wrong stops and asks;
the Chief amends it where the project keeps contracts, then tells every lane that
consumes it.

## Layout

A project may be one repo or a workspace of several (a folder holding an API repo,
a web repo, a docs repo…). Everything below is anchored to the **project root**:
the directory whose `docs/` holds the shared documents, and where the
Chief's session runs.

| Project shape | Project root |
|---------------|--------------|
| One repo | The repo's root |
| Workspace of repos | Wherever the project already keeps those documents — the workspace folder, or a docs repo inside it. Never two. |

- **Coordination state:** `<project-root>/.crewmarshal/`. Not versioned, no history.
  If the project root is itself a git repo, the Chief adds `.crewmarshal/` to its
  `.gitignore` once, when opening the first lane.
- **Code:** a lane writes in one repo or several. For each, it gets a git worktree
  on branch `lane/<name>`, cut from that repo's `main`, at
  `<project-root>/.crewmarshal/worktrees/<name>/<repo>/` — one ignored place for
  all of it.
- **Shared documents** stay at `<project-root>/docs/`. Lanes read them
  there by absolute path, whichever repo they work in.

```
<project-root>/.crewmarshal/
├── lanes/<name>/
│   ├── charter.md    ← Chief writes: repos and paths, contracts, pool, what shared docs to read
│   ├── STATUS.md     ← lane writes: the lane pointer (pointer-handoff format)
│   ├── inbox.md      ← Chief writes: numbered entries — assignments, answers, contract changes, "tìm điểm dừng"
│   ├── outbox.md     ← lane writes: numbered entries — ready @sha, questions, escalations, lesson proposals, reset
│   ├── jobs/         ← lane's detached executor jobs: <id>.pid, <id>.log, <id>.exit
│   ├── runs/         ← one output file per lane run, written by the Chief's launch (headless)
│   ├── launch.sh     ← interactive only: env vars + claude command the window runs (launch.ps1 on Windows), prompt in prompt.txt
│   └── window        ← interactive only: Chief writes what the launch returned (window id, tmux window…) so it can close it
└── worktrees/<name>/<repo>/
```

Templates: [references/lane-files.md](references/lane-files.md).

The Chief launches every lane run with two environment variables,
`CREWMARSHAL_PROJECT_ROOT` and `CREWMARSHAL_LANE`. They tell the run — and the
plugin's hooks — where the project root is and which lane this session is,
whatever repo or directory it was started in.

The Chief's own pointer stays the project pointer (`docs/STATUS.md`)
and carries a **lane board** — see `pointer-handoff`.

## Opening a Lane

After the shared design is done — profile, agreement, team, cross-service spec,
frozen contracts — the Chief, per lane:

1. Creates a worktree and branch in every repo the lane writes.
2. Writes the charter: the project root, repos and worktree paths, owned paths, read-only paths, contracts provided and
   consumed, executor pool, any tightened rules, **which shared documents (and
   which sections) the lane must read** — a lane never loads everything.
3. Writes inbox entry #1: the first milestone.
4. Adds the lane to the lane board, then launches its first run.

## A Lane Run

Every run is a **new headless session**. The Chief never resumes one: a resumed
session drags its whole history back into context, which is what the reset exists
to shed. The charter, the lane pointer and the inbox are the only memory a run has.

**Start:**
1. In each of its worktrees, merge that repo's `main` into `lane/<name>`. This
   brings in what the Chief and other lanes landed there. It cannot conflict when
   every lane stays inside its owned paths — a conflict means a boundary was
   crossed: write an escalation and stop.
2. Read the charter, then the shared documents and contracts it names, from the
   project root.
3. Read the lane pointer and reconcile it with `git log` of its branches
   (`pointer-handoff`). A run that hit the hard ceiling last time left it stale.
4. Read the inbox from the entry after the last one the pointer acknowledges.

**Working:** the normal arc, inside the charter. After **every accepted task**,
re-read the inbox — it is the only way the Chief reaches a running lane.

**Executors inside a lane run** are launched **detached**, each under a fresh id
per launch, writing its exit code to `jobs/<id>.exit` when it ends. A headless session kills its own background
tasks when it exits (verified on Claude Code 2.1.282: `run_in_background` work died
with the session, a `nohup … &` process survived). So a lane run never waits on an
executor: it dispatches, records every job in its pointer's *Đang dở*, and stops.
The Chief watches the exit files (and the processes, for a job that dies before
writing one) and starts the next run when they land. Exact
commands are in the roster (`orchestrating-executors`).

**A run ends on exactly one of these**, always with the pointer written first and
one outbox entry:

| Ends because | Outbox entry |
|--------------|--------------|
| Milestone done | `sẵn sàng tích hợp` + `<repo>@<sha>` per repo + test counts |
| A decision it may not make | The question, the options, what it recommends |
| Blocked, or needs commons or another lane | Escalation with evidence |
| Waiting on executor jobs | `chờ job: <ids>` |
| Time for a reset | `reset: <lý do>` |

Guessing past a question to keep the run going is the failure this table exists to
prevent: the answer lands in code before the user ever sees the question.

Before exiting, the run checks its pointer against one test: **could an empty
session, given only the charter, this pointer and the inbox, start *Việc kế tiếp*
immediately?** If not, the pointer is not done.

## Interactive Lanes

The working agreement picks how lane runs execute: **headless** (the default,
everything above) or **interactive** — each lane run is a normal Claude Code
session in its own terminal window or tab. The user can watch every lane and answer
a lane's question in place instead of through the Chief.

### Before the first interactive lane: settle the environment

How a window is opened depends on the user's machine, so the Chief settles it once
and records it in the working agreement before opening any lane this way:

1. **Look first, ask only what it cannot see.** OS, terminal app (`$TERM_PROGRAM`,
   `$WT_SESSION`, `$TMUX`…), whether `claude` is on the path. Ask the user what it
   cannot detect or what is a preference: window or tab, which terminal app, and
   any permission the method needs (macOS asks once for Automation to drive
   Terminal; faking ⌘T for a tab also needs Accessibility).
2. **Prove it with one probe window** before writing anything: open a window with
   the chosen method running `claude -n lane-probe` in the same permission mode as
   the Chief, check `ListAgents` shows it, send it a message asking for a reply,
   receive the reply. Then the user closes it.
3. **Record the result** in the agreement — the method, the exact launch command,
   and whether cross-session messaging works there. Methods and known traps per
   environment: [references/lane-windows.md](references/lane-windows.md).

If messaging fails in the probe, interactive lanes still work, but every signal
travels through the outbox and the user: the lane tells the user in its window, the
user tells the Chief. Record that in the agreement, not as a surprise later.

### Launching

The Chief writes `lanes/<name>/launch.sh` (or `.ps1`): `cd` to the lane's first
worktree, export `CREWMARSHAL_PROJECT_ROOT` and `CREWMARSHAL_LANE`, then
`claude -n lane-<name>-r<run> <permission flag>` with the lane-run prompt read
from `prompt.txt` beside it. The window runs that file — quoting a whole prompt
through AppleScript or `wt.exe` is where launches break. The run number in the name keeps a new run distinct from an old
window still open. The Chief writes whatever the launch returned that identifies
the window (macOS: `window id N`) to `lanes/<name>/window`. The permission mode must match the Chief's: a session in another
mode holds peer messages for its user's approval, and they expire unseen.

### What changes in a run

Start, the normal arc inside the charter, and the ending table stay as above. These
differ:

- **Questions inside the charter** — how to build something within the lane's own
  paths — the lane asks the user in its window and waits; no new run. Anything
  touching a contract, commons, another lane or the shared documents still goes to
  the outbox and the Chief.
- **Every decision the user makes in a lane window becomes an outbox entry**
  (`quyết định`): what was decided, user-confirmed. The Chief records the ones that
  outlive the lane where they belong. A decision held only in one window is the
  failure this mode risks most — lane B never learns what lane A's user said.
- **Signals are a doorbell, files are the record.** Write the outbox entry first,
  then send the Chief one line naming its number (`SendMessage` to the Chief's
  session name, from the charter). The Chief does the same the other way: inbox
  first, then a message to `lane-<name>-r<run>`. A message never replaces the entry,
  and silence never means received.
- **Executors** still launch detached under a fresh id, so the user closing the
  window does not kill them. The lane may wait on them with a monitor instead of
  ending its run.
- **Reset:** at a clean point the lane writes its pointer and `reset`, messages the
  Chief, and stops. The Chief closes the old window, then opens the next run in a
  new one — never `/clear` or `--resume` in the old one. To close, only after the
  `reset` entry is in the outbox and `ListAgents` shows the lane idle: find the
  process whose command is exactly `claude -n lane-<name>-r<run>`, end it, then
  close the window recorded in `lanes/<name>/window` (commands per environment in
  `lane-windows.md`). Ending the process first keeps the terminal from asking
  whether to kill it. Where the environment has no way to close a window, the
  Chief ends the process and tells the user which window to close.

### The Chief's side

There is no process exit to watch. The Chief acts on the lane's messages and the
outbox; when a lane has gone quiet past what its task should take, one
`SendMessage` with `notify_when_idle` replaces any polling. When a lane is waiting
on the user, the Chief tells the user in one line which window and what about — it
does not answer for them, and it does not copy the question into its own chat.

## When to Reset

A long session degrades: early detail crowds out the current task. A lane run
should end at a clean point and let the next one start from the pointer — but only
when the pointer can carry everything that matters. Reset needs **both**:

**1. The session is long** — any of:
- It has accepted about as many tasks as the agreement's lane-run limit.
- Its context has grown past the threshold the Chief watches — the agreement's
  number, or **about 300k tokens** when it sets none (a proposed `~` value until
  the user confirms one).
- It was compacted. Strongest signal: reset at the next clean point.

**2. What remains is clear and converging:**
- *Việc kế tiếp* is concrete and startable.
- No investigation half-done, no hypotheses held only in context.
- No executor running that the pointer does not list.

Long but still diverging — mid-debugging with three live hypotheses — keeps going
until it converges. If it must stop anyway, the hypotheses and their evidence go
into *Cảnh báo đang mở* first.

**A clean point:** the last task accepted and committed, every running job
recorded, the pointer written with evidence, `reset` in the outbox.

**Who triggers it:** the lane itself when it sees both conditions; or the Chief,
which can see the run's context size from its output and writes `tìm điểm dừng` to
the inbox. The lane stops at its next checkpoint, not mid-task.

**The hard ceiling** (turn limit or timeout on the launch) is a safety net, not the
plan. Hitting it is a dirty stop — the next run must reconcile before trusting the
pointer. Repeated dirty stops mean the lane-run limit is too high: lower it.

## The Chief's Loop

The Chief launches each lane run in the background with a monitor attached, as
`orchestrating-executors` requires for any dispatch, and watches three things:

- **The run's exit** → read the new outbox entries and act.
- **The run's context size** → past the threshold, write `tìm điểm dừng`.
- **Job exit files a lane is waiting on** → when all have landed, start a new run.

Outbox handling:

| Entry | Chief does |
|-------|------------|
| Ready @sha | Integrate (below), then the next milestone in the inbox — or close the lane |
| Question | Answer from settled rules if it can; otherwise ask the user, batched with other lanes' questions; write the answer to the inbox; start a new run |
| Escalation | Resolve: amend commons or a contract, re-split lanes, or ask the user |
| Lesson proposal | Record it in the ledger (`lessons-ledger`) |
| Reset / waiting | Start a new run when there is something to do |

When the Chief changes anything shared, it writes one inbox line to every lane
affected, naming what changed (and the SHA, where it is versioned). Lanes read shared
documents straight from the project root, so **a saved edit is already published**:
the Chief edits a shared document only when the change is ready.

## Integration

The Chief does not re-review a lane's tasks — the lane accepted each one with
`checkpoint-verification`. The Chief checks what no lane can see:

1. Merge each lane branch at the reported SHA into that repo's `main`.
2. Run the contract tests and the cross-service paths end to end — drive the real
   runtime path across the services (`checkpoint-verification`), not just each
   side's own tests.
3. Adversarial review at integration altitude (`adversarial-review-to-go`): how the
   services meet, not how each is written.

Lanes that ship on the same milestone are merged one at a time, each verified
before the next.

## The Chief's Own Session

The Chief is interactive, so it does not reset itself — it follows *Suggesting a
Fresh Session* in `pointer-handoff`, like any single coordinator. The same two
conditions apply, with the same threshold: when they hold, it writes its pointer and **suggests** a new session to the
user. Its pointer stays short by holding the lane board, not the lanes' detail.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Resume the lane's last session, it already knows everything" | That is the context the reset exists to shed. New session, from the pointer. |
| "The lane can wait for its executor in the background" | Headless background work dies with the session. Detach, record, stop. |
| "I'll ask the user directly, faster than going through the Chief" | Lanes never talk to the user. Stop the run and ask the Chief. |
| "Small fix in the shared lib, quicker than an escalation" | Commons belong to the Chief. The next merge from `main` will show the crossing. |
| "State dir goes in this repo's `.git`" | A workspace has several repos. State lives at the project root, beside the shared `docs/`. |
| "Chief should look over each lane's tasks to be safe" | The lane already verified them. The Chief verifies what crosses lanes. |
| "Session is long, reset now" while three hypotheses are open | Converge first, or write them down. A reset loses whatever the pointer doesn't hold. |
| "Two areas are small but let's make them lanes anyway" | A lane is a coordinator's worth of work. Otherwise stay single. |
| "I'll tell the lane about the contract change when it asks" | Write the inbox line when you commit the change. |
| "Interactive lane, the user already answered in that window — no need to write it down" | Every decision in a lane window becomes an outbox entry. Otherwise only that window knows. |
| "I sent the lane a message, so it knows" | Inbox first, message second. Messages expire, get held, or arrive at a run that is gone. |
| "Open the lane windows the way it worked on my machine" | The method is per environment: probe once, record it in the agreement. |
