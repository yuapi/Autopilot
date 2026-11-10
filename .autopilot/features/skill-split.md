# SKILL.md를 핵심 루프와 참조 파일로 분리 (P-001)

slug: skill-split
status: done
started: 2026-11-10

## Purpose
채택된 P-001. SKILL.md 431줄·47.6KB가 호출마다 통째로 로드된다(약 12~15k 토큰). 상황에 따라서만 필요한 절을 참조 파일로 옮겨 비용을 줄인다.

## Interface
- `skills/autopilot/references/integration.md`: 통합 정책(branch·pr 모드, PR 규칙, 릴리스) — integration이 local이 아닐 때만 읽음
- `skills/autopilot/references/operations.md`: Stop 훅 상세·대체 설치, 드라이버, 상태 확인, 레포 자체 Stop 훅 — 해당 상황에서만 읽음
- SKILL.md에는 각 절 자리에 "언제 읽는지" 한 줄과 경로를 남김. 규칙 내용은 바꾸지 않고 위치만 이동

## Data flow
SKILL.md(핵심 루프) → 조건이 맞으면 references/*.md를 Read

## Stages
| Stage | Task ID | Content | Done when | Status |
|---|---|---|---|---|
| 1/3 | T-127 | 통합 정책을 references/integration.md로, tests/test_skill_rules.sh가 SKILL.md+references를 함께 검사 | validate PASS, eval pr 관련 규칙 검사 유지 | done |
| 2/3 | T-128 | Stop 훅 상세·드라이버·상태·레포 훅을 references/operations.md로 | validate PASS | done |
| 3/3 | T-129 | eval --fixture all 전후 비교(--model 고정), docs/skill-design.md·README 레이아웃, SKILL.md 크기 전후 | 점수 유지·규칙 위반 0, 크기 감소 기록 | done |

## Decisions
- 생략 위험이 제안의 위험 항목: 핵심 루프(Phase 0~5, Never)는 SKILL.md에 남기고, 참조 파일은 "이 조건이면 읽는다"를 SKILL.md에 명시
