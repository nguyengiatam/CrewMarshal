# CrewMarshal

A plugin packaging a **coordination discipline for multi-agent delivery**. The
coordinating agent sizes each request to just enough process, designs, and hands
one task at a time to subagents or external coding agents (agy, Codex, kiro,
opencode, …), then verifies every result on the real code. Short shared project
files — profile, working agreement, executor context, pointer, lessons — carry
context across agents and sessions, so nothing is retyped and a fresh session
resumes cheaply. Projects with several services can split into lanes, each with
its own coordinator.

Installs on **Claude Code** and **Codex**. It stands on its own, and works alongside
[superpowers](https://github.com/obra/superpowers) when that is installed.
The hooks need `python3`.

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
  steps directly; every CrewMarshal skill works standalone.
- **No verified notification channel yet.** `orchestrating-executors` requires
  every dispatch to run in the background with a monitor that notifies the
  coordinator. On Codex that channel is unverified, so a dispatch there does not
  meet the contract — the skill says so and uses the project's allowed fallback
  or asks, instead of polling silently.
- **No hooks.** The hooks below are Claude Code only; on Codex the skills
  carry the same rules without the reminders.

### Maintainer note

The version appears in **three** files and they must match:
`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and
`.codex-plugin/plugin.json`. Validate the Codex side with the `plugin-creator`
skill's `validate_plugin.py`. A repo-local pre-commit check refuses a commit
when they differ — enable it once per clone with `git config core.hooksPath .githooks`.
Hook tests: `bash hooks/tests/run.sh`.

## Getting started

Bring a request as usual. On a new project, `concept-briefing` asks a few
questions to lock the project profile and tiers the request;
`project-working-agreement` asks once how the work should run (stop after each
task or continue, parallel or sequential executors, what each role may decide).
Both answers are saved, so later sessions and executors reuse them instead of
asking again. For a map of the whole workflow, invoke `using-crewmarshal`.

Before the first dispatch, check `skills/orchestrating-executors/references/executor-roster.md`:
it describes the author's machine (see [Porting](#porting-to-another-environment)).

## Files in your project

Everything CrewMarshal keeps lives in the project's `docs/`, short enough to load
cheaply:

| File | Holds |
|------|-------|
| `STATUS.md` | The pointer: current state + next action |
| `system-profile.md` | Who uses it, where it's heading, what wins a trade-off |
| `working-agreement.md` | How the work runs; loaded at every session start |
| `team.md` | Agents in use, what each has proven, who is paused |
| `executor-context.md` | Conventions every handoff points at |
| `lessons/` | Lessons indexed by code area and work type |
| `specs/`, `plans/` | Specs and plans (unless the working agreement says elsewhere) |

Multi-lane projects add `.crewmarshal/` beside `docs/`. Projects set up by earlier
versions may keep these under `docs/superpowers/`; the hooks look in both.

The session-start, cache-warm and context hooks stay inert until
`docs/working-agreement.md` exists, and the pointer reminder until `docs/STATUS.md`
does.

## Hooks (Claude Code)

Reminders at points the agent cannot skip past. None refuses anything; all fail
open if something goes wrong.

| Hook | When | What |
|------|------|------|
| `session_context.py` (SessionStart) | Every session start, including after `/clear` and compaction, in a project with `docs/working-agreement.md` (or `docs/superpowers/working-agreement.md`) at the project root (`CREWMARSHAL_PROJECT_ROOT` in a lane run) | Loads the working agreement into context so its rules are known before the first task. Claude Code caps injected context at 10,000 characters; a longer agreement is cut at the last heading that fits and the agent is told which line to read on from. |
| `dispatch_gate.py` (PreToolUse, Bash) | An external executor is launched in the foreground (patterns in `hooks/dispatch-commands.txt`) | Adds one reminder: a real dispatch belongs in the background with a monitor. The command still runs — testing an executor or checking quota is fine. |
| `pointer_gate.py` (Stop) | HEAD is 3+ commits past the last commit touching the pointer (`docs/STATUS.md`, or `docs/superpowers/STATUS.md` in projects set up by earlier versions), and the pointer has no pending edit | Holds the end of the turn once and asks for a pointer update. At most once per HEAD; inert in projects without that file and in lane sessions. Claude Code labels this "Stop hook error" — that is its name for any Stop hook that holds a turn. |
| `warm_gate.py` (Stop) | A turn ends with background runs still out (a background Bash command or async agent with no completion notification yet) and no warm-up timer armed in that turn (ScheduleWakeup, CronCreate, Monitor, a background `sleep N` or `keep_warm.py wait`, or a `keep_warm.py set` that found its waiter running), in a project with a working agreement | Holds the end of the turn once and asks, per `keeping-cache-warm`, to move the session's one timer before the cache TTL. Reads the session transcript; never holds twice in a row. |
| `context_gate.py` (Stop) | The session's context (last main-thread call's input in the transcript) passes the fresh-session threshold: the number on the working-agreement line naming it (`Ngưỡng chuyển phiên: ✓ **400k**`, or `fresh session` / `session reset`), else 300k | Holds the end of the turn once and asks, per `pointer-handoff`, to hand over at a clean point — write the pointer, then open the next session in a new window if the agreement allows it (`Tự chuyển phiên`), else suggest one — or say what is still open. Again only at each further 100k; inert without a working agreement. |
| `lane_commons_gate.py` (PreToolUse, Edit/Write) | In a multi-lane lane session (`CREWMARSHAL_LANE` set by the Chief, or a `lane/*` branch), an edit to the Chief's documents in the project root's `docs/` (pointer, profile, agreement, team, executor context, lessons, specs, plans) — even from another repo of the workspace | Adds one reminder: shared project documents belong to the Chief; ask through the outbox. Inert outside lane sessions. |

## Skills

Listed in the order the arc uses them.

| Skill | Purpose |
|-------|---------|
| `using-crewmarshal` | Map of the workflow arc and where it meets superpowers. |
| **Session and context** | |
| `pointer-handoff` | One short pointer file per project: current state + next action. Read on resume, written before the session ends. |
| `lessons-ledger` | Lessons indexed by code area and work type, so only the relevant ones load; project-wide ones move into the executor context file. |
| `project-working-agreement` | One file of working rules — cadence, parallel or sequential, one coordinator or lanes, what each role may decide, plan detail, commit/language — asked once, reused everywhere. |
| **Design** | |
| `concept-briefing` | Locks a user-confirmed project profile, tiers each request and routes it to just enough process — including a phased roadmap for layered work. |
| `mapping-user-flows` | A user-confirmed UX flow (journeys, surfaces with their states, what each reads and sends) before BE or FE is designed — frontend in the repo or not — so the BE contract comes from the journey. |
| `planning-for-delegation` | The gate a plan passes before the first dispatch: spec/plan altitude, the plan-detail convention, nine structural checks, and an assignment table in waves picked from the team file. |
| **Delegation** | |
| `managing-workforce` | The team file: who does what, proven capability, task size vs agent ceiling, paused agents, quota; a new source of labor is confirmed with the user. |
| `executor-context` | One fixed context file, so handoffs point at it instead of retyping conventions. |
| `writing-handoffs` | The handoff prompt: stands on its own, says what to achieve not how, continues unfinished work as a continuation. |
| `orchestrating-executors` | Roles, one-task checkpoints, background dispatch with a monitor (no polling), a freed agent gets the next ready task in the same turn, parallel isolation. |
| `keeping-cache-warm` | While runs are out: one warm-up timer per session, re-armed by moving a deadline file (`scripts/keep_warm.py`) rather than relaunched. |
| **Verification** | |
| `checkpoint-verification` | Refuses green tests as proof; inspects the call-site and drives the real runtime path. |
| `convention-commit-gate` | Centralized enums, no magic literals, the project's commit style. |
| `adversarial-review-to-go` | External reviewer locked to the altitude of a spec, plan or diff; a diff converges to GO, a spec or plan until a round leaves fewer than 5 mostly-low findings; every finding re-verified. |
| **Scale** | |
| `multi-lane-coordination` | Several services: a Chief owns design, contracts, integration and the user; each lane coordinator owns one service, headless or in its own terminal window, always from a fresh session. Only when the working agreement opts in. |

## The Arc

The arc is **elastic** — `concept-briefing` tiers each request and the tier decides
which steps run. Below is the full T2/T3 path:

```
pointer-handoff (resume) → lessons-ledger (what applies here?)
  → concept-briefing → project-working-agreement (cadence + execution mode + role rules)
  → mapping-user-flows (user business flows)
  → brainstorming (SP) → writing-plans (SP)
  → planning-for-delegation (gate the plan before anyone is dispatched)
  → per task, in a loop:
      managing-workforce (who) → writing-handoffs (prompt, pointing at executor-context)
      → orchestrating-executors (background dispatch + monitor; keeping-cache-warm while out)
      → checkpoint-verification → convention-commit-gate
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

Executor command syntax is NOT baked into the skills. Two files hold everything
machine-specific; edit them together for your agents, and the skills stay unchanged:

- `skills/orchestrating-executors/references/executor-roster.md` — how to invoke,
  check quota for, and monitor each executor. As shipped it describes the
  author's machine (agy, Codex, kiro-cli, opencode); treat it as an example.
- `hooks/dispatch-commands.txt` — the command patterns `dispatch_gate.py`
  recognizes as an executor launch.

## Relationship to superpowers

CrewMarshal does not depend on superpowers. When superpowers is installed, its
brainstorm / plan / finish skills cover those bookends; without it, those steps are
done directly. Every CrewMarshal skill works standalone,
which is how they run on Codex.
