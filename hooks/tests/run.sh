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

# --- session_context ---
session() { printf '{"cwd":"%s","source":"startup"}' "$1" | python3 "$HOOKS/session_context.py"; }
wa="$(mktemp -d)"; git -C "$wa" init -q; mkdir -p "$wa/docs/superpowers" "$wa/src"
check "no agreement: nothing loaded" '' "$(session "$wa")"
printf '# Quy ước\n\n## Nhịp\n- ✓ dừng sau mỗi task\n' > "$wa/docs/superpowers/working-agreement.md"
check "old location loaded" 'dừng sau mỗi task' "$(session "$wa")"
check "loaded from a subdirectory" 'dừng sau mỗi task' "$(session "$wa/src")"
printf '# Quy ước\n- ✓ chạy liền mạch\n' > "$wa/docs/working-agreement.md"
check "docs/ wins over old location" 'chạy liền mạch' "$(session "$wa")"
check "short agreement not cut" '' "$(session "$wa" | grep 'Cut to fit')"
python3 - "$wa/docs/working-agreement.md" <<'PY'
import sys
parts = ["# Quy ước\n"] + ["## Mục %d\n%s\n" % (i, "- ✓ quy tắc dài dòng\n" * 60) for i in range(1, 9)]
open(sys.argv[1], "w").write("".join(parts))
PY
big="$(session "$wa")"
check "long agreement: cut and points at the rest" 'Read the rest of' "$big"
check "long agreement: fits the 10k cap" 'ok' "$(printf '%s' "$big" | python3 -c 'import json,sys; c=json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]; print("ok" if len(c)<=10000 else len(c))')"
check "long agreement: cut at a heading" 'ok' "$(printf '%s' "$big" | python3 -c 'import json,sys,re; c=json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"]; n=int(re.search(r"from line (\d+)",c).group(1)); l=open(sys.argv[1]).read().splitlines(); print("ok" if l[n-1].startswith("## ") else l[n-1])' "$wa/docs/working-agreement.md")"
ws="$(mktemp -d)"; mkdir -p "$ws/docs" "$ws/api"; git -C "$ws/api" init -q
echo '- ✓ quy ước workspace' > "$ws/docs/working-agreement.md"
check "lane run reads project root" 'quy ước workspace' "$(printf '{"cwd":"%s"}' "$ws/api" | CREWMARSHAL_PROJECT_ROOT="$ws" python3 "$HOOKS/session_context.py")"
check "session hook malformed input fails open" '' "$(printf 'x' | python3 "$HOOKS/session_context.py")"
rm -rf "$wa" "$ws"

