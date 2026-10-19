# ROADMAP (autopilot 레포 자체 개발)

last_scan: 2026-10-19
last_issue_check: 2026-10-19 (open 이슈 0건, gh 미인증 → GitHub MCP로 확인)
last_retro: 2026-10-19

## 제품

### 이 소프트웨어는
사람 지시 없이 레포의 다음 개발 작업을 발굴·선택·구현·검증·기록하는 Claude Code 스킬(`autopilot`)과, 그것을 배포하는 플러그인 마켓플레이스. 사용자는 레포에서 스킬을 부르기만 하고, 스킬은 `.autopilot/` 상태 파일을 근거로 작업을 이어간다. 실행 방식은 세션 연속 모드(기본, Stop 훅으로 조기 종료 방지)와 드라이버 모드(`scripts/autopilot.sh`가 `claude -p`를 반복 호출) 두 가지.

### 기능 지도
| 기능 | 완성도 | 근거 |
|---|---|---|
| 상태 파일 기반 루프 (ROADMAP/BACKLOG/LOG/PROPOSALS/CONFIG) | 완성 | SKILL.md, assets/ |
| 발굴: 유지보수 축 (깨진 상태·보안·마커·테스트 공백) | 완성 | SKILL.md 1-B |
| 발굴: 제품 축 (기능 지도·직접 써보기·시나리오) | 완성 | SKILL.md 1-A |
| 발굴: 이슈 트래커·리뷰 코멘트 | 완성 | SKILL.md 1-E |
| 기능 제안 (PROPOSALS) | 완성 | SKILL.md 1-F |
| 심화 발굴 후 최종 중단 | 완성 | SKILL.md 실질 작업 판정 |
| 회고 | 완성 | SKILL.md Phase 0.5 |
| 검증 (베이스라인·불안정 테스트·무테스트 레포) | 완성 | SKILL.md Phase 0·4 |
| 세션 연속 모드 + Stop 훅 | 완성 | assets/autopilot-stop.sh, tests/test_hook.sh |
| 드라이버 모드 | 완성 | scripts/autopilot.sh, tests/test_driver.sh |
| 통합 정책 (local/branch/pr, 자동 머지·릴리스) | 완성 | SKILL.md 통합 정책, assets/CONFIG.md |
| 긴 실행 컨텍스트 관리 | 완성 | scripts/archive.sh |
| 실행 결과 요약 보기 | 완성 | scripts/status.sh |
| 레포 도구 (validate/bump/release/tests) | 완성 | scripts/, tests/ (88개) |

### 빠진 것
- SKILL.md가 참조하는 파일(assets·scripts)이 실제로 있는지 검사: 빠지면 스킬이 깨지는데 validate가 모름

### 약한 것
- Phase 0의 `git stash`가 `.autopilot/`의 미커밋 상태(실패한 작업의 attempts·LOG)까지 치워 무한 재시도가 다른 경로로 재발
- frontmatter description이 1.5 기준이라 이슈 처리·PR 통합 등 새 기능이 호출 조건에 반영되지 않음
- "반복 차단 규칙 (유일한 중단 조건)" 문구가 "실질 작업 판정 — 최종 중단의 유일한 기준"과 모순

### 관찰
- 2026-10-19 드라이버(`scripts/autopilot.sh`) 실행:
  - `autopilot.sh abc` → 매 반복 `integer expression expected`를 내고 무제한으로 돈다
  - `claude` 미설치 → 크래시로 세고 10초씩 3회 헛돈 뒤 종료 코드 0
  - 같은 초에 끝난 반복이 같은 로그 파일을 덮어쓴다
  - 레포 하위 폴더에서 실행하면 거부(루트로 이동 가능)
- validate.sh: 공백 포함 경로 PASS. bump.sh 인자 없음 → 사용법 출력·rc 1 (정상)

### 시나리오
1. 새 사용자: 마켓플레이스 추가 → 설치 → 자기 레포에서 "autopilot 실행" → 첫 발굴. 막힌 점: 무엇을 얼마나 할지(통합 방식·중단 조건)를 정할 방법이 없음 → T-008
2. 터미널 사용자: 드라이버로 밤새 실행 → 아침에 결과 확인. 막힌 점: 위 관찰의 드라이버 결함, 결과 요약을 한눈에 볼 수단 없음
3. 유지보수자: 이슈로 버그 신고 → 루프가 반영. T-004로 해결

## 심화 발굴
(아직 없음)

## 진행 중인 기능
(없음)

## 유지보수 상태
- 검증 명령: `bash scripts/validate.sh` (JSON·frontmatter·버전·bash -n·claude plugin validate·tests/test_*.sh). 약 20초. 2026-10-19 PASS, 테스트 93개

## 배운 것
- 클라우드 세션은 태그 push(403)·원격 브랜치 삭제가 막힌다. 릴리스는 main 머지까지 하고 태그는 `release.sh --catch-up`으로 로컬에서 처리
- 스크립트를 바꾸면 경계 입력(빈 값·숫자 아님·도구 없음·하위 폴더) 테스트를 같이 쓴다. 직접 써보기에서 드라이버 결함 5건이 나왔다
- SKILL.md에 적힌 명령(롤백 등)은 tests/test_skill_rules.sh로 실제 실행해 검증한다. 문서 속 명령의 버그가 무한 재시도를 만들었다
- `.autopilot/` 상태를 되돌리거나 치우는 모든 git 명령은 pathspec으로 `.autopilot`을 제외해야 한다

## 하지 않기로 한 것
- GitHub Actions CI: 레포 규칙상 로컬 검증만 (CLAUDE.md)
