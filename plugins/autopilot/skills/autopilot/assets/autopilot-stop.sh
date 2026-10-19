#!/usr/bin/env bash
# autopilot Stop 훅: .autopilot/STOP이 없으면 세션 종료를 막고 다음 작업을 지시한다.
# 해제: .autopilot/STOP 생성 또는 .claude/settings.json에서 이 훅 제거
if [ -f .autopilot/STOP ]; then
  exit 0
fi
cat << 'JSON'
{"decision":"block","reason":"autopilot 세션 연속 모드. .autopilot/ 상태 파일을 다시 읽고 다음 작업 하나를 수행해. 큐가 비었으면 재발굴(제품 축 포함)부터. 요약이나 보고 없이 바로 진행."}
JSON
exit 0
