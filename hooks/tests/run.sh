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
nop="$(mktemp -d)"; git -C "$nop" init -q
check "project without pointer: no nudge" '' "$(pointer "$nop")"
check "not a git repo: fails open" '' "$(pointer "$(mktemp -d)")"
rm -rf "$repo" "$nop"

exit $fail
