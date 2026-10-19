#!/usr/bin/env bash
# autopilot 드라이버: Claude Code를 반복 호출해 작업을 하나씩 처리한다.
# 레포에 넣지 말고 스킬 폴더에서 직접 실행:
#   cd <레포 루트> && bash <스킬 폴더>/scripts/autopilot.sh [최대 반복, 기본 무제한]
#
# 종료 조건:
#   - .autopilot/STOP 파일 존재 (Claude가 생성)
#   - claude 프로세스 연속 3회 비정상 종료
#   - 최대 반복 도달 (인자로 준 경우)
#
# 권한 모드 (환경변수 AUTOPILOT_PERMISSION):
#   allowlist (기본) : --allowedTools 로 필요한 도구만 허용. root에서도 동작.
#   skip             : --dangerously-skip-permissions. 전용 머신·컨테이너 전용. root에서는 거부될 수 있음.

set -u
if [ ! -d .git ]; then
  echo "[driver] 레포 루트(.git이 있는 디렉토리)에서 실행하세요." >&2
  exit 1
fi

MAX_ITER="${1:-0}"
MAX_CONSECUTIVE_CRASH=3
SLEEP_BETWEEN=10
LOG_DIR=".autopilot/driver-logs"
mkdir -p "$LOG_DIR"

# .autopilot 산출물이 커밋에 섞이지 않도록 (상태 파일은 스킬이 커밋 대상에 포함)
if ! grep -qs '^\.autopilot/driver-logs/' .gitignore 2>/dev/null; then
  printf '\n# autopilot 드라이버 산출물\n.autopilot/driver-logs/\n.autopilot/STOP\n' >> .gitignore
fi

# 스킬은 이름으로 호출한다. 레포 경로가 아니라 계정/프로젝트에 설치된 스킬을 찾는다.
PROMPT='autopilot 스킬을 사용해서 그 절차대로 작업 하나만 수행한 뒤 종료해. 질문하지 말고, 두 번째 작업을 시작하지 마.'

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
    echo "[driver] STOP 파일 발견. 종료."
    cat .autopilot/STOP 2>/dev/null
    break
  fi
  if [ "$MAX_ITER" -gt 0 ] && [ "$iter" -ge "$MAX_ITER" ]; then
    echo "[driver] 최대 반복 $MAX_ITER 도달. 종료."
    break
  fi

  iter=$((iter + 1))
  ts="$(date +%Y%m%d-%H%M%S)"
  echo "[driver] #$iter 시작 $ts"

  if AUTOPILOT_DRIVER=1 claude -p "$PROMPT" "${PERM_ARGS[@]}" > "$LOG_DIR/$ts.log" 2>&1; then
    crash=0
  else
    crash=$((crash + 1))
    echo "[driver] claude 비정상 종료 ($crash/$MAX_CONSECUTIVE_CRASH). 로그: $LOG_DIR/$ts.log"
    if [ "$crash" -ge "$MAX_CONSECUTIVE_CRASH" ]; then
      echo "[driver] 연속 크래시 한도 초과. 종료."
      break
    fi
  fi
  sleep "$SLEEP_BETWEEN"
done
