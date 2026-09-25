#!/usr/bin/env bash
# Script-level tests for the CrewMarshal hooks. Run: bash hooks/tests/run.sh
# These prove the scripts' logic only; a real session is still needed to prove
# the harness calls them (see README, "Hooks").
set -u
HOOKS="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
check() { # name, expected substring ('' = expect empty output), actual
  if [ -z "$2" ]; then [ -z "$3" ] && echo "ok   $1" || { echo "FAIL $1: expected no output, got: $3"; fail=1; }
  else case "$3" in *"$2"*) echo "ok   $1";; *) echo "FAIL $1: expected '$2', got: $3"; fail=1;; esac; fi
}
dispatch() { printf '%s' "$1" | python3 "$HOOKS/dispatch_gate.py"; }
pointer() { printf '{"cwd":"%s","stop_hook_active":%s}' "$1" "${2:-false}" | python3 "$HOOKS/pointer_gate.py"; }

# --- dispatch_gate ---
check "foreground codex exec reminded" 'additionalContext' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"codex exec --cd . \"do it\""}}')"
check "background codex exec: no reminder" '' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"codex exec \"do it\"","run_in_background":true}}')"
check "unrelated command allowed" '' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"git status"}}')"
check "agy foreground reminded" 'additionalContext' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"agy -c --prompt=\"read file t.md\""}}')"
check "word containing agy allowed" '' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"ls stagy"}}')"
check "grep for agy allowed" '' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"grep agy notes.md"}}')"
check "cd then codex exec reminded" 'additionalContext' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"cd /x && timeout 600 codex exec \"go\""}}')"
check "foreground claude -p (lane run) reminded" 'additionalContext' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"cd ../x.lanes/a && claude -p \"lane\" < /dev/null"}}')"
check "claude --version allowed" '' "$(dispatch '{"tool_name":"Bash","tool_input":{"command":"claude --version"}}')"
check "malformed input fails open" '' "$(printf 'not json' | python3 "$HOOKS/dispatch_gate.py")"

# --- pointer_gate ---
repo="$(mktemp -d)"
git -C "$repo" init -q && git -C "$repo" config user.email t@t && git -C "$repo" config user.name t
mkdir -p "$repo/docs/superpowers" && echo s > "$repo/docs/superpowers/STATUS.md"
git -C "$repo" add -A && git -C "$repo" commit -qm pointer
c() { echo "$1" > "$repo/f$1" && git -C "$repo" add -A && git -C "$repo" commit -qm "c$1"; }
c 1; c 2
check "2 commits behind: no nudge" '' "$(pointer "$repo")"
c 3
check "3 commits behind: nudge" '"block"' "$(pointer "$repo")"
check "same HEAD: no second nudge" '' "$(pointer "$repo")"
c 4
check "stop_hook_active: never block" '' "$(pointer "$repo" true)"
check "new HEAD: nudge again" '"block"' "$(pointer "$repo")"
c 5; echo s2 > "$repo/docs/superpowers/STATUS.md"
check "pointer being edited: no nudge" '' "$(pointer "$repo")"
git -C "$repo" add -A && git -C "$repo" commit -qm "pointer update"
check "pointer just committed: no nudge" '' "$(pointer "$repo")"
git -C "$repo" checkout -qb lane/billing; c 6; c 7; c 8
check "lane branch: no nudge" '' "$(pointer "$repo")"
lane() { printf '{"cwd":"%s","tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$repo" "$1" | python3 "$HOOKS/lane_commons_gate.py"; }
check "lane edits docs/superpowers: reminded" 'additionalContext' "$(lane docs/superpowers/STATUS.md)"
check "lane edits own code: no reminder" '' "$(lane services/billing/a.py)"
check "lane edits absolute docs path: reminded" 'additionalContext' "$(lane "$repo/docs/superpowers/team.md")"
git -C "$repo" checkout -q -
check "main edits docs/superpowers: no reminder" '' "$(lane docs/superpowers/STATUS.md)"
ws="$(mktemp -d)"; mkdir -p "$ws/docs/superpowers" "$ws/api"; git -C "$ws/api" init -q
envlane() { printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$ws/api" "$1" | CREWMARSHAL_LANE=billing CREWMARSHAL_PROJECT_ROOT="$ws" python3 "$HOOKS/lane_commons_gate.py"; }
check "workspace lane edits root docs: reminded" 'lane billing' "$(envlane "$ws/docs/superpowers/team.md")"
check "workspace lane edits root docs/team.md: reminded" 'lane billing' "$(envlane "$ws/docs/team.md")"
check "workspace lane edits root docs/lessons/: reminded" 'lane billing' "$(envlane "$ws/docs/lessons/x.md")"
check "workspace lane edits other root docs: no reminder" '' "$(envlane "$ws/docs/billing-guide.md")"
check "workspace lane edits its repo: no reminder" '' "$(envlane "$ws/api/src/a.py")"
check "workspace lane edits docs-lookalike: no reminder" '' "$(envlane "$ws/docs/superpowers-old/x.md")"
c 9; c 10; c 11
check "lane env: pointer gate silent" '' "$(printf '{"cwd":"%s","stop_hook_active":false}' "$repo" | CREWMARSHAL_LANE=billing python3 "$HOOKS/pointer_gate.py")"
check "same repo without lane env: nudge" '"block"' "$(pointer "$repo")"
rm -rf "$ws"
check "lane gate malformed input fails open" '' "$(printf 'x' | python3 "$HOOKS/lane_commons_gate.py")"
new="$(mktemp -d)"; git -C "$new" init -q && git -C "$new" config user.email t@t && git -C "$new" config user.name t
mkdir -p "$new/docs" && echo s > "$new/docs/STATUS.md" && git -C "$new" add -A && git -C "$new" commit -qm pointer
for i in 1 2 3; do echo $i > "$new/f$i" && git -C "$new" add -A && git -C "$new" commit -qm "c$i"; done
check "pointer at docs/STATUS.md: nudge" 'docs/STATUS.md' "$(pointer "$new")"
rm -rf "$new"
nop="$(mktemp -d)"; git -C "$nop" init -q
check "project without pointer: no nudge" '' "$(pointer "$nop")"
check "not a git repo: fails open" '' "$(pointer "$(mktemp -d)")"
rm -rf "$repo" "$nop"

# --- watch_lane_run (multi-lane-coordination) ---
WATCH="$HOOKS/../skills/multi-lane-coordination/scripts/watch_lane_run.py"
run="$(mktemp)"
cat > "$run" <<'JSONL'
Warning: no stdin data received in 3s, proceeding without it.
{"type":"system","subtype":"init"}
{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_read_input_tokens":90000,"cache_creation_input_tokens":5000}}}
{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_read_input_tokens":160000,"cache_creation_input_tokens":0}}}
{"type":"assistant","message":{"usage":{"input_tokens":10,"cache_read_input_tokens":170000,"cache_creation_input_tokens":0}}}
{"type":"system","subtype":"compact_boundary"}
{"type":"result","subtype":"success","num_turns":7}
JSONL
out="$(python3 "$WATCH" "$run" 150000)"
check "watch: context crossing reported" 'context 160010' "$out"
check "watch: context reported once" '' "$(printf '%s' "$out" | grep -c '^context' | grep -v '^1$')"
check "watch: compaction reported" 'compacted' "$out"
check "watch: end reported" 'ended success turns=7' "$out"
check "watch: below threshold, no context line" '' "$(python3 "$WATCH" "$run" 999999 | grep '^context')"
rm -f "$run"

exit $fail
