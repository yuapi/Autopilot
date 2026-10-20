# ROADMAP (autopilot 레포 자체 개발)

last_scan: 2026-10-20
last_issue_check: 2026-10-20 (open 이슈 0건, open PR 0건)
last_retro: 2026-10-20

## 제품

### 이 소프트웨어는
사람 지시 없이 레포의 다음 개발 작업을 발굴·선택·구현·검증·기록하는 Claude Code 스킬(`autopilot`)과, 그것을 배포하는 플러그인 마켓플레이스. 사용자는 레포에서 스킬을 부르기만 하고, 스킬은 `.autopilot/` 상태 파일을 근거로 작업을 이어간다. 실행 방식은 세션 연속 모드(기본, Stop 훅으로 조기 종료 방지)와 드라이버 모드(`scripts/autopilot.sh`가 `claude -p`를 반복 호출) 두 가지.

### 기능 지도
| 기능 | 완성도 | 근거 |
|---|---|---|
| 상태 파일 루프 (ROADMAP/BACKLOG/LOG/PROPOSALS/CONFIG) | 완성 | SKILL.md, assets/ |
| 발굴: scan.sh(마커·보안 패턴) + 직접 실행·시나리오 + 완료 조건 | 완성 | scripts/scan.sh, SKILL.md Phase 1 |
| 발굴: 이슈 트래커·리뷰 코멘트 | 완성 | SKILL.md 1-E |
| 제안 · 회고 · 심화 발굴 후 중단 | 완성 | SKILL.md 1-F, Phase 0.5 |
| 출력 언어 설정 | 완성 | SKILL.md Language, CONFIG language |
| 작업 브랜치(local 모드에서 기본 브랜치 회피) | 완성 | scripts/workbranch.sh |
| 한 레포 한 루프, 소유 세션만 훅 차단 | 완성 | scripts/runlock.sh, assets/autopilot-stop.sh |
| 세션 연속 모드 Stop 훅 설치·갱신 | 부분 | 레포에 복사된 훅이 스킬 업데이트를 따라가지 않음 |
| 드라이버 (잠금·통합 사전 점검) | 완성 | scripts/autopilot.sh |
| 통합 정책 (local/branch/pr, 자동 머지·릴리스) | 완성 | SKILL.md 통합 정책 |
| 상태 요약 | 완성 | scripts/status.sh |
| 발굴 품질 평가 | 부분 | scripts/eval.sh, 예제 1개(Python CLI)뿐 |
| 레포 도구 (validate/bump/release/tests) | 완성 | scripts/, tests/ (테스트 203개) |

### 빠진 것
- 다른 종류의 평가 예제: 테스트가 없는 레포에서 "검증 수단 없음 → 최소 하네스 먼저" 규칙이 지켜지는지 측정할 수 없음

### 약한 것
- 레포에 복사된 Stop 훅(.claude/hooks/autopilot-stop.sh)이 스킬 업데이트 후에도 옛 버전으로 남음. 1.6~1.10 사본은 RUN 검사가 있어 "구버전 교체" 규칙에 걸리지 않고, 다른 세션을 계속 막음 (재현함)

### 관찰
- 2026-10-20 `scan.sh` (이 레포): 0건. `status.sh`: 소유 세션·활동 시각·통합 설정 표시 정상
- 2026-10-20 1.6.0 훅 사본 + 소유자가 있는 RUN + 다른 세션 ID → block (다른 세션이 갇힘). 사본에는 RUN 검사가 있어 SKILL.md의 교체 조건에 안 걸림
- 2026-10-20 `scan.sh`/`status.sh`를 빈 JS 레포에: 정상 종료, 안내 메시지 정상
- 2026-10-20 `eval.sh`: 4/5 → 5/5 (T-026)

### 시나리오
1. 1.8 사용자가 플러그인을 1.12로 업데이트하고 같은 레포에서 다시 실행: 레포의 훅 사본은 그대로 → 다른 세션 차단 버그가 남음 (T-027)
2. 테스트가 없는 JS 레포에서 처음 실행: 규칙상 하네스부터 만들어야 하지만 평가로 확인할 수단 없음 (T-028)
3. 유지보수자가 발굴 규칙을 고친 뒤 eval로 비교: 동작함. 예제가 하나라 한 종류의 결함만 측정 (T-028)

## 심화 발굴
2026-10-19 (T-018까지 완료 후 큐 비어 진행)
- 1 정적: SKILL.md 전체 재정독, 빠진 것·약한 것 비어 있음 확인 → 0건
- 2 실행: 새 시나리오(macOS 유지보수자의 릴리스, 1.5.x 사용자의 업그레이드, 실패 연속 후 재개) → 2건
- 3 품질 속성: 이식성(tac·timeout·GNU sed 의존) → T-019, 업그레이드 경로(구버전 훅 잔존) → T-020
- 4 외부 신호: open 이슈 0건, PROPOSALS 0건, 하지 않기로 한 것 재검토 이유 유지

## 진행 중인 기능
(없음)

## 유지보수 상태
- 검증 명령: `bash scripts/validate.sh` (JSON·frontmatter·버전·bash -n·claude plugin validate·tests/test_*.sh). 약 20초. 2026-10-19 PASS, 테스트 93개

## 배운 것
- 규칙이 길면 모델이 단계를 건너뛴다. 기계적으로 확인할 수 있는 것은 스크립트로, 판단이 필요한 단계는 ROADMAP에 증거를 남기는 완료 조건으로 강제한다 (eval 4/5 → 5/5)
- 훅·스크립트는 표준 입력이 닫히지 않는 환경을 가정한다. 입력을 읽을 때는 시간 제한을 둔다
- LOG·BACKLOG를 고칠 때 줄 끝 패턴 치환을 쓰지 않는다. 새 항목만 고치도록 정확한 줄을 지정한다 (지난 LOG 버전을 덮어쓴 적 있음)
- 클라우드 세션은 태그 push(403)·Release API(세션 정책)·원격 브랜치 삭제가 막힌다. PAT를 넣어도 마찬가지. 릴리스는 main 머지까지 하고 태그·Release는 사람이 로컬에서 `release.sh --catch-up`
- 스크립트를 바꾸면 경계 입력(빈 값·숫자 아님·도구 없음·하위 폴더) 테스트를 같이 쓴다. 직접 써보기에서 드라이버 결함 5건이 나왔다
- SKILL.md에 적힌 명령(롤백 등)은 tests/test_skill_rules.sh로 실제 실행해 검증한다. 문서 속 명령의 버그가 무한 재시도를 만들었다
- `.autopilot/` 상태를 되돌리거나 치우는 모든 git 명령은 pathspec으로 `.autopilot`을 제외해야 한다

## 하지 않기로 한 것
- GitHub Actions CI: 레포 규칙상 로컬 검증만 (CLAUDE.md)
