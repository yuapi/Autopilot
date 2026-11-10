# 클라우드 세션에서 local 모드 결과 보존 (P-002)

slug: cloud-push
status: in progress
started: 2026-11-10

## Purpose
채택된 P-002. 클라우드 세션(CLAUDE_CODE_REMOTE=true)은 컨테이너가 회수되면 push 안 된 커밋이 사라진다. CONFIG에 integration이 없는 사용자의 작업이 전부 사라지므로, 그 경우에만 작업 브랜치를 push한다.

## Interface
- CONFIG에 `integration:`이 없고 클라우드 세션이면: local 모드처럼 동작하되(workbranch.sh의 `autopilot/<날짜>` 브랜치, PR·병합 없음) 매 작업 끝에 그 작업 브랜치만 push
- 새 명령: `workbranch.sh --push` — 현재 브랜치가 기본 브랜치가 아니고 origin이 있을 때만 `git push -u origin <브랜치>`. 기본 브랜치·분리된 HEAD에서는 거절
- CONFIG에 `integration: local`이 명시돼 있으면 지금처럼 push하지 않음(사람이 고른 값)
- 로컬 터미널(CLAUDE_CODE_REMOTE 없음)은 영향 없음

## Data flow
Phase 5 6(상태 커밋) 뒤 → 조건 확인 → workbranch.sh --push → 막히면 LOG에 기록하고 계속

## Stages
| Stage | Task ID | Content | Done when | Status |
|---|---|---|---|---|
| 1/2 | T-125 | workbranch.sh --push(기본 브랜치 거절, origin 없으면 안내), SKILL.md Phase 0·5와 상태 파일 표, status.sh 클라우드 경고 문구 | test_workbranch·test_status·test_skill_rules 추가 검사, validate PASS | done |
| 2/2 | T-126 | 드라이버 안내, README 2종, docs/skill-design.md("CONFIG로만 권한을 넓힌다" 원칙의 예외와 이유), 전체 통합 확인 | 가짜 origin 레포로 세션 흐름 통합 테스트, README·설계 문서 갱신 | open |

## Decisions
- 브랜치 방식(작업마다 브랜치·PR)이 아니라 local 모드의 작업 브랜치 하나만 push: 원격에 생기는 것이 가장 적고, 기본 브랜치·PR·병합은 그대로 금지
