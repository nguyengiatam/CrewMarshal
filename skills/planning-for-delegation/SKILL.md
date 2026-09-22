---
name: planning-for-delegation
description: Use after a plan is drafted and before any task is handed to an executor — settles how detailed this project's plans are (asking once and recording it in the working agreement), keeps spec and plan at their own altitudes, and runs nine structural checks that catch the errors which send an executor confidently in the wrong direction.
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

## Mark Who Does Each Task: [E] / [C]

Every task carries an assignment:

- **[E]** — an executor (external agent or subagent) does it.
- **[C]** — the coordinator does it: foundation, concurrency, verification code,
  and anything where precision beats delegation.

An unmarked task defaults to whoever reads the plan next, which in practice means
the coordinator discovers mid-dispatch that a task was never dispatchable. It
also makes quota planning possible: `orchestrating-executors` needs to know how
many [E] tasks are actually queued.

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
| "I'll review everything at the end" | A phase built on an unreviewed phase compounds. Put the gates in the plan as tasks. |
