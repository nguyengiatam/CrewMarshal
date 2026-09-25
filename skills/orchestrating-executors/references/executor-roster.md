# Executor Roster (machine-specific — edit per environment)

This file is the ONLY machine-specific part of the plugin. Replace its contents
with your own executors when moving to a new environment. The
`orchestrating-executors` skill stays unchanged.

Each executor entry documents: **invoke syntax · quota check · strengths · gotchas.**

> The entries below come from one WSL setup (as of 2026-07). Treat command paths
> and quirks as examples, not universal truth.

## Priority order (when multiple have quota)

1. **agy** (Antigravity CLI) — first choice when it has quota.
2. **Codex** / **kiro** — when they have quota; Codex is the review specialist.
3. **opencode + deepseek** — only when everything else is exhausted; split tasks
   smaller and review harder ("not very smart, control tightly").

Codex is preferred for REVIEW (its strength), not for coding when another
executor is available.

## Always check quota for ALL executors before assigning heavy work

Silent quota exhaustion is the classic trap: the tool runs, prints a line or
two of preamble, exits 0 with near-empty output — looks like "ran but did
nothing." Confirm quota first.

- **agy:** `timeout 300 agy --print --dangerously-skip-permissions "Reply one word: ok"`
  — out of quota prints `Error: Individual quota reached... Resets in Xh`.
  Individual quota resets ~every 4–5h.
- **kiro:** `kiro-cli chat --no-interactive "/usage"` — prints % monthly + daily
  credit and reset date (free; overage disabled, so it hard-stops at zero).
- **Codex:** read latest snapshot
  `ls -t ~/.codex/sessions/2026/*/*/rollout-*.jsonl | head -1` then grep
  `"rate_limits"`; `primary.used_percent` is the WEEKLY window. For fresh
  numbers ping `codex exec --json --skip-git-repo-check "ok"` (cheap) then grep.

## How to monitor each (exit conditions for the dispatch watcher)

`orchestrating-executors` requires every dispatch to run in the background with a
monitor attached at launch. What is actually observable differs per agent and per
coordinator harness — record it here, not in the skill.

On Claude Code the plugin's `hooks/dispatch-commands.txt` lists the launch
patterns for the agents below; a foreground launch gets a reminder. Add a new
agent there when you add it here.

**Notification channel back to the coordinator (per harness):**

- **Claude Code:** run the launch with Bash `run_in_background` — the session is
  re-invoked when the command exits, so the exit *is* the notification. For a
  condition other than exit (new commit, silence threshold), run a watcher script
  the same way, or use the `Monitor` tool. Both work while the coordinator is busy
  and while it has ended its turn.
- **Codex:** no verified channel yet. `codex queue` exists in CLI 0.155.1 (help
  only, delivery not tested) — verify before relying on it. Until then a Codex
  coordinator does not meet the async contract; use the project's allowed fallback
  or ask.

- **Universal:** new commit past the BASE SHA captured at dispatch; any change to
  the files in scope; process exit.
- **agy / opencode:** background job exit; empty output on a multi-step task means
  the prompt form was wrong (see gotchas), not that the work is done.
- **Codex:** a new session/state file appearing is the signal that the job really
  started — **absence of one means it never ran** (typically quota). Do not wait
  for a completion notice that will not come.
- **kiro:** the watcher checks liveness with `kill -0 <pid>`. Silent >5 min with no token spend
  usually means a child process is holding a pipe waiting for EOF — inspect
  children of `kiro-cli-chat` and kill the pipe holder, not the parent by pattern.

## Headless lane coordinators (multi-lane projects only)

Used by `multi-lane-coordination`. Verified on Claude Code 2.1.282, macOS, 2026-09-25.

- **Launch a lane run (Chief, Claude Code):** from the lane's worktree, via Bash
  `run_in_background` — the exit is the Chief's notification:
  `claude -p --output-format stream-json --verbose --max-turns <M> "<lane-run prompt>" < /dev/null > "$LANE/runs/<ts>.jsonl" 2>&1`
  where `$LANE` is `<git-common-dir>/crewmarshal/lanes/<name>`. Always a new
  session — never `--resume` / `--continue`.
- **Permissions:** a headless run cannot answer permission prompts. Give it the
  project's chosen mode (`--permission-mode`, or an allowlist in the project's
  settings) — the working agreement records which; do not pick one silently.
- **Gotcha — stdin:** without `< /dev/null` the CLI waits 3s for stdin and prints a
  warning line into the output.
