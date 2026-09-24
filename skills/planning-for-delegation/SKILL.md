---
name: planning-for-delegation
description: Use after a plan is drafted and before any task is handed to an executor — settles how detailed this project's plans are (asking once and recording it in the working agreement), keeps spec and plan at their own altitudes, runs nine structural checks that catch the errors which send an executor confidently in the wrong direction, and assigns every task to an agent from the team file, grouped into waves that can run in parallel.
---

# Planning for Delegation

A plan with a placeholder stops an executor: it asks, or it visibly fails. A plan
with a **wrong structure** does neither — the executor proceeds, confidently, in
the wrong direction, and the damage only surfaces at infrastructure acceptance,
where it costs many times more.

This skill is the gate a plan passes **before the first task is dispatched**. It
runs from tier T2 up (the tiers that produce a plan file). It assumes the plan
itself was already drafted — on Claude Code by `superpowers:writing-plans`,
elsewhere by hand.

## Spec and Plan Are Different Altitudes

A spec states **what must be true**. A plan states **how it gets done**. Mixing
them is not a style question: mechanism inside a spec cannot be verified by
reading, it ties the executor's hands, and it turns the design step into the
bottleneck.

| | Spec | Plan |
|---|---|---|
| Goal, and why | ✓ | points back at the spec, never restates it |
| Decisions + reasoning | ✓ | — |
| Constraints | as **results that must hold** | as the steps that hold them |
| Known risks | *how it breaks* | *what the step does about it* |
| Definition of done | observable | measured per task |
| Mechanism — structures, file layout, where the middleware goes | **no** | ✓ |

**Signs a spec has dropped an altitude:** a section only a test run could confirm
or refute · sentences of the form "change type X to Y" · long quoted code · file
line numbers scattered through the body.

A spec that grew through review rounds is the usual cause. Ask the reviewer for
cuts explicitly — see `adversarial-review-to-go`.

## How Detailed Should the Plan Be? Ask the Project.

Two defensible conventions exist, and which is right depends on **who executes**
and what they have proven:

- **Plan points, executor writes.** Examples are minimal — a signature, a data
  shape — enough to fix the shape and the constraints, never a copyable
  implementation. Leaves the thinking with the executor.
- **Plan carries the code.** Every step ships the actual code to write. This is
  `superpowers:writing-plans`' default: it requires code blocks for code steps
  and lists *"steps that describe what to do without showing how"* among its
  **plan failures**.

**Do not pick for the project. Resolve it in this order:**

1. **Read the working agreement** (`project-working-agreement`) — the plan-detail
   line under *Quy ước riêng*. If it is settled there, follow it and move on.
2. **No line there?** Look for precedent: existing plans under the
   project's plans directory. Infer the convention, write it into the agreement
   marked `~`, and confirm it in the next batched question.
3. **No line and no precedent?** **Ask the user, once**:

> "Dự án chưa có quy ước về độ chi tiết của plan. Hai kiểu: (a) **plan trỏ** —
> nêu mục tiêu, ràng buộc, nghiệm thu, ví dụ tối giản, phần cài đặt để executor
> nghĩ; (b) **plan chép đủ code** — mỗi bước kèm code viết sẵn. (a) hợp khi
> executor đã chứng minh làm được và ta muốn giữ tốc độ; (b) hợp khi executor
> yếu hoặc vùng code quá nhạy cảm. Chốt kiểu nào? Tôi ghi vào working agreement để
> các phiên sau khỏi hỏi lại."

Then **write the answer into the working agreement**, not just into this conversation. The
whole point is that the next session — and the next executor prompt — inherits
it instead of silently falling back to a default nobody chose.

When the agreement says "plan trỏ", this skill **overrides** the
`superpowers:writing-plans` rule above for this project. Say so in the plan
header, so a later reader does not "fix" the plan back.

## Nine Checks Before Handoff

Run these on the finished plan. They are deliberately not the checks
`superpowers:writing-plans` already runs (spec coverage, placeholders, type
consistency) — those catch a plan that is *incomplete*. These catch a plan that
is **complete and wrong**. On a real plan, the first review round found 12
findings of exactly this kind.

1. **Draw the real dependency graph — do not list tasks on one line.** Writing
   `C1 C2 C3 C4 C5 C6` side by side reads as "parallel". State which pairs are
   genuinely parallel **and why** (different repo, different file region).
2. **Artifact conflicts block parallelism, not just source conflicts.** Two tasks
   touching different source files still collide if both regenerate a committed
   build directory. Check generated files that are committed.
3. **A task consuming a gate's output must sit after that gate on the map.**
   "Depends on A1 being merged" is wrong when the map places the merge after both
   A1 and A3.
4. **"Done when" must measure the task's hardest requirement, not its easiest.**
   A 400-line port whose real requirement is "behaviour unchanged" is not
   accepted by "it boots and registers the handlers". For a port or migration,
   acceptance is an **old ↔ new comparison table that can be produced**.
5. **Every task has a "done when".** Missing ones are not neutral: an executor
   without acceptance criteria infers "tests are green" — wrong for every task
   whose real requirement is only observable on infrastructure.
6. **Scan for undecided decisions disguised as steps.** Markers: "or",
   "alternatively", "depending on". An executor resolves these by instinct and
   does not report doing so. If the choice has security or data consequences,
   settle it before dispatch.
7. **Match every acceptance line to the step that measures it** — this catches
   circularity. One plan asked for "service X no longer in the cluster" and
   measured it at a step *before* the step that removed X.
8. **Every number in the plan is a claim; verify it.** "Rebuild and deploy 9
   services" — in reality 7 had manifests and 1 repo would not build.
