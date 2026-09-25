# Concept Briefing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a sixth Conductor skill, `concept-briefing`, that captures a short scale/business-criticality calibration signal before `superpowers:brainstorming` starts, and wire that signal into `orchestrating-executors`'s handoff prompts and the `using-conductor`/README arc maps.

**Architecture:** One new self-contained skill file (`skills/concept-briefing/SKILL.md`, no reference subfile — the whole thing is short enough to live in one file) that stands as the first step of the arc, ahead of `superpowers:brainstorming`. Three existing files get small, additive edits to reference it: `orchestrating-executors`'s Handoff Prompt Checklist gains one bullet, and `using-conductor`/`README.md` gain the new step in their arc diagrams and skill tables. No existing skill's core content changes.

**Tech Stack:** Markdown skill file with YAML frontmatter; JSON plugin manifest version bump; git for commits. Validation is parsing frontmatter/JSON with `python3`, same as the rest of this repo — no other tooling.

## Global Constraints

- Bump `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` version from `0.1.0` to `0.2.0` (new skill added).
- New skill lives at `skills/concept-briefing/SKILL.md`; frontmatter `name` MUST equal the directory name (`concept-briefing`), matching every other skill in this repo.
- Frontmatter has exactly two keys: `name` and `description` (one line, third-person, states WHEN to use the skill) — same convention as all five existing skills.
- The SKILL.md instructional prose is in English, matching the existing four delta skills. The one exception: the `concept-brief.md` **template's field labels** (`Quy mô ước lượng`, `Mức độ nghiệp vụ`, etc.) stay in Vietnamese — this mirrors the working language of the projects Conductor is used on, the same exception already granted to the roster reference file for its Vietnamese notes.
- `concept-briefing` must NOT capture shared vocabulary, architecture rationale, or task dependency mapping — those stay in the spec/plan produced by `superpowers:brainstorming`/`writing-plans`, unduplicated. This is a hard scope boundary from the design, not a style preference.
- Do not touch `checkpoint-verification.md`, `adversarial-review-to-go.md`, or `convention-commit-gate.md` — the design's integration points are `orchestrating-executors`, `using-conductor`, and `README.md` only.
- Commit style inside the `conductor` repo: one-line message, no `Co-Authored-By` footer (existing repo convention).

---

## File Structure

```
/mnt/c/workspace/conductor/
├── .claude-plugin/
│   ├── plugin.json                       # MODIFY: version 0.1.0 → 0.2.0
│   └── marketplace.json                  # MODIFY: version 0.1.0 → 0.2.0
├── skills/
│   ├── concept-briefing/
│   │   └── SKILL.md                       # CREATE: scale/calibration signal, first step of the arc
│   ├── using-conductor/
│   │   └── SKILL.md                       # MODIFY: arc diagram + table gain concept-briefing row
│   ├── orchestrating-executors/
│   │   └── SKILL.md                       # MODIFY: Handoff Prompt Checklist gains one bullet
│   ├── adversarial-review-to-go/          # unchanged
│   ├── checkpoint-verification/           # unchanged
│   └── convention-commit-gate/            # unchanged
└── README.md                             # MODIFY: skills table + arc diagram
```

**Responsibilities:**
- `concept-briefing` — the new entry point; produces `docs/superpowers/plans/YYYY-MM-DD-<topic>-concept-brief.md` in whatever project it's used on.
- `orchestrating-executors` — now requires every handoff prompt to cite the brief's calibration line.
- `using-conductor` / `README.md` — human/agent-facing maps; both must show the new first step.

---

### Task 1: Write the `concept-briefing` skill

**Files:**
- Create: `/mnt/c/workspace/conductor/skills/concept-briefing/SKILL.md`

**Interfaces:**
- Consumes: nothing upstream — it is the new entry point, running before `superpowers:brainstorming`.
- Produces: a `concept-brief.md` file (path convention documented in the skill body) whose calibration line is consumed by `superpowers:brainstorming` (informally, by the agent reading it) and, formally, quoted in every `orchestrating-executors` handoff prompt (Task 2 wires that reference).

- [ ] **Step 1: Write `skills/concept-briefing/SKILL.md`**