- **Gotcha — background work dies with the run:** a `run_in_background` task
  started inside a headless run is killed when the run exits (verified: a 40s sleep
  never finished, the run ended at 14s). A `nohup … &` process survives.
- **Watch context size:** each `assistant` event in the stream-json output carries
  `message.usage`; input + cache-read + cache-creation tokens is the run's current
  context. Attach
  `python3 <multi-lane-coordination skill dir>/scripts/watch_lane_run.py "$LANE/runs/<ts>.jsonl" <threshold>`
  as a `Monitor`: it prints `context <n>` once past the threshold (→ write
  `tìm điểm dừng` to the inbox), `compacted` on a `compact_boundary` event (from
  the SDK's message types; not yet observed here), and `ended …` when the run ends.
- **Codex as a lane coordinator:** `codex exec` is the candidate, but its
  stream output, context reporting and survival of detached children are not
  verified yet. Verify before assigning it a lane.

**Executors launched from inside a lane run** are detached, and leave an exit file
the Chief can watch:

```
J="$LANE/jobs"; id=<task-id>
nohup sh -c '<executor command> > "$0/$1.log" 2>&1; echo $? > "$0/$1.exit"' "$J" "$id" >/dev/null 2>&1 &
```

The Chief waits on them with one background Bash command that exits when every
file has landed: `until [ -f "$J/a.exit" ] && [ -f "$J/b.exit" ]; do sleep 15; done`.

## agy (executor — mechanical/docs, general implementation)

- **Invoke:** write the task to a scratch file, then
  `agy -c --prompt="read file <path> and do it"` (run via Bash with
  `dangerouslyDisableSandbox: true`, from the repo cwd, long timeout).
- **Critical:** bind the message with `--prompt=` (the `=` matters). Positional
  message args get swallowed into context and agy goes off researching the flag
  instead of doing the task. `-c` continues the existing project session.
- **Model:** `--model "Claude Sonnet 4.6 (Thinking)"` (or current).
- **Gotcha:** headless `--print` with multi-step tasks is unreliable; prefer
  `-c --prompt=` form. Long inline prompts return empty — hand off via file.
- **Plugin option (Claude Code only):** if the `agy-executor` plugin is installed,
  dispatch via `/agy-executor:exec <task>` (or the `agy-executor:agy-runner`
  subagent) instead of hand-typing the flags above — it builds the command
  correctly and tracks the job. See https://github.com/nguyengiatam/agy-executor.
  On other harnesses, use the raw invocation above.

## Codex (reviewer-first; heavy-logic executor when needed)

- **Invoke (review/impl):**
  `codex exec --cd <dir> --sandbox danger-full-access --skip-git-repo-check "<prompt>"`.
  Do NOT use the companion wrapper for reviews — its token snapshot goes stale.
- **Strength:** concurrency/TOCTOU/crash-gap and migration-on-deploy findings
  that e2e never surfaces. Run review as a converging multi-round loop (see
  `adversarial-review-to-go`); each round ~50–145k tokens.
- **Gotcha (WSL):** the workspace-write sandbox blocks AF_VSOCK and unshare-net
  (docker/psql/e2e fail). Use `danger-full-access`. Avoid bare backticks in
  prompts (host command-substitution fires before Codex sees them).

## kiro-cli + Sonnet 5 (executor)

- **Invoke:** `kiro-cli chat --model claude-sonnet-5 --trust-all-tools --no-interactive "<prompt>"`,
  run as a background Bash job of the main session. Use a NEW session per task
  (resume a specific session only to continue in-progress context).
- **Gotcha — self-kill:** the prompt text lives in argv; forbid killing
  processes by pattern, and never embed a kill command string in the prompt.
- **Gotcha — silent hang (no token spend):** kiro writing a multi-line
  server-start script, or a `node -e` that touches the DB without
  `process.exit(0)`, holds a pipe waiting for EOF and goes silent 15+ min.
  Require single-line background commands ending in `&`, health-check with a
  SEPARATE curl, and `process.exit(0)` in a finally for any DB script. If kiro
  is silent >5 min, inspect children of `kiro-cli-chat` and kill the pipe holder.
- **Env:** `/mnt/c` (NTFS) has no inotify — watch does not reload; restart the
  dev server after edits. Source `.env.local` before e2e.

## opencode + deepseek-v4 (last resort)

- **Invoke:** `opencode run -m opencode/deepseek-v4-flash-free "<msg>"`
  (`-c`/`--session` to continue, `--agent` to pick agent).
- **Discipline:** split tasks smaller, review harder, never hand it a large block.
