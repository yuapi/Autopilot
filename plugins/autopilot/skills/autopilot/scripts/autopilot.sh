#!/usr/bin/env bash
# autopilot driver: calls Claude Code repeatedly, one task per call.
# Run it from the skill folder; do not copy it into the repository:
#   cd <repository root> && bash <skill folder>/scripts/autopilot.sh [max runs, default unlimited]
#
# Exit conditions:
#   - .autopilot/STOP exists (created by Claude)            → exit code 0
#   - max runs reached (when given)                         → 0
#   - claude exits abnormally 3 times in a row              → 1
#   - bad argument, not in a git repository, no claude CLI  → 1
#
# Environment variables:
#   AUTOPILOT_SLEEP  seconds to wait between runs (default 10)
#
# Permission mode (AUTOPILOT_PERMISSION):
#   allowlist (default) : --allowedTools allows only the needed tools. Works as root.
#   skip                : --dangerously-skip-permissions. Dedicated machines/containers only. May be refused as root.

set -u
MAX_ITER="${1:-0}"
case "$MAX_ITER" in
  ''|*[!0-9]*) echo "[driver] max runs must be a non-negative integer (0 = unlimited): $MAX_ITER" >&2; exit 1;;
esac
MAX_ITER=$((10#$MAX_ITER))
SLEEP_BETWEEN="${AUTOPILOT_SLEEP:-10}"
case "$SLEEP_BETWEEN" in
  ''|*[!0-9]*) echo "[driver] AUTOPILOT_SLEEP must be a non-negative integer: $SLEEP_BETWEEN" >&2; exit 1;;
esac

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "[driver] run it inside a git repository." >&2
  exit 1
}
cd "$root" || exit 1

if ! command -v claude >/dev/null 2>&1; then
  echo "[driver] claude CLI not found. Install Claude Code and check PATH." >&2
  exit 1
fi

MAX_CONSECUTIVE_CRASH=3
LOG_DIR=".autopilot/driver-logs"
mkdir -p "$LOG_DIR"

# One loop per repository: refuse while another driver or a session-mode loop is active
LOCK=.autopilot/driver.lock
if [ -f "$LOCK" ] && kill -0 "$(cat "$LOCK" 2>/dev/null)" 2>/dev/null; then
  echo "[driver] another driver is already running in this repository (pid $(cat "$LOCK"))." >&2
  exit 1
fi
if [ -f .autopilot/RUN ] && [ ! -f .autopilot/STOP ] && \
   python3 -c 'import os,sys,time; sys.exit(0 if time.time()-os.path.getmtime(".autopilot/RUN") < int(sys.argv[1])*60 else 1)' "${AUTOPILOT_RUN_STALE_MIN:-120}" 2>/dev/null; then
  echo "[driver] a session-mode autopilot loop is running in this repository (.autopilot/RUN). Let it finish or create .autopilot/STOP." >&2
  exit 1
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Keep .autopilot run artifacts out of commits (the state files themselves are committed by the skill)
if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then echo >> .gitignore; fi
for ig in .autopilot/driver-logs/ .autopilot/STOP .autopilot/RUN .autopilot/.hook-state .autopilot/driver.lock; do
  grep -qsxF "$ig" .gitignore || printf '%s\n' "$ig" >> .gitignore
done

# Call the skill by name so the one installed for the account/project is used, not a repository path.
PROMPT='Use the autopilot skill and follow its procedure to do exactly one task, then exit. Do not ask questions and do not start a second task.'

case "${AUTOPILOT_PERMISSION:-allowlist}" in
  skip)
    PERM_ARGS=(--dangerously-skip-permissions)
    ;;
  *)
    PERM_ARGS=(--allowedTools "Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,Skill,TodoWrite")
    ;;
esac

iter=0
crash=0
while :; do
  if [ -f .autopilot/STOP ]; then
    echo "[driver] STOP file found. Exiting."
    cat .autopilot/STOP 2>/dev/null
    break
  fi
  if [ "$MAX_ITER" -gt 0 ] && [ "$iter" -ge "$MAX_ITER" ]; then
    echo "[driver] reached $MAX_ITER runs. Exiting."
    break
  fi

  iter=$((iter + 1))
  ts="$(date +%Y%m%d-%H%M%S)"
  log="$LOG_DIR/$ts-$(printf '%04d' "$iter").log"
  echo "[driver] #$iter start $ts"

  if AUTOPILOT_DRIVER=1 claude -p "$PROMPT" "${PERM_ARGS[@]}" > "$log" 2>&1; then
    crash=0
  else
    crash=$((crash + 1))
    echo "[driver] claude exited abnormally ($crash/$MAX_CONSECUTIVE_CRASH). Log: $log"
    if [ "$crash" -ge "$MAX_CONSECUTIVE_CRASH" ]; then
      echo "[driver] too many consecutive crashes. Exiting." >&2
      exit 1
    fi
  fi
  [ -f .autopilot/STOP ] || sleep "$SLEEP_BETWEEN"
done
