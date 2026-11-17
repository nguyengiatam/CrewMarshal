---
name: binding-ui-to-api
description: Use when a frontend is about to be planned against an API — designed alongside it or already existing — and the design shows how screens look but not how they behave (when calls fire, what pending, success and each error do, who may act, what goes stale) — writes a binding table in the FE spec tying every interactive element to a contract operation and its outcome on each result, checks it both ways (every element bound, every operation and error handled, every displayed datum supplied), and for an existing API proves each operation's business meaning from a real call or its source, never from its name.
---

# Binding UI to API

A design shows what a screen looks like. The API says what the server accepts and
returns. Between them sits the behaviour neither one states: what fires the call,
what the screen does while it waits, where the user lands on success, what each
error looks like, whether a forbidden action is hidden or disabled, what other
screen now shows stale data. Left open, the executor decides each of these while
coding — differently per screen, and sometimes against the business rule.

The binding closes that gap **once, in writing, before the plan**: one row per
thing the user can do, tied to the operation it calls and to what the user sees
on every outcome.

## When It Runs

| Situation | Binding |
|-----------|---------|
| T2/T3 frontend work that calls an API — designed in this work or already existing | **yes** — after the FE design step, before `planning-for-delegation` |
| T1: one screen, a few calls, no open behaviour | the rows go straight into the task's handoff; no separate step |
| Static content, no API | no |
| Backend only, client built elsewhere | no — the UX flow and the contract are the client team's input |

