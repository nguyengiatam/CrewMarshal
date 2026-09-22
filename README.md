# CrewMarshal

A plugin packaging a **multi-agent delivery discipline**: the coordinating agent
architects and reviews while external coding agents (agy, Codex, kiro, opencode,
…) implement — under adversarial review-to-GO and real-runtime verification.

Installs on **Claude Code** and **Codex**. On Claude Code it extends
[superpowers](https://github.com/obra/superpowers) rather than replacing it.

## Install — Claude Code

From GitHub (recommended):

```
/plugin marketplace add https://github.com/nguyengiatam/conductor.git
/plugin install crewmarshal@crewmarshal-marketplace
```

`crewmarshal-marketplace` is the marketplace name (from `.claude-plugin/marketplace.json`);
the `@<marketplace>` qualifier is **required** on install. `crewmarshal` is the
plugin name.

The GitHub `owner/repo` shorthand also works, but it clones over SSH by default —
set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` to clone over HTTPS instead:

```
/plugin marketplace add nguyengiatam/conductor
```

From a local clone (no network):

```
/plugin marketplace add /path/to/conductor
/plugin install crewmarshal@crewmarshal-marketplace
```

Update to the latest pushed version any time with `/plugin marketplace update crewmarshal-marketplace`.

## Install — Codex

```
codex plugin marketplace add https://github.com/nguyengiatam/conductor.git
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
  steps directly; the nine delta skills work standalone.
- **No verified notification channel yet.** `orchestrating-executors` requires
  every dispatch to run in the background with a monitor that notifies the
  coordinator. On Codex that channel is unverified, so a dispatch there does not
  meet the contract — the skill says so and uses the project's allowed fallback
  or asks, instead of polling silently.

### Maintainer note

The version appears in **three** files and they must match:
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and
`.codex-plugin/plugin.json`. Validate the Codex side with the `plugin-creator`
skill's `validate_plugin.py`.

## Skills

| Skill | Purpose |
|-------|---------|
| `pointer-handoff` | One short pointer file per project: current state + next action. Read on resume, written before the session ends. |
| `lessons-ledger` | Per-project lessons indexed by code area and work type, so only the relevant ones load; project-wide ones get crystallized into the executor context file. |
| `concept-briefing` | Locks a user-confirmed system profile, tiers each request, and routes it to the right amount of process — including a phased roadmap for layered work. |
| `using-crewmarshal` | Index/map of the workflow arc and where it meets superpowers. |
| `orchestrating-executors` | Workforce management: who is on the team and what they proved, subagent-vs-external choice, quota, one-task handoffs, async dispatch with a monitor (no polling), parallel isolation, checkpoint protocol. |
| `executor-context` | One fixed context file the coordinator maintains, so handoffs point at it instead of retyping conventions. |
| `checkpoint-verification` | Refuses green tests as proof; inspect call-site + drive the real runtime path. |
| `planning-for-delegation` | The gate a plan passes before the first dispatch: spec/plan altitude, the project's plan-detail convention (asked once, kept in the profile), nine structural checks, [E]/[C], phase gates. |
| `adversarial-review-to-go` | External adversarial reviewer locked to the altitude of what it reviews — spec, plan or diff; every finding carries 1-2 fix directions (a direction, never a patch) at that altitude; converging rounds to GO on a diff, one round on a document; re-verify every finding. |
| `convention-commit-gate` | Centralized enums, no magic literals, project commit style. |

## The Arc

The arc is **elastic** — `concept-briefing` tiers each request and the tier decides
which steps run. Below is the full T2/T3 path:

```
pointer-handoff (resume) → lessons-ledger (what applies here?)
  → concept-briefing → brainstorming (SP) → writing-plans (SP)
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
brainstorm / plan / finish bookends. The nine delta skills also work standalone,
which is how they run on Codex.
