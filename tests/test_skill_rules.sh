#!/usr/bin/env bash
# SKILL.md에 적힌 명령이 의도대로 동작하는지 검증
. "$(dirname "$0")/lib.sh"
SKILL="$REPO/$SKILL_REL/SKILL.md"

# Phase 4 롤백 명령: "실패 시:" 줄의 첫 번째 `...` 코드
rollback="$(grep -m1 '실패 시:' "$SKILL" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')"
check "Phase 4 롤백 명령 추출" test -n "$rollback"

d="$(mktemp -d "$TMPROOT/r.XXXX")"
(
  cd "$d" && git init -q && git config user.email t@t && git config user.name t
  mkdir -p .autopilot src && echo a > src/x && echo "attempts 0" > .autopilot/BACKLOG.md
  git add -A && git commit -qm init
  echo b > src/x; echo new > src/new; mkdir src/newdir && echo z > src/newdir/f
  echo "attempts 1" > .autopilot/BACKLOG.md; echo s > .autopilot/untracked-state
  eval "$rollback"
) >/dev/null 2>&1
check "롤백: 수정한 파일 복원" grep -qx a "$d/src/x"
check "롤백: 새 파일 삭제" test ! -e "$d/src/new"
check "롤백: 새 폴더 삭제" test ! -e "$d/src/newdir"
check "롤백: .autopilot 변경(attempts) 유지" grep -qx "attempts 1" "$d/.autopilot/BACKLOG.md"
check "롤백: .autopilot 새 파일 유지" test -f "$d/.autopilot/untracked-state"

# Stop 훅 설치 예시 JSON이 유효하고 훅 경로가 \$CLAUDE_PROJECT_DIR 기준인지
json="$(grep -m1 '{"hooks":{"Stop"' "$SKILL")"
check "Stop 훅 설정 예시가 유효한 JSON" python3 -c 'import json,sys; json.loads(sys.argv[1])' "$json"
check "Stop 훅 명령이 \$CLAUDE_PROJECT_DIR 기준" grep -q 'CLAUDE_PROJECT_DIR' <<<"$json"

# Phase 0 작업 트리 정리 명령: .autopilot 밖만 치우고 .autopilot 미커밋 상태는 남김
tidy="$(grep -m1 '작업 트리 확인:' "$SKILL" | sed -n 's/^[^`]*`[^`]*`[^`]*`\([^`]*\)`.*/\1/p')"
check "Phase 0 정리 명령 추출" grep -q '^git stash' <<<"$tidy"
d="$(mktemp -d "$TMPROOT/r.XXXX")"
(
  cd "$d" && git init -q && git config user.email t@t && git config user.name t
  mkdir -p .autopilot src && echo a > src/x && echo "attempts 0" > .autopilot/BACKLOG.md
  git add -A && git commit -qm init
  echo b > src/x; echo new > src/new; echo "attempts 1" > .autopilot/BACKLOG.md; echo f > .autopilot/LOG.md
  eval "$tidy"
) >/dev/null 2>&1
check "정리: 작업 파일 변경은 stash로" grep -qx a "$d/src/x"
check "정리: 새 작업 파일도 stash로" test ! -e "$d/src/new"
check "정리: stash 하나 생김" test "$(git -C "$d" stash list | wc -l)" -eq 1
check "정리: .autopilot 수정 유지" grep -qx "attempts 1" "$d/.autopilot/BACKLOG.md"
check "정리: .autopilot 새 파일 유지" test -f "$d/.autopilot/LOG.md"

# CONFIG 템플릿: 기본값이 가장 안전한 값이고 알려진 키만 있는지
cfg="$REPO/$SKILL_REL/assets/CONFIG.md"
val() { sed -n "s/^$1:[[:space:]]*\([^[:space:]#]*\).*/\1/p" "$cfg"; }
check "CONFIG 기본 integration=local" test "$(val integration)" = local
check "CONFIG 기본 merge=off" test "$(val merge)" = off
check "CONFIG 기본 release=off" test "$(val release)" = off
keys="$(sed -n 's/^\([a-z_]*\):.*/\1/p' "$cfg" | sort | tr '\n' ' ')"
check "CONFIG 키 목록" test "$keys" = "base_branch branch_prefix integration merge release "
check "SKILL.md: CONFIG는 Claude가 바꾸지 않음" grep -q "Claude가 만들거나 값을 바꾸지 않는다" "$REPO/$SKILL_REL/SKILL.md"

finish