Inputs, all confirmed: the UX flow (`mapping-user-flows`), the design (from any
tool — whatever the profile's *design source* names), and the contract — the BE
spec's when the API is designed in this work, the existing API otherwise.

**Where it lives:** a *Ghép UI–API* section of the FE spec — not a document of its
own; the mechanism it records is the FE design's. Template:
[references/binding-template.md](references/binding-template.md).

## Two Altitudes in One Table

Every row mixes two kinds of answer, and they are decided by different people:

- **What the user feels** — the message on a failed save, where they land after
  it succeeds, a forbidden button hidden or greyed out, what happens if someone
  else changed it first. These are business rules. Taken from the design or the
  flow; when neither says, the line goes **back into the flow** as `CHƯA CHỐT`
  and the user decides. Never the coordinator's guess, never the executor's.
- **How it's done** — which operation, refetch or optimistic update, debounce,
  cache invalidation. These are the FE spec's choices; the coordinator makes them.

## What the Binding Must Satisfy

Write it in any order; before the plan is drafted it must hold:

1. **Every interactive element has a row** — every button, field, link, toggle,
   list scroll, filter and sort on the design, plus the implicit ones: opening the
   screen, refreshing, going back, a deep link straight into it.
2. **Every row states its trigger, its pending state and its success** — what
   fires the call; what the user sees and may do while it runs (double submit
   blocked?); what updates on success, *including other surfaces now showing
   stale data*.
3. **Every error the operation can return has a display.** Each error case of the
   contract maps to what the user sees and can do next: inline at the field, a
   message, a redirect, a retry. A generic fallback is allowed only for errors the
   user cannot act on, and is named as such. An unmapped error is the most common
   gap — check it per operation, not per screen.
4. **Every datum the design shows is supplied** — by a named response field, or
   by a stated derivation from fields. A number on the design with no source is a
   gap in the contract, not something the FE computes on a guess.
5. **Every contract operation is used, or the spec says why not.** An unused
   operation often means a flow step the design forgot.
6. **Every rule the UI enforces is also enforced by the API** — permission,
   limits, which state an entity may be changed in. Hiding a button is not
   access control. A rule only the UI enforces is written down as such and goes
   to the user.
7. **Every row traces upward** — to a surface and journey of the flow (`S3`, `J1`)
   and the operation it calls. A row with no surface is UI the flow never asked
   for; a surface with no row is UI nobody will build.

## When the API Already Exists

The API is fixed input, and its **name is not its meaning**. `PUT /orders/{id}`
may only edit the note; `status=active` may include suspended items;
`DELETE` may be a soft delete that keeps the item in a report. A binding built on
names wires the right button to the wrong business action, and every test still
passes against a fake that copied the same assumption.

**Prove each operation the binding uses**, and record the evidence in its row.
Evidence ranks: a real call observed > the BE source > the API docs or schema >
the name. Docs alone are a `~`. What must be proved:

- **Business effect:** what changes, and every side effect — notifications sent,
  stock reserved, other records touched, audit entries.
- **Preconditions:** which states of the entity it accepts, and what it returns
  in the others.
- **Response semantics:** default sort, page size and filters; whether deleted,
  archived or other-tenant data appears; units, time zone, money format and
  rounding.
- **Errors actually returned:** codes and body shape, observed — not the ones the
  docs promise.
- **Scope:** whose data the caller sees and may change with the role the UI runs
  under.
- **Repeat safety:** what a double submit or a retry after a timeout does.

**Calling the real API is safe or it doesn't happen.** Only against a
non-production environment the user named, writes only with test data, never a
mutation on production. No such environment → prove from the source, mark the
rows `~`, and say what stayed unproven.

**Capture what was proved as the contract.** Types (generated from a schema that
matched the observed calls, or written from them) and a fake built from **real
recorded responses, errors included**. This capture is the contract task of
`planning-for-delegation` for an existing API — FE tasks build against it.

**A gap between the flow and the API is the user's decision.** When the API
cannot do what a surface needs — a missing field, a filter, a rule it doesn't
enforce, an operation that does more than the step means — name the gap and the
options with their costs:

- change the API (who owns it, how long);
- work around it in the FE (extra calls, filtering a partial page on the client,
  a rule enforced only in the UI — each with its cost said out loud);
- change the flow.

Record the decision in the row. A silent workaround is a business rule nobody
agreed to.

## Confirming It

The rows the coordinator decided need no sign-off. Everything that went back into
the flow, every unproven operation, every gap, goes to the user in **one batched
message**, together with any open flow lines. Silence is not consent: an open
line stays `CHƯA CHỐT`, and a task whose rows depend on it does not dispatch.

## Handoff to the Rest of the Arc

- **Plan:** each FE task names the binding rows it builds (`B3–B7`); every row is
  covered by a task (`planning-for-delegation`).
- **Handoff:** the rules every FE task shares go once into the context file's UI
  section (`executor-context`); the plan task names its surfaces, frames and
  rows, and the prompt just points at the task (`writing-handoffs`).
- **Fake:** reproduces every error row, not only the success — a fake that cannot
  fail leaves every error display untested.
- **Executor finds a behaviour with no row:** stops and reports; it does not
  decide. The coordinator adds the row — through the flow first if the user would
  feel it — then the task continues.
- **Acceptance** walks the rows on the running UI (`checkpoint-verification`):
  against the fake for each task, against the real API at integration.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The design is complete, just build it" | Designs show states that look nice. Errors, pending, stale data and permissions are rarely drawn. |
| "Show a generic error toast for everything" | Only for errors the user can't act on. Each fixable error needs its own display. |
| "The endpoint is called cancelOrder, it cancels the order" | Prove it: call it, or read it. Name is not meaning. |
| "The docs list the errors" | Docs list the errors someone remembered. Observe the ones it actually returns. |
| "The API lacks the filter, I'll filter on the client" | That's a gap with a cost — partial pages, wrong counts. The user decides. |
| "Hide the button for non-admins and we're safe" | Hiding isn't enforcement. Check the API refuses it too. |
| "I'll test against production quickly, read-only" | Only a non-production environment the user named. |
| "Executor will figure out what happens after save" | That's a business rule. It goes in the row — via the flow if the user feels it. |
| "Let me write a separate binding doc" | It's a section of the FE spec. A separate copy drifts. |
