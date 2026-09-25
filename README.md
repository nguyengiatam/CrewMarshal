# CrewMarshal

A plugin packaging a **multi-agent delivery discipline**: the coordinating agent
architects and reviews while external coding agents (agy, Codex, kiro, opencode,
…) implement — under adversarial review-to-GO and real-runtime verification.

Installs on **Claude Code** and **Codex**. On Claude Code it extends
[superpowers](https://github.com/obra/superpowers) rather than replacing it.

## Install — Claude Code

From GitHub (recommended):

```
/plugin marketplace add https://github.com/nguyengiatam/CrewMarshal.git
/plugin install crewmarshal@crewmarshal-marketplace
```

`crewmarshal-marketplace` is the marketplace name (from `.claude-plugin/marketplace.json`);
the `@<marketplace>` qualifier is **required** on install. `crewmarshal` is the
plugin name.

The GitHub `owner/repo` shorthand also works, but it clones over SSH by default —
set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` to clone over HTTPS instead:

```
/plugin marketplace add nguyengiatam/CrewMarshal
```

From a local clone (no network):

```
/plugin marketplace add /path/to/CrewMarshal
/plugin install crewmarshal@crewmarshal-marketplace
```

Update to the latest pushed version any time with `/plugin marketplace update crewmarshal-marketplace`.

## Install — Codex

```
codex plugin marketplace add https://github.com/nguyengiatam/CrewMarshal.git
codex plugin add crewmarshal@crewmarshal-marketplace
```

A local clone works the same way — pass the path instead of the URL. Verify with
`codex plugin list`; the entry should read `installed, enabled`.

Codex reads `.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`;
Claude Code reads the two files under `.claude-plugin/`. Both point at the same
`skills/` directory, so the skills themselves are identical on either harness.

Remove with `codex plugin remove crewmarshal` and
`codex plugin marketplace remove crewmarshal-marketplace`.

### What differs on Codex

- **No superpowers.** `brainstorming`, `writing-plans`, and
  `finishing-a-development-branch` are Claude Code plugins. On Codex, do those
  steps directly; the eleven delta skills work standalone.
- **No verified notification channel yet.** `orchestrating-executors` requires
  every dispatch to run in the background with a monitor that notifies the
  coordinator. On Codex that channel is unverified, so a dispatch there does not
  meet the contract — the skill says so and uses the project's allowed fallback
  or asks, instead of polling silently.
- **No hooks.** The two hooks below are Claude Code only; on Codex the skills
  carry the same rules without the reminders.

### Maintainer note

The version appears in **three** files and they must match:
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and
`.codex-plugin/plugin.json`. Validate the Codex side with the `plugin-creator`
skill's `validate_plugin.py`. A repo-local pre-commit check refuses a commit
when they differ — enable it once per clone with `git config core.hooksPath .githooks`.
Hook tests: `bash hooks/tests/run.sh`.

## Hooks (Claude Code)

Three reminders at points the agent cannot skip past. Neither refuses anything;
both fail open if something goes wrong.

| Hook | When | What |
|------|------|------|
| `dispatch_gate.py` (PreToolUse, Bash) | An external executor is launched in the foreground (patterns in `hooks/dispatch-commands.txt`) | Adds one reminder: a real dispatch belongs in the background with a monitor. The command still runs — testing an executor or checking quota is fine. |
| `pointer_gate.py` (Stop) | HEAD is 3+ commits past the last commit touching `docs/superpowers/STATUS.md`, and the pointer has no pending edit | Holds the end of the turn once and asks for a pointer update. At most once per HEAD; inert in projects without that file and in lane sessions. Claude Code labels this "Stop hook error" — that is its name for any Stop hook that holds a turn. |
| `lane_commons_gate.py` (PreToolUse, Edit/Write) | In a multi-lane lane session (`CREWMARSHAL_LANE` set by the Chief, or a `lane/*` branch), an edit under the project root's `docs/superpowers/` — even from another repo of the workspace | Adds one reminder: shared project documents belong to the Chief; ask through the outbox. Inert outside lane sessions. |

## Skills

| Skill | Purpose |
|-------|---------|
| `pointer-handoff` | One short pointer file per project: current state + next action. Read on resume, written before the session ends. |
| `lessons-ledger` | Per-project lessons indexed by code area and work type, so only the relevant ones load; project-wide ones get crystallized into the executor context file. |
| `concept-briefing` | Locks a user-confirmed system profile, tiers each request, and routes it to the right amount of process — including a phased roadmap for layered work. |
| `project-working-agreement` | One project file of working rules — stop after each task or continue, what each role may decide, plan detail, commit/language — asked once, reused by every session and executor. |
| `using-crewmarshal` | Index/map of the workflow arc and where it meets superpowers. |
| `orchestrating-executors` | Workforce management: who is on the team and what they proved, subagent-vs-external choice, quota, one-task handoffs, async dispatch with a monitor (no polling), parallel isolation, checkpoint protocol. |
| `executor-context` | One fixed context file the coordinator maintains, so handoffs point at it instead of retyping conventions. |
| `checkpoint-verification` | Refuses green tests as proof; inspect call-site + drive the real runtime path. |
| `planning-for-delegation` | The gate a plan passes before the first dispatch: spec/plan altitude, the project's plan-detail convention (asked once, kept in the working agreement), nine structural checks, an assignment table (who does each task, grouped into parallel waves, picked from the team file by capability), phase gates. |
| `multi-lane-coordination` | For projects with several services: a Chief keeps design, contracts, integration and the only conversation with the user; headless lane coordinators each own one service, always start from a fresh session and their lane pointer, and stop at a clean point to reset. Only when the working agreement opts in. |
| `adversarial-review-to-go` | External adversarial reviewer locked to the altitude of what it reviews — spec, plan or diff; every finding carries 1-2 fix directions (a direction, never a patch) at that altitude; converging rounds to GO on a diff, one round on a document; re-verify every finding. |
| `convention-commit-gate` | Centralized enums, no magic literals, project commit style. |

## The Arc

The arc is **elastic** — `concept-briefing` tiers each request and the tier decides
which steps run. Below is the full T2/T3 path:

```
pointer-handoff (resume) → lessons-ledger (what applies here?)
  → concept-briefing → project-working-agreement (cadence + execution mode + role rules)
  → brainstorming (SP) → writing-plans (SP)
  → planning-for-delegation (gate the plan before anyone is dispatched)
  → orchestrating-executors ⇄ checkpoint-verification ⇄ convention-commit-gate  (per task)
  → adversarial-review-to-go
  → finishing-a-development-branch (SP)
  → pointer-handoff (record state + next action)
```

| Tier | What runs |
|------|-----------|
| **T0** mechanical (typo, constant, rename) | Do it directly → `convention-commit-gate` |
| **T1** one obvious way, 1–3 files | No spec, no plan file → executor → verification gates |
| **T2** ≥2 approaches, or touches schema/API | Full arc, incl. the plan gate; adversarial review only for risky areas |
| **T3** money/settled figures, broken boundaries | Full arc, nothing skipped |

Skipping steps is always the user's call — asked once, batched. Verification gates
are never skipped when real code gets written.

Large layered work gets a **roadmap** first: phases from foundation upward, each
standing on the last, with detailed plans written per phase rather than in advance.

## Porting to another environment

Executor command syntax is NOT baked into the skills. It lives in
`skills/orchestrating-executors/references/executor-roster.md`. Edit that one
file for your machine/agents; the skills stay unchanged.

## Relationship to superpowers

On Claude Code, CrewMarshal is a delta: it assumes superpowers is installed for the
brainstorm / plan / finish bookends. The eleven delta skills also work standalone,
which is how they run on Codex.
