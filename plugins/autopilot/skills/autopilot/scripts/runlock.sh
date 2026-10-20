#!/usr/bin/env bash
# Session-mode run marker (.autopilot/RUN) that knows which session owns it.
#   bash runlock.sh start [repo]   claim RUN for this session; exit 2 if another live loop owns it
#   bash runlock.sh touch [repo]   record activity (run at the start of every task)
#   bash runlock.sh owner [repo]   print the owning session ID (empty if none or unknown)
#   bash runlock.sh stop [repo]    a person stops the loop: write .autopilot/STOP (the loop ends after its
#                                  current task; a session loop's Stop hook then lets the session end)
# The session ID comes from CLAUDE_CODE_SESSION_ID (set by Claude Code). RUN whose last activity is
# older than AUTOPILOT_RUN_STALE_MIN minutes (default 120) counts as abandoned and is taken over.
set -eu
cmd="${1:-}"
root="$(git -C "${2:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[runlock] not inside a git repository" >&2; exit 1; }
cd "$root"
RUN=.autopilot/RUN
me="${CLAUDE_CODE_SESSION_ID:-unknown}"
stale_min="${AUTOPILOT_RUN_STALE_MIN:-120}"

owner() { [ -f "$RUN" ] && sed -n 's/^session:[[:space:]]*//p' "$RUN" | head -1 || true; }
age_min() { python3 -c 'import os,sys,time; print(int((time.time()-os.path.getmtime(sys.argv[1]))//60))' "$RUN"; }
write() { mkdir -p .autopilot; printf 'session: %s\nstarted: %s\n' "$me" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$RUN"; }

case "$cmd" in
  start)
    if [ -f "$RUN" ]; then
      o="$(owner)"; a="$(age_min)"
      if [ -n "$o" ] && [ "$o" != "$me" ] && [ "$o" != unknown ] && [ "$me" != unknown ] && [ "$a" -lt "$stale_min" ]; then
        started="$(sed -n 's/^started:[[:space:]]*//p' "$RUN" | head -1)"
        echo "[runlock] another autopilot loop is running in this repository (session $o, started ${started:-?}, last active $a min ago)." >&2
        echo "[runlock] Let it finish, or create .autopilot/STOP to stop it. A marker idle for $stale_min min is taken over." >&2
        exit 2
      fi
      if [ "$o" = "$me" ]; then touch "$RUN"; exit 0; fi
    fi
    write ;;
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
    echo "usage: runlock.sh start|touch|owner|stop [repository path]" >&2; exit 1 ;;
esac