````markdown
---
name: concept-briefing
description: Use as the first step before superpowers:brainstorming on any new request — captures a short scale/business-criticality signal so design depth and executor handoffs calibrate to the actual size of the work instead of treating every request the same.
---

# Concept Briefing

Before design begins, capture one thing: how big is this, really? A short,
persisted calibration signal — scale, business-criticality, and what the
requester actually expects — that `superpowers:brainstorming` and
`orchestrating-executors` both read so their depth matches the work, not a
fixed default.

This is deliberately narrow. It does NOT capture shared vocabulary,
architecture decisions, or task dependencies — those already live in the
spec/plan that `superpowers:brainstorming`/`writing-plans` produce, later.
Duplicating them here would just create a second, staler copy.

## What Goes In the Brief

- **Quy mô ước lượng:** nhỏ / vừa / lớn, with one reason.
- **Mức độ nghiệp vụ:** cơ học/ít rủi ro | có nghiệp vụ | business-critical, with one reason.
- **Kỳ vọng người yêu cầu:** any expectation the request itself signals (fast/minimal vs thorough/robust); if silent, default to what the scale line implies.
- **Hàm ý hiệu chỉnh** for each downstream stage: how many approaches / how deep the questions for brainstorming; how tight the checkpoint loop and how much Claude should write itself for orchestrating-executors; whether adversarial-review-to-go needs multiple convergence rounds.

## Creating It

