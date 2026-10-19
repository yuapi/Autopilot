#!/usr/bin/env bash
# autopilot Stop 훅 (세션 연속 모드).
# - .autopilot/RUN 이 있을 때만 동작한다. 실행 중이 아닌 세션은 막지 않는다.
# - .autopilot/STOP 이 있으면 RUN을 지우고 종료를 허용한다.
# - LOG·커밋에 변화가 없는데 연속 AUTOPILOT_STALL_LIMIT(기본 3)회 막았으면
#   STOP을 남기고 종료를 허용한다 (진척 없는 무한 차단 방지).
# 해제: .autopilot/STOP 생성, .autopilot/RUN 삭제, 또는 settings.json에서 이 훅 제거
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
A=.autopilot
[ -f "$A/RUN" ] || exit 0
if [ -f "$A/STOP" ]; then
  rm -f "$A/RUN" "$A/.hook-state"
  exit 0
fi

sig="$({ cat "$A/LOG.md" 2>/dev/null; git rev-parse HEAD 2>/dev/null; } | cksum | cut -d' ' -f1)"
prev=""; n=0
if [ -f "$A/.hook-state" ]; then read -r prev n < "$A/.hook-state" || true; fi
case "$n" in ''|*[!0-9]*) n=0;; esac
if [ "$sig" = "$prev" ]; then n=$((n + 1)); else n=0; fi

limit="${AUTOPILOT_STALL_LIMIT:-3}"
if [ "$n" -ge "$limit" ]; then
  {
    echo "최종 중단: 진척 없음"
    echo "- Stop 훅이 ${n}회 연속 종료를 막았지만 LOG.md와 커밋에 변화가 없음"
    echo "- 권한 거부·환경 문제로 작업을 진행하지 못하는 상태일 수 있음. LOG 마지막 항목 확인"
  } > "$A/STOP"
  rm -f "$A/RUN" "$A/.hook-state"
  exit 0
fi
echo "$sig $n" > "$A/.hook-state"

cat << 'JSON'
{"decision":"block","reason":"autopilot 세션 연속 모드. .autopilot/ 상태 파일을 다시 읽고 다음 작업 하나를 수행해. 큐가 비었으면 재발굴(제품 축 포함)부터. 요약이나 보고 없이 바로 진행."}
JSON
exit 0
