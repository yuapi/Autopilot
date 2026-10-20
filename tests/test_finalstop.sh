#!/usr/bin/env bash
# Tests for scripts/finalstop.sh (the final stop is refused until its conditions hold)
. "$(dirname "$0")/lib.sh"
FS="$REPO/$SKILL_REL/scripts/finalstop.sh"
newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/f.XXXX")"
  (cd "$d" && git init -q && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m init
   mkdir .autopilot && touch .autopilot/RUN && printf '| T-001 | fix | done | 1 | x | y | z | |\n' > .autopilot/BACKLOG.md
   printf '## Deep discovery\n- 1 static: 0. 2 running: 0. 3 quality: 0. 4 external: 0\n\n## Features in progress\n' > .autopilot/ROADMAP.md)
  echo "$d"
}
SUM=$'Final stop: no substantive work left\n- Cycles: 1'
stop() { (cd "$1" && printf '%s\n' "${2:-$SUM}" | bash "$FS" 2>&1); }

d="$(newrepo)"; out="$(stop "$d")"; rc=$?
check "all conditions hold → exit 0" test "$rc" -eq 0
check "STOP written from stdin" grep -qx "Final stop: no substantive work left" "$d/.autopilot/STOP"
check "RUN removed" test ! -e "$d/.autopilot/RUN"
check "stop LOG entry added" grep -q "| - | stop | skill" "$d/.autopilot/LOG.md"

d="$(newrepo)"; printf '## Deep discovery\n(template placeholder: static running quality external)\n' > "$d/.autopilot/ROADMAP.md"
out="$(stop "$d")"; rc=$?
check "placeholder only → refused" test "$rc" -eq 1
check "names the missing stages" grep -q "does not record stage(s): 1 static, 2 running, 3 quality attributes, 4 external signals" <<<"$out"
check "refused → no STOP" test ! -e "$d/.autopilot/STOP"
check "refused → RUN kept (the loop goes on)" test -f "$d/.autopilot/RUN"
printf '## Deep discovery\n- 1 static: 0. 2 running: 0\n' > "$d/.autopilot/ROADMAP.md"
check "two stages missing → named" grep -q "stage(s): 3 quality attributes, 4 external signals" <<<"$(stop "$d")"
printf '## 심화 발굴\n- 1 정적: 0, 2 실행: 0, 3 품질 속성: 0, 4 외부 신호: 0\n' > "$d/.autopilot/ROADMAP.md"
check "Korean headings and stage names accepted" bash -c "cd '$d' && printf '최종 정지: 할 일 없음\n' | bash '$FS' >/dev/null 2>&1"

d="$(newrepo)"; printf '| T-002 | fix | open | 0 | x | y | z | |\n| T-003 | fix | in_progress | 1 | x | y | z | |\n' >> "$d/.autopilot/BACKLOG.md"
check "open and in-progress tasks → refused and named" grep -q "open or in-progress tasks: T-002, T-003" <<<"$(stop "$d")"
d="$(newrepo)"; echo x > "$d/code.py"
check "uncommitted code → refused" grep -q "uncommitted changes outside .autopilot/" <<<"$(stop "$d")"
d="$(newrepo)"; echo "state" > "$d/.autopilot/notes"
check "uncommitted .autopilot/ state is fine" bash -c "cd '$d' && printf '%s\n' 'Final stop: x' | bash '$FS' >/dev/null 2>&1"
d="$(newrepo)"
check "summary not starting with 'Final stop' → refused" grep -q 'must start with "Final stop"' <<<"$(stop "$d" "all done")"
check_not "outside a git repository → exit 1" bash -c "cd '$TMPROOT' && echo 'Final stop' | bash '$FS'"
finish
