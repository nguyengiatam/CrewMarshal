---
name: mapping-user-flows
description: Use after concept-briefing and before the backend or frontend is designed, whenever a T2/T3 request adds or changes what a user sees and does — drafts a user-confirmed UX flow (journeys from entry to outcome, every screen with its states, what each screen reads and sends, branches and failures) in text plus simple diagrams, so the BE contract and the FE screens are both derived from one confirmed source instead of each side guessing.
---

# Mapping User Flows

Backend and frontend designed side by side, without a flow, each fill the gaps
their own way: the API follows the data model instead of what the screens need,
and the screens invent their own empty, error and no-permission states. A UX flow
fixes the gap **once, upstream of both**: what the user does, step by step, what
each screen shows and asks for, and where it can go wrong.

It is a design document like a roadmap, a spec or a plan — **Claude drafts it, the
user confirms it**, it lives beside the specs, and the designs downstream point at
it rather than restate it.

## When It Runs

| Request | Flow |
|---------|------|
| T2/T3 and adds a screen, a journey, or changes what a user does | **yes** — before the design step |
| T0/T1, cosmetic UI change, copy change | no |
| Backend-only, no visible change for any user | no |
| A finished design exists (Figma or similar, per the profile's *design source*) | read it and write only what it leaves out — states, failures, data per screen — never redraw it |

The profile must already carry the Frontend/UI or App lens (`concept-briefing`).
When it doesn't, add that lens first; who uses it and on what device decide flows.

File: `docs/specs/YYYY-MM-DD-<topic>-ux-flow.md` (or the spec folder the working
agreement names), same `<topic>` slug as the concept brief.
Template: [references/ux-flow-template.md](references/ux-flow-template.md).

## The Altitude

A flow sits **above** the spec. It speaks the user's and the domain's language.

| Belongs in the flow | Does not |
|---------------------|----------|
| Actors and their goal | Endpoints, HTTP verbs, tables, queues |
| Journeys: entry → steps → outcome | Component names, layout, pixels, colors |
| Screens and the states each can be in | Framework, state library, routing scheme |
| What a screen **reads** and **sends**, in domain words ("đơn hàng của tôi, mới nhất trước") | Field types, DTO shapes, pagination mechanics |
| Branches, failures, permission rules the user meets | Retry policy, caching, error codes |

A line from the right column means the flow has dropped an altitude: cut it and
leave it to the spec, where the BE and FE designs make those choices.

## What the Flow Must Satisfy

Write it in whatever order works; before it goes to the user it must hold:

1. **Every journey reaches an outcome** the user can see — success, or a named
   stop (cancelled, rejected, no permission). No journey ends at "…".
2. **Every screen is reachable** from at least one journey, and every journey step
   lands on a named screen. An orphan screen or a step with no screen is a gap.
3. **Every screen lists the states it can actually be in** — loading, empty,
   error, no permission, partial data — only those that can happen, and what the
   user sees and can do in each.
4. **Every action names both results:** what the user sees when it works and when
   it fails, including the failure the user can fix (bad input) and the one they
   cannot (system down, someone else changed it first).
5. **Every screen names what it reads and what it sends**, in domain words. This
   column is where the BE contract will come from — a screen that reads "the
   order" without saying which order, or for whom, will become a guessed API.
6. **Business rules are the user's, never inferred.** Who may do what, limits,
   what happens on conflict — draft it if the repo shows it (mark `~`), otherwise
   mark `CHƯA CHỐT` and ask. A guessed rule here becomes code on both sides.
7. **Text is the source; diagrams follow it.** One simple diagram per journey (or
   one overview when journeys are few), Mermaid `flowchart` or plain ASCII — boxes
   are screens, arrows are user actions and outcomes. A diagram that disagrees
   with the text is a defect; keep diagrams small enough to read without zooming.

## Confirming It

Same rule as the profile: **silence is not consent.** Send the user one batched
message — the journeys in a few lines each, the diagram, and every `CHƯA CHỐT` or
`~` business rule as a direct question. Lines they can't decide stay `CHƯA CHỐT`;
the whole file is `ĐÃ CHỐT` only when no line it depends on is open. Commit it.

T3, or a flow touching money, permissions or data other users see: run
`adversarial-review-to-go` on it with the **spec** template, adding to the
prohibitions everything in the right column above. Same stop rule as a spec.

## Handoff to the Rest of the Arc

- **The design step** (`superpowers:brainstorming` on Claude Code) starts from the
  confirmed flow. BE and FE specs cite journeys and screens by their ids (`J1`,
  `S3`) instead of restating them.
- **The BE contract** is derived from the *reads/sends* of every screen — each one
  maps to something the contract provides, or the spec says why not. This is the
  shape the contract task in `planning-for-delegation` lays down before fan-out.
- **The plan** traces both ways: every BE/FE task names the screens or journeys it
  serves, and every screen is covered by some task.
- **Multi-lane:** the flow belongs to the Chief, confirmed before contracts are
  frozen; lanes read it, never edit it (`multi-lane-coordination`).
- **Roadmap:** at roadmap level name the journeys and which phase delivers each —
  nothing more. A phase's detailed flow is written when that phase starts, same
  rule as its plan.

## Keeping It Current

The flow changes when the user's journey changes — new requirement, a review
finding, an executor reporting that a screen cannot get what it needs. Update the
flow **first**, mark the changed lines `~` until the user confirms, then
re-check the specs and plan tasks that cite them. A spec or a screen that quietly
diverges from the flow is how BE and FE stop fitting.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Flows are obvious, I'll go straight to the API" | The API then serves the data model, not the screens. Draft the flow; a short one is fine. |
| "I'll add the endpoints right here while I'm at it" | That's the spec's altitude. Name what the screen reads; the BE design picks the endpoint. |
| "Happy path is enough for now" | Empty, error and no-permission states are exactly what each side invents differently. |
| "The user didn't object to the rules" | Business rules are confirmed or `CHƯA CHỐT`. Silence is not consent. |
| "There's a Figma, I'll redraw it as a flow" | Point at the design; write only what it leaves out. |
| "Executor found the screen needs more data — I'll patch the spec" | Update the flow first, then the spec and the tasks citing it. |
| "Let me map every phase's flows up front" | Never analyze ahead. Name the journeys in the roadmap; detail per phase. |
