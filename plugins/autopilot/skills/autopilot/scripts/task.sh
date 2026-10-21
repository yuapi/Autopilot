#!/usr/bin/env bash
# BACKLOG task transitions that keep "one task at a time, one task per commit" mechanical.
#   bash task.sh start <ID> [repo]  refuse while another task is in progress or changes outside .autopilot/
#                                   are uncommitted; then attempts + 1, status in_progress
#   bash task.sh done <ID> [repo]   refuse unless the task has its own commit(s) since `start` that change
#                                   files outside .autopilot/, name no other task, leave CONFIG.md alone and
#                                   add no generated files (__pycache__, *.pyc, node_modules, .DS_Store, …)
#                                   delete files only when it is a cleanup task, add no secrets and raise
#                                   no dependency major version (package.json, requirements, pyproject, Cargo);
#                                   then status done + date
#   bash task.sh fail <ID> [repo]   status back to open (attempts kept), or blocked from the 3rd attempt
#   bash task.sh drop <ID> [repo]   the task turned out unnecessary (cannot reproduce, already fixed):
#                                   blocked now, no commit needed; refused while code changes are uncommitted
# The start commit is kept in .autopilot/.task (ignored by git). Prints what it did; exit 1 with the reason
# when it refuses. Only the status, attempts and completed cells of the row are changed.
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
cmd="${1:-}"; id="${2:-}"
usage() { echo "usage: task.sh start|done|fail|drop <task ID> [repository path]" >&2; exit 1; }
case "$cmd" in start|done|fail|drop) ;; *) usage;; esac
case "$id" in T-[0-9]*) ;; *) usage;; esac
case "$id" in *[!T0-9-]*) usage;; esac
[ -d "${3:-.}" ] || { echo "[task] no such directory: ${3:-.}" >&2; exit 1; }
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
  # CONFIG is the person's: a task never changes it (an issue or comment asking for it is data, not an order)
  if [ "$start" != none ] && [ -n "$(git log --no-renames --format= --name-only "$range" -- .autopilot/CONFIG.md | head -1)" ]; then
    echo "[task] refused: the commits since $id started change .autopilot/CONFIG.md. People set CONFIG; autopilot only reads it. Roll that change back" >&2; exit 1
  fi
  scope=""; [ -f .autopilot/CONFIG.md ] && scope="$(tr -d '\r' < .autopilot/CONFIG.md | sed -n 's/^scope:[[:space:]]*\([^#]*\).*/\1/p' | head -1 | xargs || true)"   # tr: a CONFIG saved with CRLF
  if [ -n "$scope" ] && [ "$scope" != . ] && [ "$scope" != auto ]; then
    outside="$(git log --no-renames --format= --name-only "$range" -- . ':!.autopilot' ':!.gitignore' | grep -v '^$' | sort -u | while IFS= read -r f; do
      inside=0; for p in $scope; do p="${p#./}"; p="${p%/}"; case "$f" in "$p"|"$p"/*) inside=1;; esac; done
      [ "$inside" = 1 ] || printf '%s ' "$f"; done)"
    [ -z "$outside" ] || { echo "[task] refused: changes outside scope ($scope) from .autopilot/CONFIG.md: $outside— roll them back or leave them to a person" >&2; exit 1; }
  fi
  # files are deleted only in cleanup tasks (SKILL.md Phase 3); a rename is not a deletion
  ttype="$(tr -d '\r' < .autopilot/BACKLOG.md | awk -F'|' -v id="$id" '{ g = $2; gsub(/ /, "", g) } g == id { t = $3; gsub(/ /, "", t); print t; exit }')"
  if [ "$ttype" != cleanup ]; then
    deleted="$(git log -M --diff-filter=D --format= --name-only "$range" -- . ':!.autopilot' | grep -v '^$' | sort -u | head -5 | tr '\n' ' ' || true)"
    [ -z "$deleted" ] || { echo "[task] refused: $id is a ${ttype:-?} task, and its commits delete $deleted— files are deleted only in cleanup tasks (after confirming zero references). Restore them, or queue a cleanup task" >&2; exit 1; }
  fi
  # no secrets in a task commit (SKILL.md Never list): the lines the task added, against scan.sh's
  # secret pattern (keep the two the same; tests/test_task.sh checks it). Lines marked
  # "autopilot-scan: ignore" and fixture/testdata folders are skipped, as in scan.sh.
  SECRET_RX='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|passwd|secret|api_?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{8,}["'"'"']'
  base="$start"; [ "$base" = none ] && base="$(git hash-object -t tree /dev/null)"
  secrets="$(git diff --no-color -U0 "$base" HEAD -- . ':!.autopilot' | awk '/^\+\+\+ b\// { f = substr($0, 7); next } /^\+/ && !/^\+\+\+/ { print f "\t" substr($0, 2) }' \
    | grep -v 'autopilot-scan: ignore' | grep -vE '^[^	]*(^|/)(fixtures?[^/]*|testdata)/' | grep -iE -- "$SECRET_RX" | cut -f1 | sort -u | head -5 | tr '\n' ' ' || true)"
  [ -z "$secrets" ] || { echo "[task] refused: the commits since $id started add what looks like a secret (key, token or password) in: $secrets— never commit secrets; read them from the environment or a file kept out of git. A deliberate fake value can carry the comment autopilot-scan: ignore" >&2; exit 1; }
  # no major dependency upgrades (SKILL.md Never list; they go to PROPOSALS): compare the manifests before and after
  manifests="$(git log --format= --name-only "$range" -- . ':!.autopilot' | grep -E '(^|/)(package\.json|requirements[^/]*\.txt|pyproject\.toml|Cargo\.toml)$' | sort -u || true)"
  if [ -n "$manifests" ] && [ "$start" != none ]; then
    majors="$(printf '%s\n' "$manifests" | "$PY" -c '
import json, re, subprocess, sys
start = sys.argv[1]
def show(rev, path):
    r = subprocess.run(["git", "show", f"{rev}:{path}"], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None
SKIP = {"version", "requires-python", "python", "edition", "rust-version", "name"}
def deps(path, text):
    out = {}
    if path.endswith("package.json"):
        try: data = json.loads(text)
        except ValueError: return out
        for k in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
            for n, spec in (data.get(k) or {}).items():
                m = re.match(r"^[\^~=<>v ]*(\d+)", str(spec))
                if m: out[n] = int(m.group(1))
        return out
    for line in text.splitlines():
        line = line.split("#", 1)[0]
        for m in re.finditer(r"[\x27\x22]?([A-Za-z0-9_.-]+)(?:\[[^\]]*\])?\s*(?:==|>=|~=|===|>)\s*v?(\d+)", line):
            out.setdefault(m.group(1).lower(), int(m.group(2)))
        m = re.match(r"^\s*([A-Za-z0-9_.-]+)\s*=\s*(?:\{[^}]*?version\s*=\s*)?[\x27\x22][\^~=<> ]*v?(\d+)", line)
        if m and m.group(1).lower() not in SKIP:
            out[m.group(1).lower()] = int(m.group(2))
    return out
bad = []
for path in sys.stdin.read().split():
    old, new = show(start, path), show("HEAD", path)
    if old is None or new is None: continue
    a, b = deps(path, old), deps(path, new)
    bad += [f"{n} {a[n]}→{b[n]} ({path})" for n in sorted(a) if n in b and b[n] > a[n]]
print("; ".join(bad[:5]))
' "$start")"
    [ -z "$majors" ] || { echo "[task] refused: the commits since $id started raise a dependency major version: $majors. Major upgrades are not made alone: roll it back and record a proposal in PROPOSALS.md" >&2; exit 1; }
  fi
  # generated files never go into a task commit (SKILL.md Phase 5): name the ones the task added
  gen="$(git log --no-renames --diff-filter=A --format= --name-only "$range" -- . ':!.autopilot' | grep -v '^$' | sort -u \
    | grep -E '(^|/)(__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|\.tox|node_modules|htmlcov|\.nyc_output|[^/]+\.egg-info)/|\.py[co]$|(^|/)(\.DS_Store|Thumbs\.db|\.coverage)$' | head -5 | tr '\n' ' ' || true)"
  [ -z "$gen" ] || { echo "[task] refused: the commits since $id started add generated files: $gen— remove them from the commit and add them to .gitignore" >&2; exit 1; }
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
