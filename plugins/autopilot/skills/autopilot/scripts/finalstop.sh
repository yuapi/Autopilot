#!/usr/bin/env bash
# The final stop ("no substantive work left"), refused until its conditions hold.
#   bash finalstop.sh [repository path] <<'EOF'
#   Final stop: no substantive work left
#   - Cycles: …
#   EOF
# Checks: the latest ROADMAP "Deep discovery" record holds all four stages (static, running, quality
# attributes, external signals) and is no older than the last task in the LOG; no BACKLOG task is open
# or in progress; nothing outside .autopilot/ is uncommitted.
# Then writes STOP from stdin, removes RUN and adds a `stop` LOG entry. Exit 1 with the reasons otherwise.
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
here="$(cd "$(dirname "$0")" && pwd)"
[ -d "${1:-.}" ] || { echo "[finalstop] no such directory: ${1:-.}" >&2; exit 1; }
root="$(git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[finalstop] not inside a git repository" >&2; exit 1; }
cd "$root"
summary=""
[ -t 0 ] || summary="$(cat)"

problems="$("$PY" - <<'PY'
import re
def read(p):
    try: return open(p, encoding="utf-8").read()
    except FileNotFoundError: return ""
out = []
m = re.search(r"^##[^\n]*(Deep discovery|심화 발굴)[^\n]*\n(.*?)(?=^## |\Z)", read(".autopilot/ROADMAP.md"), re.M | re.S)
lines = [l for l in (m.group(2) if m else "").splitlines() if not l.strip().startswith("(")]
# The record must be this cycle's: the latest dated record (YYYY-MM-DD, best with THH:MMZ as log.sh writes)
# holds all four stages and is no older than the last task in the LOG. A record from an earlier cycle
# would otherwise let every later final stop through.
stamp = re.compile(r"(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}:\d{2}))?")
dated = [(i, stamp.search(l)) for i, l in enumerate(lines)]
dated = [(i, mm.group(1) + "T" + (mm.group(2) or "00:00")) for i, mm in dated if mm]
tasks = re.findall(r"^## (\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})Z? \| T-\d+ \| (?:done|failed|blocked) \|", read(".autopilot/LOG.md"), re.M)
last_task = max((d + "T" + t for d, t in tasks), default="")
body = "\n".join(lines)
if dated:
    i, when = max(dated, key=lambda x: x[1])
    nxt = [j for j, _ in dated if j > i]
    body = "\n".join(lines[i:nxt[0] if nxt else len(lines)])
    if last_task and when < last_task:
        out.append(f"ROADMAP \"Deep discovery\" latest record ({when.replace('T00:00', '')}) is older than the last task in the LOG ({last_task}Z): run deep discovery again for this cycle and record it with the UTC time (date -u +%Y-%m-%dT%H:%MZ)")
elif last_task:
    out.append("ROADMAP \"Deep discovery\" record has no date: record this cycle's deep discovery with the UTC time (date -u +%Y-%m-%dT%H:%MZ)")
stages = [("1 static", r"static|정적"), ("2 running", r"running|실행"), ("3 quality attributes", r"quality|품질"), ("4 external signals", r"external|외부")]
missing = [name for name, rx in stages if not re.search(rx, body, re.I)]
if missing:
    out.append("ROADMAP \"Deep discovery\" does not record stage(s): " + ", ".join(missing))
rows = re.findall(r"^\|\s*(T-\d+)\s*\|[^|]*\|\s*(open|in_progress)\s*\|", read(".autopilot/BACKLOG.md"), re.M)
if rows:
    out.append("BACKLOG still has open or in-progress tasks: " + ", ".join(r[0] for r in rows[:10]))
print("\n".join(out))
PY
)"
# .gitignore counts as state here, as in task.sh: task.sh start adds the .autopilot/.task line to it
dirty="$(git status --porcelain -- . ':!.autopilot' ':!.gitignore' 2>/dev/null | head -5)"
[ -z "$dirty" ] || problems="${problems:+$problems
}uncommitted changes outside .autopilot/ (commit or roll back the last task first): $(echo "$dirty" | tr '\n' ' ')"
case "$summary" in "Final stop"*|"최종 정지"*) ;; *) problems="${problems:+$problems
}the STOP summary on stdin must start with \"Final stop\" (see SKILL.md)";; esac

if [ -n "$problems" ]; then
  echo "[finalstop] refused — this is not a final stop yet:" >&2
  printf '%s\n' "$problems" | sed 's/^/  - /' >&2
  echo "[finalstop] Keep going: run the missing deep discovery stages or finish the queued tasks." >&2
  exit 1
fi
printf '%s\n%s\n' "$summary" "(checked by finalstop.sh)" > .autopilot/STOP   # the hook and the driver refuse a final stop without it
rm -f .autopilot/RUN .autopilot/.hook-state
printf '%s\n' "- $(printf '%s' "$summary" | head -1)" | bash "$here/log.sh" - stop "$root" >/dev/null
echo "[finalstop] wrote .autopilot/STOP and removed RUN. Commit .autopilot/ if the integration mode commits state."
