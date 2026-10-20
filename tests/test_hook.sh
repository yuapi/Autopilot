#!/usr/bin/env bash
# assets/autopilot-stop.sh (Stop 훅) 동작 테스트
. "$(dirname "$0")/lib.sh"
HOOK="$REPO/$SKILL_REL/assets/autopilot-stop.sh"

newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/r.XXXX")"
  (cd "$d" && git init -q && git config user.email t@t && git config user.name t \
    && mkdir .autopilot && echo "# LOG" > .autopilot/LOG.md && git add -A && git commit -qm init)
  echo "$d"
}
run_hook() { (cd "$TMPROOT" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK"); }
blocks() { run_hook "$1" | grep -q '"decision":"block"'; }

d="$(newrepo)"
check_not "RUN 없으면 막지 않음" blocks "$d"
check "RUN 없으면 아무 출력 없음" test -z "$(run_hook "$d")"

touch "$d/.autopilot/RUN"
check "RUN 있고 STOP 없으면 block" blocks "$d"
check "CLAUDE_PROJECT_DIR 기준으로 상태 파일 기록" test -f "$d/.autopilot/.hook-state"

echo "- 진척" >> "$d/.autopilot/LOG.md"
check "LOG 진척 후 다시 block" blocks "$d"
check "진척 후 카운터 0" grep -q ' 0$' "$d/.autopilot/.hook-state"

check "진척 없음 1회째 block" blocks "$d"
check "진척 없음 2회째 block" blocks "$d"
check_not "진척 없음 3회째 종료 허용" blocks "$d"
check "정체 시 STOP 생성" grep -q "no progress" "$d/.autopilot/STOP"
check "정체 시 RUN 삭제" test ! -e "$d/.autopilot/RUN"

d="$(newrepo)"; touch "$d/.autopilot/RUN"
blocks "$d"; blocks "$d"
(cd "$d" && git commit -q --allow-empty -m next)
check "새 커밋은 진척으로 인정" blocks "$d"
check "커밋 후 카운터 0" grep -q ' 0$' "$d/.autopilot/.hook-state"

d="$(newrepo)"; touch "$d/.autopilot/RUN" "$d/.autopilot/STOP"
check_not "STOP 있으면 종료 허용" blocks "$d"
check "STOP 있으면 RUN 정리" test ! -e "$d/.autopilot/RUN"

d="$(newrepo)"; touch "$d/.autopilot/RUN"; echo "garbage" > "$d/.autopilot/.hook-state"
check "깨진 상태 파일에도 block" blocks "$d"
check "AUTOPILOT_STALL_LIMIT=1 이면 바로 해제" bash -c "cd '$TMPROOT' && ! AUTOPILOT_STALL_LIMIT=1 CLAUDE_PROJECT_DIR='$d' bash '$HOOK' | grep -q block"

finish
