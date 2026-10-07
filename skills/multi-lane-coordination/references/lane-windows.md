# Opening Lane Windows — Per Environment

The Chief picks one method with the user, proves it with a probe window
(`multi-lane-coordination`, *Interactive Lanes*), and records it in the working
agreement. The window always runs the lane's launch file, never an inline prompt.

Status: **verified** = probe passed (window opened, listed by `ListAgents`, message
round trip). **unverified** = documented behaviour of the tool, not yet probed by
this plugin — probe before relying on it.

| Environment | Detect | Open a window running the launch file | Status |
|-------------|--------|----------------------------------------|--------|
| macOS · Terminal.app | `TERM_PROGRAM=Apple_Terminal` | `osascript -e 'tell application "Terminal" to do script "bash <launch.sh>"'` — new window. Asks once for Automation permission. | **verified** (Claude Code 2.1.292) |
| macOS · Terminal.app, as a tab | same | No AppleScript command for a tab: needs System Events to send ⌘T, which needs Accessibility and fires into whatever window is in front. Prefer windows. | unverified |
| macOS · iTerm2 | `TERM_PROGRAM=iTerm.app` | `osascript -e 'tell application "iTerm2" to tell current window to create tab with default profile command "bash <launch.sh>"'` | unverified |
| Windows · Windows Terminal | `WT_SESSION` set | `wt.exe -w 0 new-tab --title lane-<tên> pwsh -NoExit -File <launch.ps1>` | unverified |
| Windows · no Windows Terminal | — | `start "lane-<tên>" pwsh -NoExit -File <launch.ps1>` | unverified |
| tmux (any OS) | `TMUX` set | `tmux new-window -n lane-<tên> 'bash <launch.sh>'` — the user switches with the tmux prefix | unverified |
| Linux · GNOME Terminal | `GNOME_TERMINAL_SCREEN` set | `gnome-terminal --tab --title=lane-<tên> -- bash <launch.sh>` | unverified |

## Closing a lane window at reset

Only after the lane's `reset` entry is in the outbox and `ListAgents` shows it
idle. End the session first, matching the exact name, then close the window:

| Environment | End the session | Close the window | Status |
|-------------|-----------------|------------------|--------|
| macOS · Terminal.app | `kill $(pgrep -f '^claude -n lane-<tên>-r<run>( |$)')` | `osascript -e 'tell application "Terminal" to close window id <N> saving no'` — `<N>` from `lanes/<tên>/window` | **verified** (Claude Code 2.1.292) |
| macOS · iTerm2 | same `pgrep`/`kill` | Tab closes itself when its command exits | unverified |
| tmux | — | `tmux kill-window -t lane-<tên>` ends both | unverified |
| Linux · GNOME Terminal | same `pgrep`/`kill` | Tab closes itself when its command exits (default profile) | unverified |
| Windows | `Get-CimInstance Win32_Process -Filter "Name='claude.exe'" \| Where-Object CommandLine -match 'lane-<tên>-r<run>' \| ForEach-Object { Stop-Process -Id $_.ProcessId }` | `-NoExit` keeps the tab open: tell the user which one to close | unverified |

Check the match before killing: one process, its command line naming that lane and
run. Several matches or none means stop and look, not kill them all.

Windows launch file (`launch.ps1`):

```powershell
Set-Location "<worktree đầu tiên của lane>"
$env:CREWMARSHAL_PROJECT_ROOT = "<project root>"
$env:CREWMARSHAL_LANE = "<tên>"
claude -n "lane-<tên>-r<run>" <cờ permission giống Chief> (Get-Content -Raw "<project root>\.crewmarshal\lanes\<tên>\prompt.txt")
```

## Traps

- **Permission mode must match the Chief's.** A peer in another mode holds
  incoming cross-session messages for its user's approval; they can expire unseen.
- **Cross-session messaging is not guaranteed everywhere.** It was verified on
  macOS between two local sessions. On another OS, the probe decides — if it fails,
  record "nhắn tin: không" and run on outbox + the user.
- **A window the user closes kills the session** and anything it ran in the
  background. Executors are launched detached for this reason.
- **Names collide across runs.** `lane-<tên>-r<run>` keeps a new run addressable
  while an old window is still open.
- **The Chief's own session name changes** when the user starts a new Chief
  session. Update the charters' *Cách chạy* line before the next message.
