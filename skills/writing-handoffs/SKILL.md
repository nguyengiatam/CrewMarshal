---
name: writing-handoffs
description: Use when writing the prompt that hands one task to an executor or subagent — the prompt must stand on its own (written from files, not session memory or the conversation), state what to achieve and the limits rather than how to work, point at the executor context file instead of retyping conventions, and continue an unfinished task as a continuation rather than a fresh start.
---

# Writing Handoffs

The executor has only the prompt and the files it names. Whatever the prompt leaves
to "as before" or "that one" is a hole it fills by guessing. Dispatch mechanics —
one task per handoff, background run, monitor — are in `orchestrating-executors`;
the fixed project context the prompt points at is `executor-context`.

## Handoff prompt checklist

- The single task and its acceptance criteria, copied from the plan.
- Current HEAD SHA and the baseline test count/state.
- **A pointer to the executor context file** (see `executor-context`) instead of
  restating project conventions, scope boundaries, test rules, and reporting
  requirements every time. If something is missing there, fix the file rather
  than growing the prompt.
- Any lesson specific to the area this task touches, as one constraint line —
  check `lessons-ledger` by area and work type.
- The instruction to reconcile against real code/enums before hardcoding anything.
  **When an executor stops to question the plan, take it seriously** — that is
  usually a hole in your handoff, not a defect in the executor.
- Safety rules for this dispatch: branch, port/DB isolation if parallel, which
  files another executor is currently holding.

## The prompt must stand on its own

The executor sees the prompt and the files it names — nothing of your session.
A prompt that reads clear to you can still be empty to it, and the risk grows
with the session: the longer it runs, the more of what you "know" lives only in
the conversation.

- **Nothing leans on the conversation.** No "the bug from earlier", "the second
  approach", "as agreed", no nickname coined mid-session, no pronoun without its
  noun. Name the thing and give its path. When the task comes from the plan, its
  references are resolved too — "like Task 3", "per spec §X" become the content
  or an exact path and location.
- **It answers four questions,** in the prompt or in the files it names: what to
  do and what result shows it done · where (files, directories) · how acceptance
  is checked (command, expected output) · what not to touch and when to stop and
  ask.

## Say what to achieve, not how to work

Newer models follow the procedure in a prompt to the letter. A rule about *how*
to work stops being advice and becomes the run: told to read a spec "in pieces
of at most 80 lines", with a list of files to "read first", ChatGPT agent runs
read in slices round after round until the run's budget ran out, and ended with
a summary of what they had read and no edit. The same model, given the same kind
of change as a plain request, read the files whole, edited, tested and committed.

- **The task comes first.** Open with what to change and what shows it done.
  Context follows, as paths to open when needed. A long "read this first"
  section turns reading into the job.
- **Constrain the result and the boundaries, not the method.** Files in scope,
  commands off-limits, when to stop: yes. How many lines to read at once, in
  what pieces, in what order to open files: no. The executor knows its own
  tools better than a rule written for another one.
- **A tool limit stays with the action it limits.** "Output over the round cap
  costs an extra round" is about command output: the rule is "send long command
  output to a file and read its tail", never "read files in pieces". Before a
  limit goes into the context file or a prompt, name the one action it governs.

## Continuation task

When a task stopped partway, or a task too long for its agent was split into a
chain (`planning-for-delegation`), each next piece is a **continuation**: same
worktree, same branch, run strictly after the previous piece is accepted — never
alongside it.

- Start from the **last accepted commit**. Uncommitted leftovers of a stopped run
  are inspected, then either committed by you as a piece of their own or discarded
  — the next run never starts on a dirty tree it did not make.
- The prompt names what is already done by commit SHA and what remains, as steps
  from the plan. The executor reads the earlier commits; you do not retell them.
- Each piece ends where build and tests pass and gets its own checkpoint. A piece
  that cannot end in a passing state was cut in the wrong place — recut it.
- Never restart a stopped task from scratch when its finished steps passed review.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The prompt is clear enough, I know what I mean" | You do; the executor has only the prompt. Every "as before" or "that one" is a hole. |
| "I'll tell it exactly how to read, to save rounds" | A method rule gets followed to the letter. State the result and the limits; leave the reading to the executor. |
| "I'll restate the conventions in this prompt" | Point at the context file and fix the file. Retyped conventions drift and get omitted under pressure. |
