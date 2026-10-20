#!/usr/bin/env bash
# BACKLOG task transitions that keep "one task at a time, one task per commit" mechanical.
#   bash task.sh start <ID> [repo]  refuse while another task is in progress or changes outside .autopilot/
#                                   are uncommitted; then attempts + 1, status in_progress
#   bash task.sh done <ID> [repo]   refuse unless the task has its own commit(s) since `start` that change
#                                   files outside .autopilot/ and name no other task; then status done + date
#   bash task.sh fail <ID> [repo]   status back to open (attempts kept), or blocked from the 3rd attempt
#   bash task.sh drop <ID> [repo]   the task turned out unnecessary (cannot reproduce, already fixed):
#                                   blocked now, no commit needed; refused while code changes are uncommitted
# The start commit is kept in .autopilot/.task (ignored by git). Prints what it did; exit 1 with the reason
# when it refuses. Only the status, attempts and completed cells of the row are changed.
set -eu
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
cmd="${1:-}"; id="${2:-}"
usage() { echo "usage: task.sh start|done|fail|drop <task ID> [repository path]" >&2; exit 1; }
case "$cmd" in start|done|fail|drop) ;; *) usage;; esac
case "$id" in T-[0-9]*) ;; *) usage;; esac
case "$id" in *[!T0-9-]*) usage;; esac
root="$(git -C "${3:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[task] not inside a git repository" >&2; exit 1; }
cd "$root"
[ -f .autopilot/BACKLOG.md ] || { echo "[task] no .autopilot/BACKLOG.md" >&2; exit 1; }

dirty="$(git status --porcelain -- . ':!.autopilot' ':!.gitignore' 2>/dev/null | head -5 | tr '\n' ' ')"
head="$(git rev-parse -q --verify HEAD 2>/dev/null || echo none)"
start=""; [ -f .autopilot/.task ] && read -r tid start < .autopilot/.task && [ "$tid" = "$id" ] || start=""

if [ "$cmd" = drop ] && [ -n "$dirty" ]; then
  echo "[task] refused: uncommitted changes outside .autopilot/ ($dirty). A dropped task changes no code: roll them back first" >&2; exit 1
fi
if [ "$cmd" = start ] && [ -n "$dirty" ]; then
  echo "[task] refused: uncommitted changes outside .autopilot/ ($dirty). Commit or roll back the previous task first" >&2; exit 1
fi
if [ "$cmd" = done ]; then
  [ -n "$start" ] || { echo "[task] $id was not started with task.sh start; cannot tell which commits are its own" >&2; exit 1; }
  [ -z "$dirty" ] || { echo "[task] refused: uncommitted changes outside .autopilot/ ($dirty). Commit $id first" >&2; exit 1; }
  [ "$head" != "$start" ] || { echo "[task] refused: no commit since $id started. Commit the task's change first" >&2; exit 1; }
  range="$start..HEAD"; [ "$start" = none ] && range=HEAD
  code="$(git log --format= --name-only "$range" | grep -v '^$' | grep -v '^\.autopilot/' | grep -vx '.gitignore' | head -1 || true)"
  [ -n "$code" ] || { echo "[task] refused: the commits since $id started change only .autopilot/" >&2; exit 1; }
  scope=""; [ -f .autopilot/CONFIG.md ] && scope="$(tr -d '\r' < .autopilot/CONFIG.md | sed -n 's/^scope:[[:space:]]*\([^#]*\).*/\1/p' | head -1 | xargs || true)"   # tr: a CONFIG saved with CRLF
  if [ -n "$scope" ] && [ "$scope" != . ] && [ "$scope" != auto ]; then
    outside="$(git log --format= --name-only "$range" -- . ':!.autopilot' ':!.gitignore' | grep -v '^$' | sort -u | while IFS= read -r f; do
      inside=0; for p in $scope; do p="${p#./}"; p="${p%/}"; case "$f" in "$p"|"$p"/*) inside=1;; esac; done
      [ "$inside" = 1 ] || printf '%s ' "$f"; done)"
    [ -z "$outside" ] || { echo "[task] refused: changes outside scope ($scope) from .autopilot/CONFIG.md: $outside— roll them back or leave them to a person" >&2; exit 1; }
  fi
  others="$(git log --format=%s "$range" -- . ':!.autopilot' ':!.gitignore' | grep -oE 'T-[0-9]+' | grep -vx "$id" | sort -u | tr '\n' ' ' || true)"
  [ -z "$others" ] || { echo "[task] refused: commits since $id started also name $others— one task per commit. Roll back and redo them one at a time" >&2; exit 1; }
fi

"$PY" - "$cmd" "$id" <<'PY'
import datetime, re, sys
cmd, tid = sys.argv[1], sys.argv[2]
p = ".autopilot/BACKLOG.md"
lines = open(p, encoding="utf-8", newline="").read().split("\n")   # newline="": a CRLF file stays CRLF
row = re.compile(r"^\|\s*(T-\d+)\s*\|")
def cells(l): return l.strip().strip("|").split("|")
target = None
for i, l in enumerate(lines):
    m = row.match(l)
    if not m: continue
    c = [x.strip() for x in cells(l)]
    if m.group(1) == tid: target = i
    elif cmd == "start" and len(c) > 2 and c[2] == "in_progress":
        sys.exit(f"[task] refused: {m.group(1)} is still in progress. Finish it (task.sh done) or roll it back (task.sh fail) first")
if target is None:
    sys.exit(f"[task] no BACKLOG row {tid}")
c = cells(lines[target])
if len(c) < 8:
    sys.exit(f"[task] BACKLOG row {tid} has {len(c)} columns, expected 8. Fix the row first, e.g.\n"
             f"  | ID | Type | Status | Attempts | Task | Done when | Source | Completed |\n"
             f"  | {tid} | fix | open | 0 | what to do | how to verify | where it came from | |")
status = c[2].strip()
try: attempts = int(c[3].strip() or 0)
except ValueError: attempts = 0
if cmd == "start":
    if status not in ("open", "in_progress"):
        sys.exit(f"[task] refused: {tid} is {status}, not open")
    if status == "open":
        attempts += 1
    status = "in_progress"
elif cmd == "done":
    if status != "in_progress":
        sys.exit(f"[task] refused: {tid} is {status}, not in_progress")
    status = "done"
    c[-1] = " " + datetime.date.today().isoformat() + " "
elif cmd == "drop":
    if status not in ("open", "in_progress"):
        sys.exit(f"[task] refused: {tid} is {status}, not open or in_progress")
    status = "blocked"
else:
    status = "blocked" if attempts >= 3 else "open"
c[2] = f" {status} "; c[3] = f" {attempts} "
lines[target] = "|" + "|".join(c) + "|" + ("\r" if lines[target].endswith("\r") else "")
open(p, "w", encoding="utf-8", newline="").write("\n".join(lines))
print(f"[task] {tid}: {status} (attempts {attempts})")
PY

# Task budget (runlock.sh start --tasks N): count completed tasks and stop at N
if [ "$cmd" = done ] && [ "${AUTOPILOT_DRIVER:-}" != 1 ] && [ -f .autopilot/RUN ] && grep -q '^tasks:' .autopilot/RUN; then
  n="$(sed -n 's/^tasks:[[:space:]]*//p' .autopilot/RUN | head -1)"
  k="$(sed -n 's/^done:[[:space:]]*//p' .autopilot/RUN | head -1)"; k=$(( ${k:-0} + 1 ))
  { grep -v '^done:' .autopilot/RUN; echo "done: $k"; } > .autopilot/RUN.tmp && mv .autopilot/RUN.tmp .autopilot/RUN
  if [ "$k" -ge "${n:-0}" ] && [ ! -f .autopilot/STOP ]; then
    printf 'Stopped after %s task(s) as asked\n- The person set a budget of %s task(s) for this run (runlock.sh start --tasks)\n- Invoke autopilot again to continue\n' "$k" "$n" > .autopilot/STOP
    echo "[task] task budget used ($k/$n): wrote .autopilot/STOP. Record this task (LOG, commit), then end."
  else
    echo "[task] task budget: $k/$n done"
  fi
fi

case "$cmd" in
  start)
    echo "$id $head" > .autopilot/.task
    # keep the marker out of commits (only once the start succeeded: a refusal changes nothing)
    grep -qxF .autopilot/.task .gitignore 2>/dev/null || { [ -z "$(tail -c 1 .gitignore 2>/dev/null)" ] || echo >> .gitignore; echo .autopilot/.task >> .gitignore; };;
  done|fail|drop) rm -f .autopilot/.task;;
esac
