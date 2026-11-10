# ROADMAP (autopilot 레포 자체 개발)

last_scan: 2026-11-10
last_issue_check: 2026-11-10 (open 이슈 0건, open PR 0건)
last_retro: 2026-11-10T05:59Z

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
| 세션 연속 모드 Stop 훅 | 완성 | SKILL.md frontmatter hooks(1.16), 옛 사본 갱신·제거 hook.sh install/uninstall |
| 드라이버 (잠금·통합 사전 점검) | 완성 | scripts/autopilot.sh |
| 통합 정책 (local/branch/pr, 자동 머지·릴리스) | 완성 | SKILL.md 통합 정책 |
| 상태 요약 | 완성 | scripts/status.sh |
| 발굴 품질 평가 | 완성 | scripts/eval.sh: 예제 2개, 드라이버·세션 모드, 반복 실행, 규칙 검사, --grade |
| LOG 기록·최종 정지 장치 | 완성 | scripts/log.sh, scripts/finalstop.sh |
| 플러그인 명령 | 완성 | commands/status.md, stop.md |
| 레포 도구 (validate/bump/release/tests) | 완성 | scripts/, tests/ (테스트 203개) |

### 빠진 것
- 클라우드 세션에서 local 모드 결과 보존(경고만 있음, P-002 제안)

### 약한 것
- 세션 모드에서 작업 여러 개를 한 커밋으로 묶는 경우가 남음(T-041 후 eval 4회 중 1회). 규칙·log.sh 경고까지만 있음

### 관찰
- 2026-10-20 `scan.sh` (이 레포): 0건. `status.sh`: 소유 세션·활동 시각·통합 설정 표시 정상
- 2026-10-20 1.6.0 훅 사본 + 소유자가 있는 RUN + 다른 세션 ID → block (다른 세션이 갇힘). 사본에는 RUN 검사가 있어 SKILL.md의 교체 조건에 안 걸림
- 2026-10-20 `scan.sh`/`status.sh`를 빈 JS 레포에: 정상 종료, 안내 메시지 정상
- 2026-10-20 `eval.sh`: 4/5 → 5/5 (T-026)

- 2026-10-20 eval --mode session(todo): 수정 전 LOG 역순·시각 조작, 5작업 1커밋, 심화 발굴 생략 정지. log.sh·finalstop.sh 후 todo 3회·wordcount 1회 중 위반 1건(2작업 1커밋)
- 2026-10-20 eval 드라이버 3회: 8/8, 규칙 검사 전부 ok
- 2026-10-20 claude -p --plugin-dir: frontmatter Stop 훅은 스킬을 호출한 세션에서만 동작

### 시나리오
1. 클라우드 세션 사용자가 CONFIG 없이 플러그인으로 처음 실행: 작업은 되지만 local이라 push 안 됨 → 컨테이너 회수 시 전부 사라짐 (T-046, P-002)
2. 1.15 이하 사용자가 1.16+로 업데이트: 레포 훅 사본과 스킬 훅이 같이 돎 → 카운터 1회로 처리(T-031), 사본 제거 방법(T-032)
3. 오래 도는 세션이 "할 일 없음"이라 판단: 이전엔 근거 없이 멈출 수 있었음 → finalstop.sh가 빠진 조건을 알려 줌(T-041, T-045)

## 심화 발굴
2026-11-10T04:16Z (T-111~T-124 사이클 뒤 큐가 비어 진행)
- 1 정적: 이슈 0·PR 0·scan.sh 0건, shellcheck 없음(설치 안 됨). Never 목록·"사람만/항상" 규칙을 스크립트 거절과 대조(T-111~T-115 이후 남은 것은 판단이 필요한 질문·훅 우회·공개 인터페이스뿐). 빠진 것: P-001·P-002(제안, 결정 대기) 외 없음. 약한 것: 없음
- 2 실행: 새 시나리오 — 멈춘 뒤 다른 세션에서 재개(T-121), 거절된 최종 정지 뒤 상태 확인(T-122), language: ja의 최종 정지(T-124), 최종 정지 뒤 상태(문제 없음), 드롭한 작업의 LOG 상태·예산 재개·새 매니페스트(문제 없음)
- 3 품질 속성: 업그레이드 경로(1.54 이전 최종 정지, T-123), 이식성(새 awk·grep·hash-object 이식 가능), 관찰성(eval 모델 표시 T-120, STOP.refused T-122), 비용(eval 기본 모델 변경 → --model), 성능 변화 없음
- 4 외부 신호: 열린 이슈 0, 열린 PR 0, 제안 P-001·P-002 proposed(채택 없음), 하지 않기로 한 것(Actions CI) 이유 유지
- 결과: 이번 라운드 새 실질 작업 0건

2026-10-19 (T-018까지 완료 후 큐 비어 진행)
- 1 정적: SKILL.md 전체 재정독, 빠진 것·약한 것 비어 있음 확인 → 0건
- 2 실행: 새 시나리오(macOS 유지보수자의 릴리스, 1.5.x 사용자의 업그레이드, 실패 연속 후 재개) → 2건
- 3 품질 속성: 이식성(tac·timeout·GNU sed 의존) → T-019, 업그레이드 경로(구버전 훅 잔존) → T-020
- 4 외부 신호: open 이슈 0건, PROPOSALS 0건, 하지 않기로 한 것 재검토 이유 유지

