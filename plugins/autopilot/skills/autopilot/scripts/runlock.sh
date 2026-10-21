#!/usr/bin/env bash
# Session-mode run marker (.autopilot/RUN) that knows which session owns it.
#   bash runlock.sh start [--tasks N] [repo]   claim RUN for this session; exit 2 if another live loop owns it.
#                                  Also adds the run artifacts (STOP, RUN, .hook-state, …) to .gitignore.
#                                  --tasks N: stop after N completed tasks (task.sh done writes STOP)
#   bash runlock.sh touch [repo]   record activity (run at the start of every task)
#   bash runlock.sh owner [repo]   print the owning session ID (empty if none or unknown)
#   bash runlock.sh stop [repo]    a person stops the loop: write .autopilot/STOP (the loop ends after its
#                                  current task; a session loop's Stop hook then lets the session end)
# The session ID comes from CLAUDE_CODE_SESSION_ID (set by Claude Code). RUN whose last activity is
# older than AUTOPILOT_RUN_STALE_MIN minutes (default 120) counts as abandoned and is taken over.
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
cmd="${1:-}"; [ $# -gt 0 ] && shift
budget=""; repo=.
while [ $# -gt 0 ]; do
  case "$1" in
    --tasks) shift; budget="${1:-}"
      case "$budget" in ''|*[!0-9]*|0) echo "[runlock] --tasks needs a positive number" >&2; exit 1;; esac;;
    *) repo="$1";;
  esac
  shift
done
[ -d "$repo" ] || { echo "[runlock] no such directory: $repo" >&2; exit 1; }
root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[runlock] not inside a git repository" >&2; exit 1; }
cd "$root"
RUN=.autopilot/RUN
me="${CLAUDE_CODE_SESSION_ID:-unknown}"
stale_min="${AUTOPILOT_RUN_STALE_MIN:-120}"

owner() { [ -f "$RUN" ] && sed -n 's/^session:[[:space:]]*//p' "$RUN" | head -1 || true; }
age_min() { "$PY" -c 'import os,sys,time; print(int((time.time()-os.path.getmtime(sys.argv[1]))//60))' "$RUN"; }
write() { mkdir -p .autopilot; printf 'session: %s\nstarted: %s\n' "$me" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$RUN"; set_budget; }
ignore_artifacts() {  # keep run artifacts out of commits, as the driver does (a refusal changes nothing)
  if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then echo >> .gitignore; fi
  for ig in .autopilot/STOP .autopilot/STOP.refused .autopilot/RUN .autopilot/.hook-state .autopilot/driver-logs/ .autopilot/driver.lock .autopilot/.task; do
    grep -qsxF "$ig" .gitignore || printf '%s\n' "$ig" >> .gitignore
  done
}
set_budget() {  # task budget lines (tasks: N, done: 0); without --tasks an existing budget is kept
  [ -n "$budget" ] || return 0
  grep -v '^tasks:\|^done:' "$RUN" > "$RUN.tmp" || true
  printf 'tasks: %s\ndone: 0\n' "$budget" >> "$RUN.tmp" && mv "$RUN.tmp" "$RUN"
  echo "[runlock] this loop stops after $budget completed task(s)."
}

case "$cmd" in
  start)
    if [ "${AUTOPILOT_DRIVER:-}" = 1 ]; then
      # Driver mode: the driver runs one task per call and limits runs itself. A run marker here would
      # let the session-mode Stop hook keep this call going, and --tasks would stop the whole driver.
      echo "[runlock] driver mode (AUTOPILOT_DRIVER=1): no run marker and no task budget; do one task and exit."
      exit 0
    fi
    if [ -f "$RUN" ]; then
      o="$(owner)"; a="$(age_min)"
      if [ -n "$o" ] && [ "$o" != "$me" ] && [ "$o" != unknown ] && [ "$me" != unknown ] && [ "$a" -lt "$stale_min" ]; then
        started="$(sed -n 's/^started:[[:space:]]*//p' "$RUN" | head -1)"
        echo "[runlock] another autopilot loop is running in this repository (session $o, started ${started:-?}, last active $a min ago)." >&2
        echo "[runlock] Let it finish, or create .autopilot/STOP to stop it. A marker idle for $stale_min min is taken over." >&2
        exit 2
      fi
      if [ "$o" = "$me" ]; then ignore_artifacts; set_budget; touch "$RUN"; exit 0; fi
    fi
    ignore_artifacts; write ;;
  touch)
    [ -f "$RUN" ] || exit 0
    o="$(owner)"
    if [ -z "$o" ] || [ "$o" = "$me" ]; then touch "$RUN"; fi ;;
  owner)
    owner ;;
  stop)
    [ -d .autopilot ] || { echo "[runlock] no .autopilot/ here: autopilot has not run in this repository."; exit 0; }
    if [ -f .autopilot/STOP ]; then echo "[runlock] already stopped: $(head -1 .autopilot/STOP)"; exit 0; fi
    printf 'Stopped by a person\n- %s, via /autopilot:stop or runlock.sh stop\n- Invoke autopilot again to resume\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .autopilot/STOP
    o="$(owner)"
    if [ -f "$RUN" ]; then
      echo "[runlock] wrote .autopilot/STOP. The loop (session ${o:-unknown}) stops after its current task."
    else
      echo "[runlock] wrote .autopilot/STOP. No loop was running; the next run will treat it as a request to stop until a person invokes autopilot again."
    fi ;;
  *)
    echo "usage: runlock.sh start [--tasks N]|touch|owner|stop [repository path]" >&2; exit 1 ;;
esac
