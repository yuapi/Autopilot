#!/usr/bin/env bash
# autopilot driver: calls Claude Code repeatedly, one task per call.
# Run it from the skill folder; do not copy it into the repository:
#   cd <repository root> && bash <skill folder>/scripts/autopilot.sh [max runs, default unlimited]
#
# Exit conditions:
#   - .autopilot/STOP exists (created by Claude)            → exit code 0
#   - max runs reached (when given)                         → 0
#   - AUTOPILOT_MAX_COST reached (when set)                 → writes STOP, 0
#   - claude exits abnormally 3 times in a row              → 1
#   - 3 runs in a row change neither LOG.md nor the commits → writes STOP, 1
#   - bad argument, not in a git repository, no claude CLI  → 1
#
# Environment variables:
#   AUTOPILOT_SLEEP        seconds to wait between runs (default 10)
#   AUTOPILOT_STALL_LIMIT  runs in a row without progress before stopping (default 3, same as the Stop hook)
#   AUTOPILOT_MODEL        model for every run, passed to claude --model (default: the CLI's default)
#   AUTOPILOT_MAX_COST     stop once the runs together cost this many USD (as claude reports it); writes STOP, exit 0
#
# Permission mode (AUTOPILOT_PERMISSION):
#   allowlist (default) : --allowedTools allows only the needed tools. Works as root.
#   skip                : --dangerously-skip-permissions. Dedicated machines/containers only. May be refused as root.

set -u
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
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
   "$PY" -c 'import os,sys,time; sys.exit(0 if time.time()-os.path.getmtime(".autopilot/RUN") < int(sys.argv[1])*60 else 1)' "${AUTOPILOT_RUN_STALE_MIN:-120}" 2>/dev/null; then
  echo "[driver] a session-mode autopilot loop is running in this repository (.autopilot/RUN). Let it finish or create .autopilot/STOP." >&2
  exit 1
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

# Keep .autopilot run artifacts out of commits (the state files themselves are committed by the skill)
if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then echo >> .gitignore; fi
for ig in .autopilot/driver-logs/ .autopilot/STOP .autopilot/RUN .autopilot/.hook-state .autopilot/driver.lock .autopilot/.task; do
  grep -qsxF "$ig" .gitignore || printf '%s\n' "$ig" >> .gitignore
done

# Integration preflight: branch/pr modes publish results. Say up front if the tools are missing,
# instead of letting tasks fail one by one. The driver only gets Bash, so PRs need the gh CLI
# (glab for a GitLab origin).
cfg_value() { [ -f .autopilot/CONFIG.md ] && sed -n "s/^$1:[[:space:]]*\([^[:space:]#]*\).*/\1/p" .autopilot/CONFIG.md | head -1; }
integration="$(cfg_value integration || true)"; integration="${integration:-local}"
case "$integration" in
  branch|pr)
    if ! git remote get-url origin >/dev/null 2>&1; then
      echo "[driver] integration: $integration needs a remote named origin, and there is none. Tasks will stay as local branches." >&2
    fi
    if [ "$integration" = pr ] && git remote get-url origin 2>/dev/null | grep -qi gitlab; then
      if ! command -v glab >/dev/null 2>&1; then
        echo "[driver] integration: pr on a GitLab origin needs the glab CLI to open merge requests, and it is not installed. Tasks will be pushed but no MRs opened; after 3 blocked attempts autopilot works like local." >&2
      elif ! glab auth status >/dev/null 2>&1; then
        echo "[driver] integration: pr needs glab logged in (glab auth login). Without it no MRs are opened; after 3 blocked attempts autopilot works like local." >&2
      else
        echo "[driver] integration: pr — glab can open and merge merge requests."
      fi
    elif [ "$integration" = pr ]; then
      if ! command -v gh >/dev/null 2>&1; then
        echo "[driver] integration: pr needs the gh CLI to open PRs, and it is not installed. Tasks will be pushed but no PRs opened; after 3 blocked attempts autopilot works like local." >&2
      elif [ "$(gh api 'repos/{owner}/{repo}' --jq '.permissions.push' 2>/dev/null)" != "true" ]; then
        echo "[driver] integration: pr needs gh with push access to this repository (gh auth login). Without it no PRs are opened; after 3 blocked attempts autopilot works like local." >&2
      else
        echo "[driver] integration: pr — gh can open and merge PRs."
      fi
    fi
    ;;
  local) ;;
  *) echo "[driver] unknown integration value in .autopilot/CONFIG.md: $integration (expected local, branch or pr)." >&2 ;;
esac

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
if [ -n "${AUTOPILOT_MODEL:-}" ]; then
  PERM_ARGS+=(--model "$AUTOPILOT_MODEL")
  echo "[driver] model: $AUTOPILOT_MODEL"
