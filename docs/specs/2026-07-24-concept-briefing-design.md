# Concept Briefing (Conductor upgrade) — Design

**Goal:** Add a new Conductor skill, `concept-briefing`, that captures a short
**scale/calibration signal** before design work starts, so
`superpowers:brainstorming` and the rest of the Conductor arc calibrate their
depth (how many approaches, how much scrutiny, how tight the checkpoint loop)
to the actual size and business-criticality of the request — instead of
treating every request the same.

## Problem

Conductor's arc currently starts at `superpowers:brainstorming`, which begins
designing immediately. Nothing upstream tells brainstorming (or, later,
`orchestrating-executors`) whether the work in front of it is a one-line
mechanical fix or a business-critical subsystem redesign. Without that
signal:

- Brainstorming may ask too many/too few clarifying questions, or propose too
  many/too few approaches, relative to what the request actually needs.
- Executor handoff prompts (in `orchestrating-executors`) carry no explicit
  calibration, so an executor may over-engineer a trivial change or
  under-scrutinize a critical one.
- There is no persisted record of "how big did we think this was", so if the
  estimate turns out wrong mid-project, nothing prompts a recalibration.

## Scope

**In scope:** a single new signal — estimated scale, business-criticality,
and the requester's expressed expectations — captured in one short file
*before* brainstorming begins, then referenced through the rest of the arc.

**Explicitly out of scope for this file** (these already live in the spec/plan
produced by `superpowers:brainstorming`/`writing-plans` and are NOT
duplicated here):
- Shared vocabulary/naming conventions.
- Architecture decisions and their rationale.
- Task dependency mapping.

These three were considered during design and rejected for this artifact
because they don't exist yet at the point this file is created (before
brainstorming), and merging them in later would make this file a second copy
of the spec/plan — the design deliberately keeps this file narrow.

## Placement in the Arc

`concept-briefing` is the **first step**, before `superpowers:brainstorming`:

```
conductor:concept-briefing       → lock scale/calibration BEFORE design starts
superpowers:brainstorming        → design (informed by the brief)
superpowers:writing-plans        → plan (inherits calibration)
   ┌─ orchestrating-executors    → hand off ONE task (every prompt cites the brief's calibration)
   │     checkpoint-verification
   │     convention-commit-gate
   └─  (if actual scope diverges mid-project → update the brief, recalibrate)
adversarial-review-to-go
superpowers:finishing-a-development-branch
```

Rationale for standing before brainstorming rather than after writing-plans:
design itself should be calibrated (fewer questions/approaches for small
mechanical work; deeper decomposition and scrutiny for large/critical work),
not just the executor handoff that happens after design is already done.

## File Content

Location: `docs/superpowers/plans/YYYY-MM-DD-<topic>-concept-brief.md` — same
directory and same `<topic>` slug convention as the plan that will eventually
be written, so the pair is easy to find. The slug is chosen by this skill (it
runs before brainstorming/writing-plans exist to choose one); brainstorming
and writing-plans should reuse the same slug for their own spec/plan
filenames.

Template:

```markdown
# Concept Brief: <topic>

**Quy mô ước lượng:** nhỏ / vừa / lớn — <1 câu lý do>
**Mức độ nghiệp vụ:** cơ học/ít rủi ro | có nghiệp vụ | business-critical — <1 câu lý do>
**Kỳ vọng người yêu cầu:** <tín hiệu rõ từ request gốc, hoặc "không nói rõ → mặc định theo quy mô">

## Hàm ý hiệu chỉnh
- Brainstorming: <số lượng approach nên đề xuất / có cần tách sub-project không / độ sâu câu hỏi>
- Orchestrating-executors: <mức giám sát/checkpoint cần thiết, phần nào Claude nên tự viết thay vì delegate>
- Adversarial-review-to-go: <có cần nhiều vòng review hội tụ không>
```

The file stays in Vietnamese for the calibration prose (matching this
project's working language), same as other Conductor-adjacent docs in this
codebase.

## Creation Mechanism

- Claude asks **1–3 lightweight questions** — noticeably shallower than
  brainstorming's clarifying-question loop — or skips questions entirely and
  states the calibration in one line when the request is unambiguous (e.g.
  "fix typo in README" → trivially small, no questions, move on immediately).
- This step must not itself become bureaucratic overhead on small requests —
  that would violate the exact principle it exists to protect.
- Confirmation is a single line to the user (e.g. "Quy mô: vừa, nghiệp vụ
  trung bình. Đúng chưa?"), not a full spec-review gate. This is a triage
  step, not a design decision.

## Update Mechanism

When Claude discovers, at any later checkpoint (during
`checkpoint-verification`, `adversarial-review-to-go`, or mid-plan
discovery), that the actual scope/criticality diverges materially from the
brief's estimate (e.g. a task assumed mechanical turns out to require a
larger redesign), Claude updates `concept-brief.md` itself — no user prompt
required — and subsequent handoff prompts cite the updated calibration.

## Integration with Existing Skills

- **`orchestrating-executors`** (`skills/orchestrating-executors/SKILL.md`):
  add a bullet to the "Handoff Prompt Checklist" requiring the calibration
  line (scale + business-criticality + the orchestrating-executors-specific
  implication) be quoted or referenced in every executor prompt. If no
  `concept-brief.md` exists (Conductor adopted mid-project), infer the
  calibration inline from the plan's Architecture section or ask the user
  directly — this is a soft fallback, not a hard block.
- **`using-conductor`** (`skills/using-conductor/SKILL.md`): update the arc
  diagram and the "When to Use Which Skill" table to include
  `concept-briefing` as the first row.
- **`README.md`**: add `concept-briefing` to the skills table; update the arc
  diagram shown there.
- **Versioning**: bump `.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` from `0.1.0` to `0.2.0` (new skill
  added).

## Edge Cases

- **Trivial request:** skip questions, state calibration in one line, proceed
  immediately — see Creation Mechanism above.
- **Conductor adopted mid-project (no brief exists):** `orchestrating-executors`
  falls back to inferring calibration from the plan or asking the user; this
  is noted in that skill's checklist, not enforced as a blocking gate.
- **Estimate turns out wrong:** see Update Mechanism above — Claude updates
  the file proactively, not only on user request.
- **Multiple independent subsystems in one request:** the brief's calibration
  should flag this explicitly (e.g. "lớn — có dấu hiệu cần tách sub-project"),
  reinforcing brainstorming's own existing decomposition check rather than
  duplicating it.

## Verification Plan

Since this change is a set of skill/doc files (not application code),
verification is a dogfood dry run: apply `concept-briefing` to a real next
task (in this repo or a consuming project) and confirm:
1. The brief is produced with the right level of brevity for that task's
   actual size.
2. `orchestrating-executors`'s handoff prompts actually quote the calibration
   line once that skill is updated.
3. Nothing in the existing four skills' behavior regresses (their content is
   otherwise unchanged except the noted checklist/table additions).