Ask 1–3 lightweight questions — shallower than brainstorming's own
clarifying-question loop — or skip questions entirely and write the
one-line calibration yourself when the request is unambiguous (e.g. "fix a
typo in the README" needs zero questions). This step must never become
overhead on small requests; that would defeat its own purpose.

Confirm with a single line to the user (e.g. "Quy mô: vừa, nghiệp vụ trung
bình. Đúng chưa?") — not a spec-review gate. This is triage, not a design
decision.

## File Location

`docs/superpowers/plans/YYYY-MM-DD-<topic>-concept-brief.md`. Pick `<topic>`
yourself — brainstorming/writing-plans haven't run yet, so no slug exists.
When they do run, reuse the same slug for the spec/plan filenames so the
trio is easy to find together.

## Updating It

When a later checkpoint (`checkpoint-verification`, `adversarial-review-to-go`,
or a mid-plan discovery) reveals the actual scope diverges from this
estimate — a task assumed mechanical turns out to need a real redesign —
update this file yourself, without waiting to be asked, then carry the new
calibration into subsequent handoff prompts.

## Handoff to the Rest of the Arc

- `superpowers:brainstorming` reads the calibration to decide how many
  approaches to propose and how much to probe before presenting a design.
- `orchestrating-executors` quotes the calibration line in every handoff
  prompt (see its Handoff Prompt Checklist). If no brief exists (Conductor
  adopted mid-project), infer calibration from the plan's Architecture
  section or ask the user directly — a soft fallback, not a blocker.

## Red Flags

| Thought | Reality |
|---------|---------|
| "This is obviously small, I'll just start brainstorming" | Say so in one line and move on — but write the line. An unstated assumption is what drifts. |
| "I'll capture the vocab/architecture/dependency map here too" | Out of scope. Those belong in the spec/plan, not this file — don't duplicate them. |
| "The estimate was wrong, I'll just proceed" | Update the brief first. A stale calibration miscalibrates every handoff after it. |
| "Small task, but let me ask 5 questions to be safe" | Match the questions to the scale. Over-asking on small work is the failure mode this skill exists to prevent. |
````

- [ ] **Step 2: Validate frontmatter**

Run:
```bash
cd /mnt/c/workspace/conductor && python3 - <<'PY'
import re
t = open('skills/concept-briefing/SKILL.md', encoding='utf-8').read()
m = re.match(r'^---\n(.*?)\n---\n', t, re.S)
name = re.search(r'^name:\s*(\S+)', m.group(1), re.M) if m else None
desc = re.search(r'^description:\s*\S', m.group(1), re.M) if m else None
ok = bool(m and name and name.group(1) == 'concept-briefing' and desc)
print('OK' if ok else 'FAIL')
PY
```
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd /mnt/c/workspace/conductor && git add skills/concept-briefing/SKILL.md && git commit -m "add concept-briefing skill"
```

---

### Task 2: Wire `concept-briefing` into `orchestrating-executors`'s handoff checklist

**Files:**
- Modify: `/mnt/c/workspace/conductor/skills/orchestrating-executors/SKILL.md:39-46` (the "Handoff Prompt Checklist" section)

**Interfaces:**
- Consumes: the `concept-brief.md` calibration line, per Task 1's "Handoff to the Rest of the Arc" section.
- Produces: no new symbols — this is a checklist addition to an existing prose skill.

- [ ] **Step 1: Insert the calibration bullet**

The current section (lines 39-46) reads:

```markdown
## Handoff Prompt Checklist

Every executor prompt includes:
- The single task and its acceptance criteria (copy from the plan).
- Current HEAD SHA and the baseline test count/state.
- The instruction to reconcile against real code/enums before hardcoding anything (executors catch plan errors this way — when one stops to ask, take it seriously).
- The convention requirements from `convention-commit-gate` for any new code.
- Repo safety rules (branch, ports/DB isolation if parallel, no killing processes by pattern).
```

Replace it with:

```markdown
## Handoff Prompt Checklist

Every executor prompt includes:
- The single task and its acceptance criteria (copy from the plan).
- Current HEAD SHA and the baseline test count/state.
- The instruction to reconcile against real code/enums before hardcoding anything (executors catch plan errors this way — when one stops to ask, take it seriously).
- The convention requirements from `convention-commit-gate` for any new code.
- The calibration line from `concept-briefing`'s `concept-brief.md` (scale + business-criticality + its orchestrating-executors implication), so the executor knows how much rigor this task actually needs. If no `concept-brief.md` exists, infer calibration from the plan's Architecture section or ask the user directly.
- Repo safety rules (branch, ports/DB isolation if parallel, no killing processes by pattern).
```

- [ ] **Step 2: Verify the edit landed**

Run:
```bash
cd /mnt/c/workspace/conductor && grep -n "concept-briefing" skills/orchestrating-executors/SKILL.md
```
Expected: one line of output — the new bullet, containing `concept-briefing`.

- [ ] **Step 3: Commit**

```bash
cd /mnt/c/workspace/conductor && git add skills/orchestrating-executors/SKILL.md && git commit -m "orchestrating-executors: cite concept-briefing calibration in handoff prompts"
```

---

### Task 3: Add `concept-briefing` to the `using-conductor` and README arc maps

**Files:**
- Modify: `/mnt/c/workspace/conductor/skills/using-conductor/SKILL.md:14-27` (arc diagram), `:29-39` (table), `:52-53` (closing paragraph)
- Modify: `/mnt/c/workspace/conductor/README.md:38-46` (skills table), `:48-55` (arc diagram)

**Interfaces:**
- Consumes: nothing new — pure documentation propagation of Task 1's skill.
- Produces: nothing new — no code interfaces; this task keeps the two arc-facing docs in sync with the skill set.

- [ ] **Step 1: Update `using-conductor`'s arc diagram (lines 14-27)**

Current:

```markdown
## The Arc

```
superpowers:brainstorming        → design the change
superpowers:writing-plans        → task-by-task plan with real code

   ┌─ orchestrating-executors    → pick executor (roster), hand off ONE task
   │     checkpoint-verification  → inspect call-site + drive real runtime path
   │     convention-commit-gate   → enums, no magic literals, commit style
   └─  (loop per task; fix or re-dispatch if a gate fails)

adversarial-review-to-go         → external reviewer, converge findings to GO
superpowers:finishing-a-development-branch → merge / PR / cleanup
```
```

Replace with:

```markdown
## The Arc

```
conductor:concept-briefing       → lock scale/calibration BEFORE design starts
superpowers:brainstorming        → design the change (informed by the brief)
superpowers:writing-plans        → task-by-task plan with real code

   ┌─ orchestrating-executors    → pick executor (roster), hand off ONE task
   │     checkpoint-verification  → inspect call-site + drive real runtime path
   │     convention-commit-gate   → enums, no magic literals, commit style
   └─  (loop per task; fix or re-dispatch if a gate fails; recalibrate if scope diverges)

adversarial-review-to-go         → external reviewer, converge findings to GO
superpowers:finishing-a-development-branch → merge / PR / cleanup
```
```

- [ ] **Step 2: Add a table row (lines 29-39)**

Current:

```markdown
## When to Use Which Skill

| Situation | Skill |
|-----------|-------|
| Deciding what to build | `superpowers:brainstorming` |
| Turning a spec into tasks | `superpowers:writing-plans` |
| Handing a task to an external agent | `orchestrating-executors` |
| Accepting an executor's result | `checkpoint-verification` |
| Committing at a checkpoint | `convention-commit-gate` |
| Hardening a risky area before merge | `adversarial-review-to-go` |
| Integrating the finished branch | `superpowers:finishing-a-development-branch` |
```

Replace with:

```markdown
## When to Use Which Skill

| Situation | Skill |
|-----------|-------|
| Calibrating scale/criticality before design | `concept-briefing` |
| Deciding what to build | `superpowers:brainstorming` |
| Turning a spec into tasks | `superpowers:writing-plans` |
| Handing a task to an external agent | `orchestrating-executors` |
| Accepting an executor's result | `checkpoint-verification` |
| Committing at a checkpoint | `convention-commit-gate` |
| Hardening a risky area before merge | `adversarial-review-to-go` |
| Integrating the finished branch | `superpowers:finishing-a-development-branch` |
```

- [ ] **Step 3: Update the closing paragraph (lines 52-53)**

Current:

```markdown
If superpowers is not installed, the four delta skills still work standalone —
you just lose the brainstorm/plan/finish bookends this map references.
```

Replace with:

```markdown
If superpowers is not installed, the five delta skills still work standalone —
you just lose the brainstorm/plan/finish bookends this map references.
```

- [ ] **Step 4: Update `README.md`'s skills table (lines 38-46)**

Current:

```markdown
## Skills

| Skill | Purpose |
|-------|---------|
| `using-conductor` | Index/map of the workflow arc and where it meets superpowers. |
| `orchestrating-executors` | Reviewer/executor split, per-task checkpoint protocol, quota-aware executor selection. |
| `checkpoint-verification` | Refuses green tests as proof; inspect call-site + drive the real runtime path. |
| `adversarial-review-to-go` | External adversarial reviewer in converging rounds to GO; re-verify every finding. |
| `convention-commit-gate` | Centralized enums, no magic literals, project commit style. |
```

Replace with:

```markdown
## Skills

| Skill | Purpose |
|-------|---------|
| `concept-briefing` | Captures a scale/business-criticality signal before design starts, so depth calibrates to the work. |
| `using-conductor` | Index/map of the workflow arc and where it meets superpowers. |
| `orchestrating-executors` | Reviewer/executor split, per-task checkpoint protocol, quota-aware executor selection. |
| `checkpoint-verification` | Refuses green tests as proof; inspect call-site + drive the real runtime path. |
| `adversarial-review-to-go` | External adversarial reviewer in converging rounds to GO; re-verify every finding. |
| `convention-commit-gate` | Centralized enums, no magic literals, project commit style. |
```

- [ ] **Step 5: Update `README.md`'s arc diagram (lines 48-55)**

Current:

```markdown
## The Arc

```
brainstorming (SP) → writing-plans (SP)
  → orchestrating-executors ⇄ checkpoint-verification ⇄ convention-commit-gate  (per task)
  → adversarial-review-to-go
  → finishing-a-development-branch (SP)
```
```

Replace with:

```markdown
## The Arc

```
concept-briefing → brainstorming (SP) → writing-plans (SP)
  → orchestrating-executors ⇄ checkpoint-verification ⇄ convention-commit-gate  (per task)
  → adversarial-review-to-go
  → finishing-a-development-branch (SP)
```
```

- [ ] **Step 6: Verify both files mention `concept-briefing`**

Run:
```bash
cd /mnt/c/workspace/conductor && grep -c "concept-briefing" skills/using-conductor/SKILL.md README.md
```
Expected:
```
skills/using-conductor/SKILL.md:2
README.md:2
```
(each file has exactly two mentions: one in its arc diagram, one in its skill table.)

- [ ] **Step 7: Commit**

```bash
cd /mnt/c/workspace/conductor && git add skills/using-conductor/SKILL.md README.md && git commit -m "add concept-briefing to the arc maps (using-conductor + README)"
```

---

### Task 4: Bump plugin version and run final validation

**Files:**
- Modify: `/mnt/c/workspace/conductor/.claude-plugin/plugin.json`
- Modify: `/mnt/c/workspace/conductor/.claude-plugin/marketplace.json`

**Interfaces:**
- Consumes: the finished six-skill set from Tasks 1-3.
- Produces: a version-bumped, fully-validated plugin. Final task — nothing downstream depends on this one.

- [ ] **Step 1: Bump `plugin.json` version**

In `/mnt/c/workspace/conductor/.claude-plugin/plugin.json`, change:

```json
  "version": "0.1.0",
```

to:

```json
  "version": "0.2.0",
```

- [ ] **Step 2: Bump `marketplace.json` version**

In `/mnt/c/workspace/conductor/.claude-plugin/marketplace.json`, change the nested plugin entry's version:

```json
      "version": "0.1.0",
```

to:

```json
      "version": "0.2.0",
```

- [ ] **Step 3: Run full plugin validation**

Run:
```bash
cd /mnt/c/workspace/conductor && python3 - <<'PY'
import json,re,glob,sys
ok=True
pj=json.load(open('.claude-plugin/plugin.json'))
mk=json.load(open('.claude-plugin/marketplace.json'))
if pj['name']!='conductor': print('plugin name wrong'); ok=False
if pj['version']!='0.2.0': print('plugin version not bumped'); ok=False
if mk['plugins'][0]['name']!='conductor': print('marketplace plugin name wrong'); ok=False
if mk['plugins'][0]['version']!='0.2.0': print('marketplace version not bumped'); ok=False
names=set()
for f in sorted(glob.glob('skills/*/SKILL.md')):
    d=f.split('/')[1]; t=open(f,encoding='utf-8').read()
    m=re.match(r'^---\n(.*?)\n---\n',t,re.S)
    nm=re.search(r'^name:\s*(\S+)',m.group(1),re.M) if m else None
    ds=re.search(r'^description:\s*\S',m.group(1),re.M) if m else None
    if not(m and nm and nm.group(1)==d and ds): print('BAD SKILL',f); ok=False
    else: names.add(nm.group(1))
expected={'using-conductor','orchestrating-executors','checkpoint-verification','adversarial-review-to-go','convention-commit-gate','concept-briefing'}
if names!=expected: print('skill set mismatch', names^expected); ok=False
print('PLUGIN VALID' if ok else 'PLUGIN INVALID'); sys.exit(0 if ok else 1)
PY
```
Expected: `PLUGIN VALID`

- [ ] **Step 4: Commit**

```bash
cd /mnt/c/workspace/conductor && git add .claude-plugin/plugin.json .claude-plugin/marketplace.json && git commit -m "bump conductor to 0.2.0 for concept-briefing"
```

- [ ] **Step 5 (optional): Update the installed plugin and smoke-test discovery**

```bash
# In Claude Code:
#   /plugin marketplace update conductor-marketplace
# Then confirm concept-briefing appears in the skills listing alongside the other five.
```

---

## Self-Review Notes

- **Spec coverage:** design's "File Content" template → Task 1 Step 1; "Creation Mechanism" → Task 1's "Creating It" section; "Update Mechanism" → Task 1's "Updating It" section; "Integration with Existing Skills" (orchestrating-executors / using-conductor / README) → Tasks 2-3; "Versioning" → Task 4; "Edge Cases" (trivial request, mid-project adoption, wrong estimate, multi-subsystem) → all covered in Task 1's skill body (Creation Mechanism, Handoff fallback, Updating It, Red Flags table). ✓
- **No placeholders:** every step shows the literal before/after text or full file content; no TBD/TODO. ✓
- **Name consistency:** `concept-briefing` used identically as directory name, frontmatter `name`, grep targets, table rows, and the final validator's `expected` set. ✓
- **Scope discipline:** Global Constraints explicitly forbids this skill from absorbing vocabulary/architecture/dependency-map content, matching the design's rejected-scope section — nothing in the tasks reintroduces it. ✓
- **Ordering:** Task 1 (new skill) before Tasks 2-3 (references to it) before Task 4 (version bump + validation), so every grep/reference target exists by the time it's checked. ✓
