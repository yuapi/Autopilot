# 서브에이전트 활용 (사람의 요청)

slug: subagents
status: in progress
started: 2026-11-10

## Purpose
사람이 2026-11-10 대화에서 요청: 오토파일럿이 서브에이전트를 활용하고, 사용자 옵션으로 끌 수 있게(기본값 켬). 발굴(탐색 실행·시나리오·정적 검토)은 서로 독립이라 나눠 돌리기 좋고, 커밋 전 diff를 다른 눈으로 검토하면 Phase 4가 놓치는 것을 잡는다. 한 번에 작업 하나 원칙은 그대로다.

## Interface
- CONFIG 새 키 `subagents: on | off` (기본 on, 모르는 값은 off — 가장 안전)
- references/subagents.md: 언제 쓰는지(Phase 1 발굴 분담, Phase 4 diff 검토), 무엇을 맡기지 않는지(구현·커밋·push·상태 파일), 결과는 검증할 데이터
- 드라이버: subagents가 off가 아니면 허용 도구에 Agent 추가; eval 세션 모드도 같음
- status.sh: subagents 값 표시·오타 경고

## Data flow
Phase 1: 주 에이전트가 발굴 영역을 나눠 서브에이전트(최대 3)에 맡김 → 각자 근거 있는 발견 목록 반환 → 주 에이전트가 확인·중복 제거 후 BACKLOG에 씀
Phase 4: 커밋 전 서브에이전트 1개가 diff를 완료 기준·Never 목록에 대해 검토 → 주 에이전트가 확인해 고치거나 실패 처리

## Stages
| Stage | Task ID | Content | Done when | Status |
|---|---|---|---|---|
| 1/2 | T-131 | CONFIG 키, references/subagents.md, SKILL.md 안내·Never, 드라이버·eval 허용 도구, status.sh, 테스트 | validate PASS, 테스트 추가 | open |
| 2/2 | T-132 | eval --fixture all 전후 비교(--model 고정), 서브에이전트 사용 확인(세션 기록), README·설계 문서 | 점수 유지 이상·규칙 위반 0, README·skill-design 갱신 | 대기 |

## Decisions
- 구현은 맡기지 않음: 한 작업 = 한 커밋, task.sh 검사, 상태 파일 정합성이 주 에이전트 하나에 기대고 있어서
- 모르는 값은 off: 서브에이전트는 비용을 늘리므로 오타일 때 덜 쓰는 쪽이 안전
