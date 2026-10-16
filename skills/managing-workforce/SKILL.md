---
name: managing-workforce
description: Use when choosing which agent does a task, when a project needs its first subagent or external executor, when an agent fails or runs out of quota, or when deciding what an agent has proven — keeps the project's team file (who is assigned what, observed capability with evidence, paused agents and when to retry them), matches work to agents by difficulty and length, confirms with the user before spending a new source of labor, and allocates quota across a phase.
---

# Managing the Workforce

Who does each task is a decision about the user's money and time, made from what
each agent has proven on this project — not from memory or habit. Dispatch mechanics
are in `orchestrating-executors`; exact invocations and quota commands in its
[executor roster](../orchestrating-executors/references/executor-roster.md).

## Selecting an Executor

**Check quota across the whole roster before assigning heavy work**, not just for
the one you intend to use — you need to know your fallbacks before you need them.

Then match work to agent:

| Work | Route to |
|------|----------|
| Writing detailed plans from a spec | The strongest reasoning agent available; you review rather than write |
| Business logic, algorithms, anything with a subtle contract | A capable executor **plus** independent verification of the numbers |
| Mechanical: scaffolding, copying modules, CRUD, enum plumbing | The cheapest agent with quota — or yourself if it's fully specified |
| Review of concurrency, migration, crash-gap | The review-strong agent, and never the one that wrote the code |

Start from the plan's assignment table (`planning-for-delegation`): it names who does
each task and which tasks share a wave, picked from the project's team file (see
below). At dispatch you only confirm it still holds — quota, and nothing new in the
team file against that agent. A swap stays within the source of labor the user
approved and gets written back into the table and the pointer.

Reserve quota on at least one agent as a fallback and second opinion. Running
every agent to zero leaves you unable to review what the last one produced.

## Knowing Your Workforce

Coordinating is a management job: you are expected to know who is available, what
each one is for, and what each has actually proven. Two distinct sources of labor:

| | **Subagent** (inside your own harness) | **External agent** (its own CLI) |
|---|---|---|
| Quota | Spends the **current session's** budget | Its own, independent budget |
| Start-up | Warm — inherits framing you provide cheaply | Cold — knows nothing, needs the context file |
| Observability | Tracked by your harness | Needs its own monitor; can die silently |
| Independence | Same model family, correlated blind spots | Genuinely different eyes |
| Best for | Work needing deep context; when external agents are out of quota | Preserving session budget; independent review |

**Which source to use is the user's call, not yours.** The two spend different
budgets — one burns the session the user is paying for right now, the other burns
a CLI quota that may be reserved for something else. Picking silently spends
resources on their behalf.

## First time a project needs a subagent — confirm

If the project has **no history of using subagents** (no team file, or no subagent
entry in it) and the work calls for one, **stop and ask** before dispatching:

- Subagent inside this session, or an external agent?
- If a subagent: which kind/model?
- What role — writing code, reviewing, or investigating?

Then **record the answer in the team file** so this is asked once, not every time.
When the team file already answers it, follow it silently; only come back to the
user when the situation falls outside what's recorded (a new role, or the recorded
choice is out of quota).

## The team file

`docs/team.md` in the project — assignments belong to the project
(this project writes code with one model, the next may not), while
[the roster](../orchestrating-executors/references/executor-roster.md) holds what exists on this machine and
how to invoke it. Different lifetimes, different files.

```markdown
# Đội hình dự án <tên>

## Phân công
| Vai | Ai | Model | Ghi chú |
|-----|-----|-------|---------|
| Viết plan chi tiết | <agent> | <model> | <vì sao chọn> |
| Executor chính | <agent> | <model> | |
| Việc nhỏ, cơ học | <agent> | <model> | |
| Phản biện | <agent> | <model> | khác agent đã viết mã |

## Năng lực quan sát được
| Agent | Làm tốt | Đã hỏng ở đâu | Cỡ trần | Lần dùng gần nhất |
|-------|---------|---------------|---------|-------------------|
| <agent> | <việc + bằng chứng> | <sự cố + bằng chứng> | <S/M/L + bằng chứng> | <ngày / phase> |

## Tạm dừng
| Agent | Dừng từ | Lỗi gặp phải | Thử lại từ |
|-------|---------|--------------|------------|
| <agent> | <YYYY-MM-DD HH:MM> | <lỗi + bằng chứng, vd: hết quota, reset 23:00> | <YYYY-MM-DD HH:MM> \| Đến khi được yêu cầu |

## Chưa quyết
- <vai chưa có ai đảm nhiệm — phải hỏi user khi công việc cần tới>
```

