#!/usr/bin/env bash
# The final stop ("no substantive work left"), refused until its conditions hold.
#   bash finalstop.sh [repository path] <<'EOF'
#   Final stop: no substantive work left
#   - Cycles: …
#   EOF
# Checks: ROADMAP "Deep discovery" records all four stages (static, running, quality attributes,
# external signals); no BACKLOG task is open or in progress; nothing outside .autopilot/ is uncommitted.
# Then writes STOP from stdin, removes RUN and adds a `stop` LOG entry. Exit 1 with the reasons otherwise.
set -eu
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
here="$(cd "$(dirname "$0")" && pwd)"
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
body = "\n".join(l for l in (m.group(2) if m else "").splitlines() if not l.strip().startswith("("))
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
dirty="$(git status --porcelain -- . ':!.autopilot' 2>/dev/null | head -5)"
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
printf '%s\n' "$summary" > .autopilot/STOP
rm -f .autopilot/RUN .autopilot/.hook-state
printf '%s\n' "- $(printf '%s' "$summary" | head -1)" | bash "$here/log.sh" - stop "$root" >/dev/null
echo "[finalstop] wrote .autopilot/STOP and removed RUN. Commit .autopilot/ if the integration mode commits state."
