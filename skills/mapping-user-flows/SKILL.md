---
name: mapping-user-flows
description: Use after concept-briefing and before the backend or frontend is designed, whenever a T2/T3 request adds or changes a business flow a user goes through — with or without a frontend in this project — drafts a user-confirmed UX flow (journeys from entry to outcome, every surface the user meets with its states, what each surface reads and sends, branches and failures) in text plus simple diagrams, so the BE contract and any FE are both derived from one confirmed source instead of each side guessing.
---

# Mapping User Flows

Without a flow, the API follows the data model instead of what the user's
journey needs, and whoever builds the client invents the empty, error and
no-permission cases. A UX flow fixes the gap **once, upstream of both**: what the
user does, step by step, what each surface shows and asks for, and where it can
go wrong.

**A frontend is not the trigger — a user's business flow is.** A backend whose
client is built elsewhere (a mobile team, a partner, a chatbot) still serves a
user journey, and that journey is exactly what its API must be designed from.
A *surface* is wherever the user meets the system: a screen, a client app's call,
a notification, an email, a bot reply.

It is a design document like a roadmap, a spec or a plan — **Claude drafts it, the
user confirms it**, it lives beside the specs, and the designs downstream point at
it rather than restate it.

## When It Runs

| Request | Flow |
|---------|------|
| T2/T3 and adds or changes a business flow a user goes through — on any surface, frontend in this repo or not | **yes** — before the design step |
| T0/T1, cosmetic UI change, copy change | no |
| No user journey changes: internal refactor, infrastructure, a job no user triggers or sees | no |
| A finished design exists (Figma or similar, per the profile's *design source*) | read it and write only what it leaves out — states, failures, data per screen — never redraw it |

The profile's core — who uses it, in what situation — must be confirmed
(`concept-briefing`); it decides the actors. When the user meets a UI, its lens
(device, design source) belongs in the profile too.

File: `docs/specs/YYYY-MM-DD-<topic>-ux-flow.md` (or the spec folder the working
agreement names), same `<topic>` slug as the concept brief.
Template: [references/ux-flow-template.md](references/ux-flow-template.md).

## The Altitude

A flow sits **above** the spec. It speaks the user's and the domain's language.

| Belongs in the flow | Does not |
|---------------------|----------|
| Actors and their goal | Endpoints, HTTP verbs, tables, queues |
| Journeys: entry → steps → outcome | Component names, layout, pixels, colors |
| Surfaces and the states each can be in | Framework, state library, routing scheme |
| What a surface **reads** and **sends**, in domain words ("đơn hàng của tôi, mới nhất trước") | Field types, DTO shapes, pagination mechanics |
| Branches, failures, permission rules the user meets | Retry policy, caching, error codes |

A line from the right column means the flow has dropped an altitude: cut it and
leave it to the spec, where the BE and FE designs make those choices.

## What the Flow Must Satisfy

Write it in whatever order works; before it goes to the user it must hold:

1. **Every journey reaches an outcome** the user can see — success, or a named
   stop (cancelled, rejected, no permission). No journey ends at "…".
2. **Every surface is reachable** from at least one journey, and every journey
   step lands on a named surface. An orphan surface or a step with none is a gap.
3. **Every surface lists the states it can actually be in** — loading, empty,
   error, no permission, partial data — only those that can happen, and what the
   user sees and can do in each.
4. **Every action names both results:** what the user sees when it works and when
   it fails, including the failure the user can fix (bad input) and the one they
   cannot (system down, someone else changed it first).
5. **Every surface names what it reads and what it sends**, in domain words. This
   column is where the BE contract will come from — a surface that reads "the
   order" without saying which order, or for whom, will become a guessed API.
6. **Business rules are the user's, never inferred.** Who may do what, limits,
   what happens on conflict — draft it if the repo shows it (mark `~`), otherwise
   mark `CHƯA CHỐT` and ask. A guessed rule here becomes code on both sides.
7. **Text is the source; diagrams follow it.** One simple diagram per journey (or
   one overview when journeys are few), Mermaid `flowchart` or plain ASCII — boxes
   are surfaces, arrows are user actions and outcomes. A diagram that disagrees
   with the text is a defect; keep diagrams small enough to read without zooming.

## Confirming It

Same rule as the profile: **silence is not consent.** Send the user one batched
message — the journeys in a few lines each, the diagram, and every `CHƯA CHỐT` or
`~` business rule as a direct question. Lines they can't decide stay `CHƯA CHỐT`;
the whole file is `ĐÃ CHỐT` only when no line it depends on is open. Commit it.

T3, or a flow touching money, permissions or data other users see: run
`adversarial-review-to-go` on it with the **spec** template, adding to the
prohibitions everything in the right column above. Same stop rule as a spec.

## The Backend Flow Lives in the Spec

How the system gets the user their outcome — the states an entity moves through,
what moves it when no user does (a timer, an event, an external system), the
asynchronous steps, what is compensated when a step fails, what must always hold
— is a **design decision**, and decisions are the spec's. It gets no third
document: two places describing one flow drift apart, which is the very gap the
UX flow exists to close.

- **The flow stops at what the user meets.** "Đơn chuyển sang *đang giao*, user
  nhận thông báo" belongs here; what the system does to get there does not.
- **The BE spec carries a system-flow section** whenever the work has multi-step,
  asynchronous or stateful processing: states and transitions, non-user
  triggers, failure and compensation, invariants — as results that must hold,
  not mechanism. It cites the journeys (`J1`) it serves and never retells them.
- **A rule the user can feel stays in the flow.** "Hủy được trước khi giao" is a
  business rule the user confirms here, even though the system flow enforces it;
  the spec points at the rule instead of restating it. A rule found while writing
  the spec that the user would feel goes back into the flow, to be confirmed.

## Handoff to the Rest of the Arc

- **The design step** (`superpowers:brainstorming` on Claude Code) starts from the
  confirmed flow. BE and FE specs cite journeys and surfaces by their ids (`J1`,
  `S3`) instead of restating them.
- **The BE contract** is derived from the *reads/sends* of every surface — each one
  maps to something the contract provides, or the spec says why not. This is the
  shape the contract task in `planning-for-delegation` lays down before fan-out.
- **The plan** traces both ways: every BE/FE task names the surfaces or journeys it
  serves, and every surface is covered by some task.
- **Multi-lane:** the flow belongs to the Chief, confirmed before contracts are
  frozen; lanes read it, never edit it (`multi-lane-coordination`).
- **Roadmap:** at roadmap level name the journeys and which phase delivers each —
  nothing more. A phase's detailed flow is written when that phase starts, same
  rule as its plan.

## Keeping It Current

The flow changes when the user's journey changes — new requirement, a review
finding, an executor reporting that a surface cannot get what it needs. Update the
flow **first**, mark the changed lines `~` until the user confirms, then
re-check the specs and plan tasks that cite them. A spec or a surface that quietly
diverges from the flow is how BE and FE stop fitting.

## Red Flags

| Thought | Reality |
|---------|---------|
| "No frontend here, so no flow" | The client is elsewhere; the journey isn't. The API is designed from it. |
| "Flows are obvious, I'll go straight to the API" | The API then serves the data model, not the journey. Draft the flow; a short one is fine. |
| "I'll add the endpoints right here while I'm at it" | That's the spec's altitude. Name what the surface reads; the BE design picks the endpoint. |
| "Happy path is enough for now" | Empty, error and no-permission states are exactly what each side invents differently. |
| "The user didn't object to the rules" | Business rules are confirmed or `CHƯA CHỐT`. Silence is not consent. |
| "There's a Figma, I'll redraw it as a flow" | Point at the design; write only what it leaves out. |
| "Executor found the surface needs more data — I'll patch the spec" | Update the flow first, then the spec and the tasks citing it. |
| "I'll add a separate backend-flow doc too" | It's the spec's system-flow section. A third document is a second copy that drifts. |
| "The spec needs a cancel rule — I'll decide it there" | A rule the user feels goes into the flow and gets confirmed; the spec points at it. |
| "Let me map every phase's flows up front" | Never analyze ahead. Name the journeys in the roadmap; detail per phase. |