fi

# Progress = LOG.md or HEAD changed during the run
progress_sig() { { cat .autopilot/LOG.md 2>/dev/null; git rev-parse HEAD 2>/dev/null; } | cksum | cut -d' ' -f1; }
STALL_LIMIT="${AUTOPILOT_STALL_LIMIT:-3}"
case "$STALL_LIMIT" in ''|*[!0-9]*|0) STALL_LIMIT=3;; esac

# One result per run from claude --output-format json: the log gets the readable result text, and the
# cost (USD) is printed for the caller. Not JSON (old CLI, crash): the raw output is the log, cost empty.
read_result() {  # <raw output> <log file>
  "$PY" - "$1" "$2" <<'PY'
import json, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
res = None
for line in raw.splitlines():
    line = line.strip()
    if line.startswith("{") and '"total_cost_usd"' in line:
        try: res = json.loads(line)
        except ValueError: pass
with open(sys.argv[2], "w", encoding="utf-8") as f:
    if res is None:
        f.write(raw)
    else:
        f.write(str(res.get("result") or "") + "\n")
        f.write(f"\n[driver] turns {res.get('num_turns')}, cost ${float(res.get('total_cost_usd') or 0):.4f}\n")
print("" if res is None else f"{float(res.get('total_cost_usd') or 0):.4f}")
PY
}
MAX_COST="${AUTOPILOT_MAX_COST:-}"
if [ -n "$MAX_COST" ] && ! "$PY" -c 'import sys; assert float(sys.argv[1]) > 0' "$MAX_COST" 2>/dev/null; then
  echo "[driver] AUTOPILOT_MAX_COST must be a positive number of USD: $MAX_COST" >&2; exit 1
fi
total_cost=0

iter=0
crash=0
stall=0
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

  before="$(progress_sig)"
  raw="$(mktemp)"
  AUTOPILOT_DRIVER=1 claude -p "$PROMPT" "${PERM_ARGS[@]}" --output-format json > "$raw" 2>&1; rc=$?
  cost="$(read_result "$raw" "$log" || true)"; rm -f "$raw"
  if [ -n "$cost" ]; then
    total_cost="$("$PY" -c 'import sys; print(f"{float(sys.argv[1]) + float(sys.argv[2]):.4f}")' "$total_cost" "$cost")"
    echo "[driver] #$iter cost \$$cost (total \$$total_cost${MAX_COST:+ of \$$MAX_COST})"
  fi
  if [ "$rc" -eq 0 ]; then
    crash=0
    if [ "$(progress_sig)" = "$before" ]; then
      stall=$((stall + 1))
      echo "[driver] #$iter made no progress (LOG.md and commits unchanged, $stall/$STALL_LIMIT). Log: $log"
      if [ "$stall" -ge "$STALL_LIMIT" ] && [ ! -f .autopilot/STOP ]; then
        {
          echo "Final stop: no progress (driver)"
          echo "- $stall runs in a row changed neither LOG.md nor the commits"
          echo "- Work may be stuck on permission denials or an environment problem. See $log"
        } > .autopilot/STOP
        echo "[driver] $stall runs in a row without progress. Wrote .autopilot/STOP and exiting." >&2
        exit 1
      fi
    else
      stall=0
      last="$(grep '^## ' .autopilot/LOG.md 2>/dev/null | tail -1)"
      [ -n "$last" ] && echo "[driver] #$iter → ${last#\#\# }"
    fi
  else
    crash=$((crash + 1))
    echo "[driver] claude exited abnormally ($crash/$MAX_CONSECUTIVE_CRASH). Log: $log"
    if [ "$crash" -ge "$MAX_CONSECUTIVE_CRASH" ]; then
      echo "[driver] too many consecutive crashes. Exiting." >&2
      exit 1
    fi
  fi
  if [ -n "$MAX_COST" ] && "$PY" -c 'import sys; sys.exit(0 if float(sys.argv[1]) >= float(sys.argv[2]) else 1)' "$total_cost" "$MAX_COST" && [ ! -f .autopilot/STOP ]; then
    printf 'Stopped: cost budget reached\n- The runs cost $%s together; AUTOPILOT_MAX_COST is $%s\n- Run the driver again (with a higher budget) to continue\n' "$total_cost" "$MAX_COST" > .autopilot/STOP
    echo "[driver] cost budget reached (\$$total_cost of \$$MAX_COST). Wrote .autopilot/STOP and exiting."
    exit 0
  fi
  [ -f .autopilot/STOP ] || sleep "$SLEEP_BETWEEN"
done