2026-10-21 (T-083~T-094 사이클)
- 1 정적: scan.sh 0건, SKILL.md·README 전체 정독(T-073, T-089), 빠진 것은 P-002(제안)뿐, 약한 것 없음
- 2 실행: 새 시나리오 — 정체 없는 git(T-085), 첫 커밋 없는 레포(T-086), 공백·한글 경로·worktree(T-087), 예산 정지 후 재개(정상), 하위 폴더에서 /autopilot:status(T-094)
- 3 품질 속성: 성능(catch-up 49→13초, T-093), 오류 메시지(T-082), 도움말(T-081), 안전한 기본값(T-080), 관찰성(T-088), 상태 커밋(T-091, T-092)
- 4 외부 신호: 열린 이슈 0, 제안 P-001·P-002 결정 대기, 하지 않기로 한 것(Actions CI) 이유 유지

## 진행 중인 기능
(없음)

## 유지보수 상태
- 검증 명령: `bash scripts/validate.sh` (JSON·frontmatter·버전·bash -n·claude plugin validate·tests/test_*.sh). 약 20초. 2026-10-19 PASS, 테스트 93개

## 배운 것
- 규칙이 길면 모델이 단계를 건너뛰고 "작은 레포라 됐다"며 규칙을 푼다. 기계적으로 확인할 수 있는 것은 스크립트로 막고(task.sh·log.sh·finalstop.sh), 점수보다 eval 규칙 검사를 본다
- 훅·스크립트는 표준 입력이 닫히지 않는 환경을 가정하고 시간 제한을 둔다
- LOG는 log.sh로만 쓰고(손으로 쓴 시각은 지어낸 값이었다), LOG·BACKLOG는 정확한 줄만 고친다. Python으로 상태 파일을 쓸 때는 newline=""(CRLF 유지)
- 클라우드 세션은 태그 push(403)·Release API·원격 브랜치 삭제가 막힌다(PAT도 마찬가지). 릴리스는 main 머지까지, 태그·Release는 사람이 `release.sh --catch-up`. 릴리스 LOG는 바로 커밋한다
- 스크립트를 바꾸면 경계 입력(빈 값·숫자 아님·도구 없음·하위 폴더·비ASCII·공백 경로·파일 하나) 테스트를 같이 쓴다. CHANGELOG·주석에 scan.sh가 잡는 표식 단어를 쓰지 않는다
- SKILL.md에 적힌 명령은 tests/test_skill_rules.sh로 실제 실행해 검증한다. `.autopilot/`을 건드리는 git 명령은 pathspec으로 제외한다
- 훅·스킬 동작은 `claude -p --plugin-dir plugins/autopilot`(세션)과 드라이버 모드 둘 다로 실제 확인한다. 세션용 예산이 드라이버를 1회 후 멈추게 한 적 있다(T-076). 실제로 무엇을 읽었는지는 ~/.claude/projects/<실행 경로>/*.jsonl의 도구 호출로 확인한다(T-130: references/integration.md를 cat으로 읽음)
- 작업은 task.sh start로 먼저 잡고 구현한다. 스크립트가 거부하면 우회하지 말고 순서를 바로잡는다
- 시나리오에 Windows(CRLF)·배포 경로(계정 동기화가 version을 다시 씀)를 넣는다
- "처음 쓰는 환경"(정체 없는 git, 첫 커밋 없음, 끝나지 않는 명령)과 "잘못된 설정"(CONFIG 오타, 없는 scope·base_branch, 잘못된 branch_prefix)은 루프를 조용히 잘못 보낸다. 모르는 값은 가장 안전한 값으로 보고 경고하며, 진행할 수 없으면 고칠 방법과 함께 STOP한다. 같은 계열은 한 번에 끝까지 훑는다(T-098, T-100~T-102)
- 성능 10배 입력은 속도만이 아니라 출력 크기도 본다. 빠른 scan.sh도 400줄을 내면 규칙상 400작업이 됐다(T-099)
- 긴 백그라운드 작업(eval)을 기다릴 때 턴을 끝내지 않는다. Stop 훅이 변화 없는 차단 3번에 STOP을 쓴다. 코드는 먼저 커밋하고 포그라운드 대기 루프로 기다린다
- 규칙만 있고 스크립트가 강제하지 않는 곳은 결함이다. "사람만/항상/먼저/절대" 규칙과 Never 목록을 스크립트 거절과 대조한다(T-105~T-108, T-111~T-115: CONFIG·rename·LOG 순서·손으로 쓴 최종 정지·생성 파일·삭제·비밀·메이저 상승). 판단이 필요한 것(질문·훅 우회·공개 인터페이스)은 규칙으로 남는다
- eval에서 같은 항목을 반복해 놓치면 변동이 아니다. --keep으로 보존 실행의 ROADMAP·커밋을 읽어 원인을 본다: 규칙 공백(T-109 처음 상태)일 수도, 의도는 지켰는데 문구·채점이 틀렸을 수도(T-110) 있다. 새 예제는 결함이 서로 가리지 않는지 먼저 돌려 본다. eval은 --model을 지정해 돈다: 기본 모델이 바뀌어 비용이 5배가 되고 점수 비교가 깨졌다(T-120). 워커 재시작 중 0턴으로 끝난 실행은 무효로 다시 돌린다
- 파이프의 종료 코드를 믿지 않는다: `validate.sh | tail -1 && git commit`은 실패해도 커밋했다(T-118). 결과를 파일에 쓰고 rc를 따로 확인한다. 셸 따옴표가 복잡한 편집은 안전 검사가 해석하지 못해 막는다: 파일 편집은 Edit 도구로(T-130)

## 하지 않기로 한 것
- GitHub Actions CI: 레포 규칙상 로컬 검증만 (CLAUDE.md)
