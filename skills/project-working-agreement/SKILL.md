---
name: project-working-agreement
description: Use before executing or dispatching work on a project, and whenever the user changes how the work should run — keeps one project file of working rules (stop after each task or continue, what coordinator/executor/reviewer may decide, plan detail, commit and language conventions), set up once by asking the user and reused by every later session and every executor.
---

# Project Working Agreement

The system profile says **what the system is**. The working agreement says **how
we work on it**: when to stop, who decides what, what each role may and may not
do. Without it, every session re-guesses — one stops after every task, the next
runs through the whole plan — and executors never hear the rules at all.

## The File

Default location `docs/superpowers/working-agreement.md`, next to
`system-profile.md`. Template:
[references/working-agreement-template.md](references/working-agreement-template.md).

**Look before you create.** If the project already keeps working rules in
`AGENTS.md`, `CLAUDE.md`, or a similar file, integrate with that — add the missing
groups there, or keep them here and point from there. One place holds each rule;
never two copies that can drift.

Markers as in the profile: `✓` = the user settled it, `~` = proposed or inferred,
not yet confirmed, `CHƯA CHỐT` = open. Only `✓` lines bind. A `~` line is a
question you still owe the user.

## Reading It — before executing or dispatching

1. Read it before the first task you execute or hand off in a session.
2. **Re-read when it may have changed:** the file was edited, the user stated a new
   rule, or context was compacted. A rule changed mid-session applies from the
   **next relevant step** — never keep the old one because you read it first.
3. Apply the cadence and the role limits to what you are about to do.

## Setting It Up — missing file or missing groups

1. Search for existing rules first (above). Don't ask what the project or this
   session has already settled.
2. Ask what is missing **in one batched message**, grouped. Draft `~` answers where
   the repo shows precedent; ask the rest outright.
3. Write the answers to the file as `✓`, commit per the project's commit rules.
   Anything the user can't decide yet stays `CHƯA CHỐT`.

### The cadence question is always asked explicitly

Offer at least these two, and never pick for the user — not even from an example
they gave:

1. **Stop after each task** — finish and verify the task, report, wait for the user
   before the next one.
2. **Continue** — keep going within the agreed scope; ask only when a decision or
   permission is missing. When one part is blocked, continue the independent rest.

Pin down what "a task" means in this project's workflow (a plan task, a phase, a
PR). One tool call is not a task. Continuing never means widening scope or
skipping verification.

## The Groups

| Group | What to settle |
|-------|----------------|
| Cadence | Stop after each task, or continue within scope; what "a task" is |
| Coordinator | Design, breakdown, dispatch, dependency calls, acceptance, keeping state |
| Executor | What it may decide alone, what it must verify, what its report contains |
| Reviewer | Scope, evidence a finding needs, fix directions, what happens on disagreement |
| Authority | What anyone decides alone, what needs the user, what to do when blocked |
| Project rules | Plan detail, language, commit/PR, environment, progress reporting, anything else |

These are the questions to ask, not a fixed role set to impose. Roles can merge
(one agent coordinating and reviewing) — but the plugin's verification boundaries
still hold: whoever writes the code does not certify it, and findings are
re-verified on real source.

**Plan detail** lives here, in *Project rules* — `planning-for-delegation` asks it
the first time a plan is written and records it here, not upfront.

## Changing It

- A request the user makes now applies **within what it covers**. It becomes a
  lasting rule only if that is what the user means — when unclear, ask one line:
  "ghi thành quy ước lâu dài không?"
- An edit to a `✓` line needs the user. A line you revise from new evidence drops
  back to `~` until confirmed.
- The agreement never overrides instructions of higher priority — the harness, the
  user's direct instruction in this session.

## Passing It On

Executors and reviewers don't read your session. The part of the agreement that
applies to their role reaches them through the executor context file (see
`executor-context`) or the handoff prompt — for agents outside your harness too.
That you read the agreement proves nothing about whether they did.

## What Doesn't Go In

| Content | Where |
|---------|-------|
| Scale, trade-off priorities, hard system boundaries | `system-profile.md` (`concept-briefing`) |
| Execution detail every executor needs (scope dirs, test commands) | Executor context file (`executor-context`), which points here for role rules |
| Where the work stands | Pointer (`pointer-handoff`) |
| Lessons from past mistakes | `lessons-ledger` |

## Red Flags

| Thought | Reality |
|---------|---------|
| "They said 'keep going' once, so the cadence is continuous" | An example is not a rule. Ask the cadence question explicitly. |
| "I read the agreement at the start, that's enough" | It may have changed. Re-read after edits, new user rules, or compaction. |
| "Continuous mode, so I'll take the next phase too" | Continue within the agreed scope only. Continuing never widens it. |
| "The user asked for X this time — write it into the agreement" | Only if they meant it to last. Ask one line. |
| "I'll copy the rules into the executor context too" | Point at them. Two copies drift. |
| "The coordinator read it, so the executor knows" | Executors don't see your session. Pass the role's part on. |
| "No agreement yet — I'll assume sensible defaults" | Defaults nobody chose are how sessions disagree. Ask, batched, once. |
