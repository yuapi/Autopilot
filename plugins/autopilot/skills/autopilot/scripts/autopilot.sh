#!/usr/bin/env bash
# autopilot 드라이버: Claude Code를 반복 호출해 작업을 하나씩 처리한다.
# 레포에 넣지 말고 스킬 폴더에서 직접 실행:
#   cd <레포 루트> && bash <스킬 폴더>/scripts/autopilot.sh [최대 반복, 기본 무제한]
#
# 종료 조건:
#   - .autopilot/STOP 파일 존재 (Claude가 생성)          → 종료 코드 0
#   - 최대 반복 도달 (인자로 준 경우)                      → 0
#   - claude 프로세스 연속 3회 비정상 종료                 → 1
#   - 잘못된 인자, git 레포 밖, claude CLI 없음            → 1
#
# 환경변수:
#   AUTOPILOT_SLEEP  반복 사이 대기 초 (기본 10)
#
# 권한 모드 (환경변수 AUTOPILOT_PERMISSION):
#   allowlist (기본) : --allowedTools 로 필요한 도구만 허용. root에서도 동작.
#   skip             : --dangerously-skip-permissions. 전용 머신·컨테이너 전용. root에서는 거부될 수 있음.

set -u
MAX_ITER="${1:-0}"
case "$MAX_ITER" in
  ''|*[!0-9]*) echo "[driver] 최대 반복은 0 이상의 정수여야 합니다 (0 = 무제한): $MAX_ITER" >&2; exit 1;;
esac
MAX_ITER=$((10#$MAX_ITER))
SLEEP_BETWEEN="${AUTOPILOT_SLEEP:-10}"
case "$SLEEP_BETWEEN" in
  ''|*[!0-9]*) echo "[driver] AUTOPILOT_SLEEP은 0 이상의 정수여야 합니다: $SLEEP_BETWEEN" >&2; exit 1;;
esac

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "[driver] git 레포 안에서 실행하세요." >&2
  exit 1
}
cd "$root" || exit 1

if ! command -v claude >/dev/null 2>&1; then
  echo "[driver] claude CLI를 찾을 수 없습니다. Claude Code를 설치하고 PATH를 확인하세요." >&2
  exit 1
fi

MAX_CONSECUTIVE_CRASH=3
LOG_DIR=".autopilot/driver-logs"
mkdir -p "$LOG_DIR"

# .autopilot 산출물이 커밋에 섞이지 않도록 (상태 파일은 스킬이 커밋 대상에 포함)
if [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ]; then echo >> .gitignore; fi
for ig in .autopilot/driver-logs/ .autopilot/STOP .autopilot/RUN .autopilot/.hook-state; do
  grep -qsxF "$ig" .gitignore || printf '%s\n' "$ig" >> .gitignore
done

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
  log="$LOG_DIR/$ts-$(printf '%04d' "$iter").log"
  echo "[driver] #$iter 시작 $ts"

  if AUTOPILOT_DRIVER=1 claude -p "$PROMPT" "${PERM_ARGS[@]}" > "$log" 2>&1; then
    crash=0
  else
    crash=$((crash + 1))
    echo "[driver] claude 비정상 종료 ($crash/$MAX_CONSECUTIVE_CRASH). 로그: $log"
    if [ "$crash" -ge "$MAX_CONSECUTIVE_CRASH" ]; then
      echo "[driver] 연속 크래시 한도 초과. 종료." >&2
      exit 1
    fi
  fi
  [ -f .autopilot/STOP ] || sleep "$SLEEP_BETWEEN"
done