9. **Point at conventions per task, not "follow the code style".** A convention
   set of twenty-odd files, each opening with *when to read this file*, is
   written to be read selectively. Name the two or three rules most often
   violated in that area — `lessons-ledger` knows which.

Fix inline; no second pass needed. If a check keeps failing across plans, that is
a `lessons-ledger` entry, not a habit.

## Assign the Work: Who Does Each Task, in Which Wave

A plan that only lists the work leaves the hardest coordination call — who runs
what, and what can run at once — to be improvised mid-dispatch, one task at a time.
The plan carries an **assignment table** instead: tasks grouped into **waves**, each
task naming who does it and why.

### Where the names come from: the team file

Assignees are picked from the project's team file (`docs/superpowers/team.md`, see
`orchestrating-executors`) **by capability** — its *Phân công* table for the role,
its *Năng lực quan sát được* table for what each agent has proven. Match the task's
hardest requirement to an agent with evidence for that kind of work.

- **No team file, or the role the task needs is unfilled** → ask the user once,
  batched with the plan's other open questions, and record the answer in the team
  file. Do not fill the table from memory or from whoever is listed first.
- The coordinator is a valid assignee (**C**): foundation, concurrency,
  verification code, and anything where precision beats delegation.

### Waves

A **wave** is a set of tasks that run at the same time; the next wave starts only
when every task in the current one is Done. Waves come straight out of the
dependency graph from checks 1–3 — a task sits in the first wave after everything
it consumes.

Two tasks share a wave only when they share **nothing a parallel run can collide
on**: source files, committed generated artifacts, a contract/interface, or a
runtime resource (DB, port, fixture directory) that is not isolated. Whatever a
task holds goes in its *Giữ* column — that column becomes the "do not touch" list
in every other prompt of the wave.

Wave width has three limits — take the smallest:

- **The team:** an agent appears twice in one wave only if the roster says it can
  run independent sessions side by side. Otherwise its second task moves to the
  next wave.
- **Quota:** a wave that spends every agent to zero leaves nobody to review it.
- **Review capacity:** every returned task needs acceptance. Five tasks landing at
  once means four waiting on the coordinator — a wider wave is not faster past that.

### The table

```markdown
## Phân công
Nguồn: docs/superpowers/team.md (<ngày đọc>)

| Task | Lượt | Người làm | Vì sao | Giữ | Chờ |
|------|------|-----------|--------|-----|-----|
| T1 schema | 1 | C | nền móng, sai là lan cả plan | db/schema.sql | — |
| T2 API list | 2 | <agent> | <bằng chứng trong team.md> | api/list.ts | T1 |
| T3 UI list | 2 | <agent khác> | <bằng chứng> | web/list/* | T1 |
| G1 review lượt 2 | 3 | <agent không viết T2/T3> | phản biện | — | T2, T3 |
```

- **Every task has one assignee.** An unassigned task defaults to whoever reads the
  plan next — in practice, the coordinator discovers mid-dispatch that it was never
  dispatchable.
- **Review and gate tasks go to an agent that wrote none of the code they review.**
- **Vì sao** cites evidence from the team file, not an impression. A reason like
  "strong coder" is the same prejudice the team file exists to prevent.

### The table is a plan, not a lock

It is written at plan time; quota is checked at dispatch time (`orchestrating-executors`).
When the named agent is out of quota or has failed on this area since, the coordinator
may swap — **within the same source of labor the user already approved** — and writes
the swap into the table and the pointer. A swap into a source the user has not
approved (a subagent where the team file records none, say) goes back to the user.

### Check the table before handoff

With the nine checks: every task assigned · every assignee exists in the team file ·
no two tasks in a wave hold the same file, artifact, contract, or resource ·
no reviewer reviews its own code · the widest wave fits the team, quota, and review
capacity.

## Review Gates Between Phases

A plan long enough to have phases needs a **gate between them**, not one review
at the end. At each gate, the phase's output goes through
`adversarial-review-to-go` with the **plan template** (or the diff template once
code exists) — a phase built on an unreviewed phase is a defect that compounds.

Mark the gates in the plan itself, as tasks. A gate that lives only in the
coordinator's intention gets skipped under time pressure, and its absence is
invisible afterwards.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The plan is complete, so it's ready to hand off" | Complete and wrong is the dangerous case. Run the nine checks. |
| "I'll write the code into the plan so nothing goes wrong" | Check the working agreement first. If the project says "plan trỏ", writing the code is doing the executor's job and making planning the bottleneck. |
| "The skill says code blocks are required" | That is `writing-plans`' default, and it is a project decision — recorded in the working agreement. |
| "No convention anywhere, I'll use the sensible default" | Ask once, then record it. A default nobody chose gets re-litigated every phase. |
| "These tasks touch different files, so they're parallel" | Check generated artifacts and shared migrations too. |
| "Acceptance is that the tests pass" | Then the tasks whose requirement is only observable on infrastructure have no acceptance at all. |
| "The executor will ask if something is ambiguous" | It will not. It picks, silently, and reports success. |
| "'9 services' — I counted earlier" | Every number is a claim. Verify before an executor acts on it. |
| "I'll decide who does what when I dispatch" | Then parallelism gets improvised one task at a time. Put the waves and assignees in the plan. |
| "Agent X is good, give it the whole wave" | One agent, one task at a time unless the roster says it runs parallel sessions. Pick by evidence in the team file. |
| "Different files, same wave" | Also check artifacts, contracts, and shared DB/ports. What a task holds goes in *Giữ*. |
| "I'll review everything at the end" | A phase built on an unreviewed phase compounds. Put the gates in the plan as tasks. |