# --- warm_gate ---
wp="$(mktemp -d)"; git -C "$wp" init -q; mkdir -p "$wp/docs"
tr="$wp/t.jsonl"
warm() { printf '{"cwd":"%s","transcript_path":"%s","stop_hook_active":%s}' "$wp" "$tr" "${1:-false}" | python3 "$HOOKS/warm_gate.py"; }
prompt() { printf '{"type":"user","message":{"role":"user","content":"%s"}}\n' "$1" >> "$tr"; }
use() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"%s","name":"%s","input":%s}]}}\n' "$1" "$2" "$3" >> "$tr"; }
result() { printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"%s","content":"ok"}]},"toolUseResult":%s}\n' "$1" "$2" >> "$tr"; }
notify() { printf '{"type":"user","message":{"role":"user","content":"<task-notification>\\n<task-id>%s</task-id>\\n%s</task-notification>"}}\n' "$1" "$2" >> "$tr"; }
prompt "go"
use t1 Bash '{"command":"codex exec go","run_in_background":true}'; result t1 '{"backgroundTaskId":"bRun1"}'
check "no agreement: silent" '' "$(warm)"
echo '- ✓ Cache TTL: 1 giờ' > "$wp/docs/working-agreement.md"
check "run out, no timer: reminded" 'bRun1' "$(warm)"
check "stop_hook_active: never holds twice" '' "$(warm true)"
use t2 Bash '{"command":"sleep 3300","run_in_background":true}'; result t2 '{"backgroundTaskId":"bSleep"}'
check "background sleep this turn: silent" '' "$(warm)"
notify bSleep '<status>completed</status>\n'
check "timer from last turn: reminded again" 'bRun1' "$(warm)"
check "sleep timer not counted as a run" '1 background run' "$(warm)"
use t3 Monitor '{"command":"tail -F x","timeout_ms":3000000}'; result t3 '{"taskId":"bMon"}'
check "Monitor this turn: silent" '' "$(warm)"
notify bMon '<summary>Monitor event: x</summary>\n'
use t4 Agent '{"description":"d","prompt":"p","run_in_background":true}'; result t4 '{"isAsync":true,"agentId":"aAgent1"}'
check "async agent counted as a run" 'aAgent1' "$(warm)"
notify bRun1 '<status>completed</status>\n'
use t5 TaskStop '{"task_id":"aAgent1"}'; result t5 '{}'
check "all runs finished or stopped: silent" '' "$(warm)"
prompt "next"
use t6 Bash '{"command":"sleep 20; gh run watch 1","run_in_background":true}'; result t6 '{"backgroundTaskId":"bWatch"}'
check "sleep before real work is a run, not a timer" 'bWatch' "$(warm)"
use t7 Bash '{"command":"python3 /p/keep_warm.py set /s 3300"}'; result t7 '{"stdout":"START_WAITER due 10:00"}'
check "keep_warm set without waiter: still reminded" 'bWatch' "$(warm)"
use t8 Bash '{"command":"python3 /p/keep_warm.py wait /s","run_in_background":true}'; result t8 '{"backgroundTaskId":"bWaiter"}'
check "keep_warm wait launched this turn: silent" '' "$(warm)"
notify bWatch '<status>completed</status>\n'
prompt "later"
use t9 Agent '{"description":"d","prompt":"p","run_in_background":true}'; result t9 '{"isAsync":true,"agentId":"aAgent2"}'
check "waiter not counted as a run" '1 background run' "$(warm)"
use t10 Bash '{"command":"python3 /p/keep_warm.py set /s 3300"}'; result t10 '{"stdout":"WAITER_RUNNING due 11:00"}'
check "keep_warm set with waiter running: silent" '' "$(warm)"
check "missing transcript fails open" '' "$(printf '{"cwd":"%s","transcript_path":"/nope"}' "$wp" | python3 "$HOOKS/warm_gate.py")"
check "warm gate malformed input fails open" '' "$(printf 'x' | python3 "$HOOKS/warm_gate.py")"
rm -rf "$wp"

# --- context_gate ---
cp="$(mktemp -d)"; git -C "$cp" init -q; mkdir -p "$cp/docs"
ct="$cp/t.jsonl"
ctx() { printf '{"cwd":"%s","transcript_path":"%s","session_id":"%s","stop_hook_active":%s}' "$cp" "$ct" "${1:-s1}" "${2:-false}" | python3 "$HOOKS/context_gate.py"; }
call() { printf '{"type":"assistant","isSidechain":%s,"message":{"usage":{"input_tokens":10,"cache_read_input_tokens":%s,"cache_creation_input_tokens":1000}}}\n' "${2:-false}" "$1" >> "$ct"; }
call 350000
check "no agreement: silent" '' "$(ctx)"
echo '- ✓ quy ước khác' > "$cp/docs/working-agreement.md"
check "default 300k: reminded" '300k' "$(ctx)"
rm -rf "$cp/.git/crewmarshal"
echo '- Ngưỡng chuyển phiên: ✓ **400k** token' >> "$cp/docs/working-agreement.md"
check "below agreement's 400k: silent" '' "$(ctx)"
call 420000
check "past 400k: reminded" 'about 421k' "$(ctx)"
check "same size band: silent" '' "$(ctx)"
call 470000
check "still within 100k step: silent" '' "$(ctx)"
call 510000
check "next 100k step: reminded again" 'about 511k' "$(ctx)"
check "new session past threshold: reminded" '400k' "$(ctx s2)"
call 900000 true
check "sidechain usage ignored" '' "$(ctx s2)"
call 520000
check "stop_hook_active: silent" '' "$(ctx s3 true)"
check "context gate malformed input fails open" '' "$(printf 'x' | python3 "$HOOKS/context_gate.py")"
rm -rf "$cp"

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
head -4 "$run" > "$run.cut"; sh -c 'exit 0' & dead=$!; wait $dead
check "watch: dead pid without result reports gone" 'gone' "$(python3 "$WATCH" "$run.cut" 150000 "$dead")"
check "watch: dead pid still reports events read" 'context 160010' "$(python3 "$WATCH" "$run.cut" 150000 "$dead")"
rm -f "$run" "$run.cut"

exit $fail