**Record both wins and failures, each with evidence.** "Handled the aggregation
engine, 11 tasks, 491 tests green" and "went silent 15 minutes holding a pipe on a
DB script" are both assignments-relevant. Judgments without evidence decay into
prejudice, and you will either over-trust an agent that got lucky once or refuse
one that failed for a reason you've since fixed.

## Two axes: how hard, and how long

What an agent can do has two independent axes. *Làm tốt* records **how hard** — the
kinds of work it gets right. *Cỡ trần* records **how long** — the largest task it
has finished in one run without stopping. An agent can be sharp on short hard
tasks and still run out halfway through a long one; another lasts all day on
mechanical work. Matching only on difficulty hands the long task to the sharp
agent, which stops at step 3 of 5.

Task size is measured from the plan, not felt:

| Cỡ | Dấu hiệu |
|----|----------|
| S | 1–2 file, một bước, một lần chạy test |
| M | vài file, một mối quan tâm, 2–3 bước |
| L | nhiều file hoặc nhiều tầng, 4–6 bước |
| XL | lớn hơn L — gần như luôn phải chia |

- **Cỡ trần is the largest size finished in one run**, with evidence ("T7, 6 file,
  4 bước, xong một mạch"). An agent with no evidence yet starts at **M**; the
  ceiling rises only when it finishes a larger task, and drops when it stops
  mid-task (next section).
- Hard limits of the tool itself — a timeout, a prompt-length cap, a web chat's
  context — live in the roster. The team file holds what was observed in this
  project.

Update it when a phase ends, and whenever an agent surprises you in either
direction. An assignment table nobody maintains sends the next phase's work to
whoever happened to be listed first.

## Pausing an agent, not dropping it

An agent that hit a problem is paused **until a time**, not crossed off. A failure
recorded with no way back quietly shrinks the team to whoever has not had a bad
day yet.

When an agent fails, first decide which kind of failure it is:

- **The agent can't do this kind of work** — wrong output on a class of task,
  repeated, with evidence → *Đã hỏng ở đâu*, for that kind of work only. It stays
  available for everything else. Not a pause.
- **The task was longer than the agent lasts** — it did the early steps right and
  stopped partway (went silent, ran out of context, ended with the rest undone),
  and quota was checked and is not the cause → lower its *Cỡ trần* to the size it
  actually finished, with the evidence. Not a pause, and not a mark against the
  kind of work. The remainder goes out as a continuation task (see *Continuation
  task* under Dispatching One Task).
- **Something outside the work blocks it right now** — quota, rate limit, provider
  outage, an expired login, a broken CLI version, network → a row in *Tạm dừng*:
  when it stopped, the error you saw, and when to try again.

Estimate the retry time from what the error tells you: a quota's reset time when
the roster or the error states it; otherwise your best guess for that kind of
failure (an outage: an hour or two; a rate limit: minutes). When nothing you can
see will clear it on its own — a login, a payment, an install only the user can
do — write `Đến khi được yêu cầu`, and tell the user what it is waiting on.

When assigning, a paused agent whose retry time has passed is available again.
Its next real task is the retry — no separate probe; run the roster's quota check
first if there is one. It works → delete the row. It fails the same way → a new
row with a longer wait. Rows that are cleared get deleted, not archived: the file
is re-read at every assignment, and history already lives in git.

## Quota Management

Quota is a resource you allocate across a phase, not a thing you check once.

- **Silent exhaustion is the classic trap.** An agent out of quota often runs,
  prints a line of preamble, exits 0 with near-empty output — indistinguishable
  from "ran but did nothing" until you look for the work it didn't do. The roster
  documents each agent's quota-check command; run it rather than inferring from
  behavior.
- **Check before dispatching heavy or parallel work**, and re-check after a
  suspiciously fast or empty result.
- **Know the reset windows.** An agent that resets in a few hours is worth waiting
  for; one on a weekly window must be spent deliberately.
- **Budget by role.** Reviews are token-heavy and repeat over rounds; a converging
  review loop can cost more than the implementation did. Don't spend the reviewer's
  quota on implementation you could route elsewhere.
- When an agent goes quiet mid-task, **check quota before debugging the task** —
  it's the cheaper hypothesis.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll just assign it, quota is probably fine" | Check first. Silent quota failure looks exactly like "did nothing". |
| "Everything else is out of quota — I'll spin up a subagent" | That spends the user's current session instead. If the project has no subagent history, ask which kind and for what role. |
| "The user won't care which agent does this" | They pay for it, in different budgets. Silent substitution spends their resources for them. |
| "It failed last time, I'll leave it out" | Check *Tạm dừng*. Past its retry time, it is back on the team — the next task is the retry. |
| "I remember this agent is bad at that" | Check the team file. If the memory isn't recorded with evidence, it's prejudice — and the reason it failed may already be fixed. |
