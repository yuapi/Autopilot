# BACKLOG (autopilot 작업 큐)

next_id: 82

상태: open | in_progress | done | blocked
유형: fix | security | feature | enhance | perf | todo | test | cleanup | lint | docs | refactor

| ID | 유형 | 상태 | 시도 | 작업 | 완료 기준 | 출처 | 완료일 |
|---|---|---|---|---|---|---|---|
| T-001 | fix | done | 1 | Stop 훅을 실행 중일 때만 활성화(`.autopilot/RUN` 마커), `$CLAUDE_PROJECT_DIR` 기준 동작, LOG 진척 없이 연속 차단되면 STOP을 쓰고 해제 | 훅 테스트: RUN 없음→통과, RUN+STOP 없음→block, 진척 없는 N회→STOP 생성·통과 | 약한 것 | 2026-10-19 |
| T-002 | fix | done | 1 | 세션 연속 모드 Phase 0에서 `.gitignore`에 STOP·RUN·driver-logs·훅 상태 파일 보장 | SKILL.md 규칙 + 드라이버와 같은 항목 | 약한 것 | 2026-10-19 |
| T-003 | fix | done | 1 | 보안 발굴 소스를 조직 전용 MCP 이름에서 생태계 표준 도구(npm audit, pip-audit, cargo audit, govulncheck 등)로 일반화 | SKILL.md에 특정 조직 MCP가 필수로 남지 않음 | 공개 체크리스트 | 2026-10-19 |
| T-004 | enhance | done | 1 | 발굴 소스에 이슈 트래커·PR 리뷰 코멘트 추가 (gh/MCP가 있을 때 읽기 전용, 라벨로 유형 매핑) | SKILL.md 1-B 표와 우선순위 반영 | 빠진 것 | 2026-10-19 |
| T-005 | feature | done | 1 | 탐색적 실행·사용 시나리오 점검 발굴 단계 추가 (진입점 실행, 경계 입력, 오류 메시지 품질) | SKILL.md 1-A/1-B 반영, 결과가 fix/enhance 작업으로 이어지는 규칙 | 빠진 것 | 2026-10-19 |
| T-006 | feature | done | 1 | 기능 제안 기록 `.autopilot/PROPOSALS.md` (근거·영향·위험), 규칙 안이면 작업화, 밖이면 사람 판단 대기 | 템플릿 + SKILL.md 규칙 | 빠진 것 | 2026-10-19 |
| T-007 | enhance | done | 1 | 최종 중단 전 발굴 심화 단계(정적 → 실행·시나리오 → 이슈·제안 검토) 모두 수행해야 실질 0개 판정 | SKILL.md 중단 판정 조건 갱신, skill-design.md 근거 | 약한 것 | 2026-10-19 |
| T-008 | feature | done | 1 | 통합 정책 `.autopilot/CONFIG.md`: local(기본)/branch/pr, release off/auto. 레포의 CONTRIBUTING·CLAUDE.md 관례 우선 | 템플릿 + SKILL.md Phase 5 분기, 기본값은 기존 동작 유지 | 빠진 것 | 2026-10-19 |
| T-009 | perf | done | 1 | 긴 실행 컨텍스트: LOG는 최근 20개만 읽기, done 50개 초과 시 BACKLOG 아카이브 | SKILL.md Phase 0 규칙 | 약한 것 | 2026-10-19 |
| T-010 | enhance | done | 1 | 10작업마다 회고: 실패·blocked 원인 → ROADMAP "배운 것"·발굴 규칙 보정 | SKILL.md 규칙 + ROADMAP 템플릿 섹션 | 빠진 것 | 2026-10-19 |
| T-011 | enhance | done | 1 | 베이스라인 명령 탐색 확대(go/cargo/gradle/justfile/tox 등), 테스트 없는 레포는 최소 하네스 구축을 첫 작업으로 | SKILL.md Phase 0·1 반영 | 약한 것 | 2026-10-19 |
| T-012 | test | done | 1 | 드라이버 스크립트 테스트 (가짜 claude로 STOP·반복 한도·연속 크래시 종료 검증) | tests/test_driver.sh 통과 | 테스트 공백 | 2026-10-19 |
| T-013 | fix | done | 1 | 드라이버: 반복 인자 검증, `claude` 미설치 사전 확인, 로그 파일명 충돌, 크래시 한도 종료 코드 1, 하위 폴더에서 레포 루트로 이동, 대기 시간 설정(`AUTOPILOT_SLEEP`) | tests/test_driver.sh(T-012)로 각 경우 검증 | 관찰 2026-10-19 | 2026-10-19 |
| T-014 | fix | done | 1 | Phase 0 정리 단계가 `.autopilot/` 미커밋 상태를 stash하지 않도록 pathspec 제외, local 모드 실패 시 상태를 커밋 | test_skill_rules: SKILL.md의 정리 명령이 .autopilot 변경을 남기고 나머지만 치움 | 정적 검토 | 2026-10-19 |
| T-015 | docs | done | 1 | "반복 차단 규칙 (유일한 중단 조건)" 문구를 최종 중단 기준과 맞게 수정 | 모순 문구 0건 | 정적 검토 | 2026-10-19 |
| T-016 | enhance | done | 1 | frontmatter description을 현재 기능(이슈·제안·PR 통합·심화 발굴) 기준으로 갱신해 호출 조건 개선 | 1024자 이내, validate PASS | 약한 것 | 2026-10-19 |
| T-017 | test | done | 1 | validate.sh: SKILL.md가 참조하는 `assets/`·`scripts/` 파일이 실제로 있는지 검사 | 없는 파일을 참조하면 FAIL하는 테스트 | 빠진 것 | 2026-10-19 |
| T-018 | feature | done | 1 | `scripts/status.sh`: 완료·실패·blocked 수, 열린 작업, 최근 LOG, 결정 대기 제안, STOP 사유를 한 화면에 요약 | tests/test_status.sh 통과, README 반영 | 시나리오 2 | 2026-10-19 |
| T-019 | fix | done | 1 | macOS 기본 환경 호환: release.sh의 `tac`, validate.sh·테스트의 `timeout`, 테스트의 GNU `sed -i` 제거 | tac·timeout 없는 PATH에서 catch-up·validate 테스트 통과 | 심화 발굴 3 이식성 | 2026-10-19 |
| T-020 | enhance | done | 1 | status.sh가 구버전(1.5.x) Stop 훅 설치를 감지해 경고하고 교체 방법 안내, README에 업그레이드 절 | 테스트: RUN 검사 없는 훅이면 경고, 새 훅이면 경고 없음 | 심화 발굴 3 업그레이드 | 2026-10-19 |
| T-021 | feature | done | 1 | 스킬 행동 평가: 일부러 버그·빠진 기능·TODO를 심은 예제 레포(tests/fixtures/)에서 드라이버 1회 실행 후 BACKLOG가 심은 항목을 찾았는지 채점 (`claude plugin eval` 사용 가능 여부 먼저 조사) | 예제 레포·채점 스크립트·README 절, claude 없으면 건너뜀 | 빠진 것: 발굴 품질을 측정할 수단 없음 | 2026-10-20 |
| T-022 | enhance | done | 1 | 동시 실행 방지: 같은 레포에서 세션 두 개가 autopilot을 돌리면 BACKLOG·커밋이 충돌. RUN 마커에 세션 정보·시각을 쓰고, 다른 세션의 RUN이 살아 있으면 시작하지 않음 | SKILL.md 규칙 + 훅·status 테스트 | 시나리오: 두 터미널에서 실행 | 2026-10-20 |
| T-023 | enhance | done | 1 | 드라이버가 `.autopilot/CONFIG.md` 통합 모드가 pr일 때 필요한 도구(gh 또는 MCP)를 시작 전에 확인하고, 없으면 안내 후 local로 동작함을 출력 | test_driver에 경우 추가 | 품질 속성: 첫 실행 안내 | 2026-10-20 |
| T-024 | fix | done | 1 | status.sh 출력을 `| head`로 자르면 BrokenPipeError 트레이스가 노출됨 | 끊겨도 오류 출력 없음 테스트 | 관찰 2026-10-19 | 2026-10-19 |
| T-025 | fix | done | 1 | local 모드가 기본 브랜치(main 등)에 바로 커밋함 → workbranch.sh로 autopilot/<날짜> 브랜치로 옮김 | tests/test_workbranch.sh 통과 | 사람 요청 | 2026-10-20 |
| T-026 | fix | done | 1 | 발굴 단계 생략: eval에서 탐색적 실행·시나리오·기능 지도를 건너뛰고 코드 마커 검사를 안 해 TODO 마커를 놓침(4/5). 결정적인 `scripts/scan.sh`(마커·보안 패턴 grep)를 Phase 1에서 실행하게 하고, 발굴 후 ROADMAP 관찰·기능 지도가 비어 있으면 발굴 미완료로 보는 규칙 | scripts/eval.sh 5/5, scan.sh 테스트 | eval 2026-10-20 | 2026-10-20 |
| T-027 | fix | done | 1 | 레포에 복사된 Stop 훅이 스킬과 다르면 Phase 0에서 교체(바이트 비교), status.sh는 사본이 스킬 assets와 다르면 경고 | 1.6 훅 사본이 교체되고 다른 세션이 막히지 않는 테스트 | 관찰·시나리오 1 | 2026-10-20 |
| T-028 | feature | done | 1 | 두 번째 eval 예제: 테스트가 없는 작은 JS/셸 프로젝트. 첫 작업이 최소 테스트 하네스인지 채점 | eval.sh가 예제를 골라 돌림(--fixture), 첫 작업 유형 채점, test_eval 갱신 | 빠진 것·시나리오 2 | 2026-10-20 |
| T-029 | enhance | done | 1 | eval.sh --iterations N: 드라이버를 N회 돌려 둘째 작업부터의 동작(상태 이어받기, 같은 작업 반복 없음, 실패 없음)을 함께 보고·채점 | test_eval에 반복 경우, 실제 todo 3회 실행 | 시나리오: 밤새 드라이버 | 2026-10-20 |
| T-030 | feature | done | 1 | 플러그인 명령 /autopilot:status, /autopilot:stop (스킬 폴더 경로를 몰라도 상태 보기·멈추기) | claude plugin validate 통과, 명령이 status.sh·STOP을 호출하는 테스트, README | 사용성: 첫 실행 안내 | 2026-10-20 |
| T-031 | enhance | done | 1 | Stop 훅을 SKILL.md frontmatter에 선언(레포 복사·settings.json 수정 없이 스킬을 호출한 세션에서만 동작) | 두 설치 형태에서 frontmatter 명령이 block하는 테스트, 사본과 같이 돌 때 정체 카운터 1회, validate·plugin validate 통과 | T-030 발견(skill hooks) | 2026-10-20 |
| T-032 | feature | done | 1 | hook.sh uninstall: 1.16부터 필요 없는 레포 훅 사본과 settings.json 항목 제거(다른 훅 보존) | 제거·재실행·빈 키 정리·잘못된 JSON 거부 테스트, status.sh 안내 | 시나리오: 1.15 이하 사용자가 1.16으로 업그레이드 | 2026-10-20 |
| T-033 | fix | done | 1 | scan.sh: 일치하는 파일이 하나면 파일 이름 없이 줄 번호만 출력, 비ASCII 이름 파일은 git이 경로를 따옴표로 감싸 건너뜀 | 파일 하나·한글+공백 이름 회귀 테스트, validate 통과 | 탐색 실행(공백 경로 레포에서 scan.sh) | 2026-10-20 |
| T-034 | fix | done | 1 | Stop 훅 STOP 메모 문법("1 times") | validate 통과 | 탐색 실행(claude -p 실제 세션에서 훅 확인) | 2026-10-20 |
| T-035 | enhance | done | 1 | status.sh: 설치된 스킬 버전 표시, LOG가 더 새 버전으로 쓰였으면 경고 | 같은/새/옛 버전 테스트, validate 통과 | 관찰: 이 세션에 동기화된 플러그인이 1.10.2(레포는 1.15) | 2026-10-20 |
| T-036 | enhance | done | 1 | pr 통합: 자기 open PR을 매 작업 시작에 다시 확인(CI 통과 → 병합, 실패·충돌 → 같은 브랜치 fix 작업) | SKILL.md 규칙·skill-design 근거·규칙 테스트, validate 통과 | 정독: "CI 대기 중이면 PR을 열어 두고 다음 작업" 뒤에 다시 보는 규칙이 없음 | 2026-10-20 |
| T-037 | fix | done | 1 | 드라이버: 정상 종료지만 LOG·커밋이 안 바뀌는 실행을 무한 반복 → 3회 연속이면 STOP, 실행마다 LOG 항목 출력 | 가짜 claude idle/ok 테스트, validate 통과 | 정독: 훅에는 정체 한도가 있는데 드라이버엔 충돌 한도만 있음 | 2026-10-20 |
| T-038 | test | done | 1 | eval.sh --mode session: 플러그인으로 로드해 세션 모드 1회 실행, n개 작업 후 STOP, 스스로 끝나고 RUN을 지웠는지 채점 | 가짜 claude 테스트, 실제 todo 1회 실행 | 품질: 기본 모드(세션)가 eval로 측정되지 않음 | 2026-10-20 |
| T-039 | fix | done | 1 | 세션 모드에서 LOG 항목이 역순(위에 끼워 넣음)이고 시각이 지어낸 값 → LOG 항목을 실제 시각으로 파일 끝에 붙이는 스크립트와 규칙 | 스크립트 테스트(순서·시각 형식), eval session에서 LOG 순서·시각 확인 | eval session 실제 실행 관찰 | 2026-10-20 |
| T-040 | test | done | 1 | eval 채점에 규칙 위반 검사 추가: 작업마다 커밋 하나, LOG는 앞부분을 고치지 않음, 최종 정지 전 심화 발굴 4단계 기록 | 가짜 claude로 위반·정상 각각 채점 테스트, 실제 session eval 1회 | eval session 2회차: 5작업 1커밋, 심화 발굴 생략 정지, 마지막 커밋이 LOG 5줄 삭제 | 2026-10-20 |
| T-041 | fix | done | 1 | 세션 모드 규칙 위반 막기: 작업마다 커밋 후 다음 작업, 심화 발굴 4단계 없이 최종 정지 금지, 알려진 결함을 "사람에게" 남기지 말고 큐에 넣기 | eval --mode session 2회 이상에서 규칙 검사 전부 ok | T-040 규칙 검사(2회차 실행에서 3개 위반) | 2026-10-20 |
| T-042 | test | done | 1 | eval 채점 정규식: off-by-one이 "mark item N (1-based)" 표현을 못 받음 | 실제 표현 회귀 검사, 남긴 실행 재채점 10/10 | eval session 실행(9/10, 실제로는 찾았음) | 2026-10-20 |
| T-043 | fix | done | 1 | log.sh가 release 상태를 거부(SKILL.md 상태 목록에 없음) → release 상태 추가, 릴리스 항목 내용 규정 | SKILL.md 목록의 모든 상태를 log.sh가 받는 테스트 | 직접 사용(1.20.0 기록 실패) | 2026-10-20 |
| T-044 | docs | done | 1 | README 2종 파일 트리에 scan·hook·log·finalstop 스크립트와 commands/ 폴더 누락 | 트리가 모든 스크립트를 이름으로 언급하는 테스트 | 심화 발굴 3단계(문서 예제 정확성) | 2026-10-20 |
| T-045 | enhance | done | 1 | Stop 훅 block 메시지가 finalstop.sh를 안내(끝났다고 생각하면 무엇이 빠졌는지 기계적으로 확인) | 출력이 유효한 JSON이고 finalstop.sh를 언급하는 테스트 | 심화 발굴 3단계(사용성: 세션이 일찍 끝나려 할 때의 안내) | 2026-10-20 |
| T-046 | enhance | done | 1 | 클라우드 세션 + integration local이면 커밋이 컨테이너와 함께 사라짐 → Phase 0 첫 진입에 한 줄 안내·LOG, status.sh 경고 (CONFIG는 바꾸지 않음) | 클라우드/비클라우드/pr 모드 status 테스트, validate 통과 | 심화 발굴 2단계 새 시나리오: 클라우드 세션에서 플러그인 첫 실행 | 2026-10-20 |
| T-047 | enhance | done | 1 | scripts/task.sh start/done/fail: 진행 중 작업·커밋 안 된 코드가 있으면 start 거부, 자기 커밋(다른 작업 ID 없음)이 없으면 done 거부, fail은 open/3회째 blocked | task.sh 테스트, eval session 2회 규칙 검사 ok | ROADMAP 약한 것: 세션 모드 작업 묶기 잔존 | 2026-10-20 |
| T-048 | feature | done | 1 | pr 통합 GitLab 지원: origin이 GitLab이면 glab으로 MR·이슈, 드라이버 사전 점검도 glab | 드라이버 테스트(glab 있음/로그인 안 됨/없음), SKILL.md 규칙 | 빠진 것: 비슷한 도구는 GitHub·GitLab 둘 다 지원 | 2026-10-20 |
| T-049 | fix | done | 1 | task.sh가 거부할 때도 .gitignore에 .autopilot/.task를 먼저 추가함(거부는 아무것도 바꾸지 않아야 함) | 거부 시 .gitignore 변경 없음 테스트 | 직접 사용(T-048 start 거부 후 stash 충돌) | 2026-10-20 |
| T-050 | enhance | done | 1 | task.sh drop: 할 필요가 없어진 작업(재현 안 됨, 이미 고쳐짐)을 커밋 없이 blocked로 닫기 + 이유는 ROADMAP 하지 않기로 한 것 | drop 테스트, SKILL.md Phase 3 규칙 | 시나리오: 재현 안 되는 버그 작업 → done은 커밋을 요구, fail은 3번 재시도 | 2026-10-20 |
| T-051 | test | done | 1 | eval 예제 conventions: CONTRIBUTING이 커밋 형식·검증 명령을 정한 레포에서 규칙("레포 관례 우선")을 따르는지 채점(commit= 기대값) | 가짜 claude 채점 테스트, 실제 실행 1회 | 품질: "레포 관례 우선" 규칙을 재는 수단 없음 | 2026-10-20 |
| T-052 | fix | done | 1 | task.sh done이 상태만 고친 커밋(후속 작업 등록 "queue T-4")에 적힌 다른 작업 ID 때문에 거부함 | 상태 전용 커밋이 있어도 done 허용 테스트 | eval stats 실제 실행(같은 원인으로 채점 오탐) | 2026-10-20 |
| T-053 | feature | done | 1 | 모델 선택: 드라이버 AUTOPILOT_MODEL(claude -p --model로 전달), eval.sh --model | 가짜 claude로 --model 전달 테스트, README | 빠진 것: 무인 장시간 실행의 비용·품질을 모델로 조절할 수 없음 | 2026-10-20 |
| T-054 | test | done | 1 | Go eval 예제 kv: 실패 테스트·go vet 경고·패닉·무시된 오류·README의 없는 플래그 5개 결함, 기준선 탐색이 go test/go vet을 찾는지 | 가짜 claude 채점, 실제 실행 1회 | 품질(이식성): 예제가 Python·Node뿐 | 2026-10-20 |
| T-055 | fix | done | 1 | Phase 0 작업 트리 정리가 진행 중 작업의 변경까지 stash해 Phase 2 "이전 작업 끝내기" 검사를 무력화 → in_progress 행이 있으면 stash하지 않고 끝내거나 되돌리기 | SKILL.md 규칙 문장과 실행 검사(test_skill_rules) | 심화 발굴 1단계(규칙 정독: Phase 0 단계 2 ↔ Phase 2 첫 검사 충돌) | 2026-10-20 |
| T-056 | enhance | done | 1 | status.sh: 지금 진행 중인 작업(ID·제목·시작 후 경과 시간, .autopilot/.task 기준) 표시 | 진행 중/없음 테스트 | 심화 발굴 3단계(관찰성: "지금 뭐 하는 중"에 개수만 나옴) | 2026-10-20 |
| T-057 | feature | done | 1 | 세션 모드 작업 수 한도: runlock.sh start --tasks N이 RUN에 기록, task.sh done이 N개째에 STOP 작성, status.sh 표시 | runlock·task·status 테스트, SKILL.md 규칙 | 시나리오: "3개만 하고 멈춰" — 드라이버엔 최대 실행 수가 있는데 세션 모드엔 없음 | 2026-10-20 |
| T-058 | test | done | 1 | eval --mode session이 "N개 작업" 예산으로 요청하고, 예산으로 끝났는지(STOP이 task.sh가 쓴 것) 채점. 감시자는 N+1에서만 개입 | 가짜 claude 테스트, 실제 실행 1회 | T-057: 예산 기능이 eval로 계속 측정되지 않음 | 2026-10-20 |
| T-059 | docs | done | 1 | README 2종 "업데이트" 절: 계정 플러그인은 자동 동기화되지만 실행 중인 세션은 시작 때 버전을 유지 → 새 세션 시작, /autopilot:status로 버전 확인 | README 2종 | 관찰: 이 세션은 1.10.2를 로드했고 계정 동기화본은 1.27.0(generation 3) | 2026-10-20 |
| T-060 | enhance | done | 1 | eval.sh --fixture all: 모든 예제를 같은 옵션으로 돌리고 예제별 점수·규칙 결과 요약, 하나라도 실패하면 exit 1 | 가짜 claude 테스트, CLAUDE.md 안내 갱신 | CLAUDE.md: 발굴 규칙 변경 시 모든 예제 eval — 지금은 명령 4개 | 2026-10-20 |
| T-061 | enhance | done | 1 | task.sh: 칸 수가 틀린 BACKLOG 행(사람이 손으로 추가 등)에 기대 형식과 예시를 보여 주고 고치게 안내 | 7칸 행 거부 메시지 테스트 | 심화 발굴 2단계 시나리오: 사람이 Completed 칸 없이 행 추가 | 2026-10-20 |
| T-062 | feature | done | 1 | CONFIG scope: 모노레포에서 지정한 경로 안에서만 발굴·수정, task.sh done이 범위 밖 변경 거부, status.sh 표시 | task.sh·status 테스트, SKILL.md 규칙, CONFIG 템플릿 | 시나리오: 모노레포의 패키지 하나만 맡기기 | 2026-10-20 |
| T-063 | test | done | 1 | eval 예제 mono: CONFIG scope: pkg/a인 모노레포, 두 패키지 모두 결함. nofile= 기대값으로 pkg/b를 건드린 커밋이 없는지 채점 | 가짜 claude 채점, 실제 실행 1회 | T-062: scope를 실제 모델이 지키는지 측정 수단 없음 | 2026-10-20 |
| T-064 | fix | done | 1 | task.sh·archive.sh가 CRLF 상태 파일을 통째로 LF로 바꿈(Windows 체크아웃에서 파일 전체가 바뀜), log.sh는 CRLF 파일에 LF 줄을 붙임 → 원래 줄 끝 유지 | CRLF BACKLOG·LOG에서 세 스크립트 후 줄 끝 그대로인 테스트 | 심화 발굴 2단계 시나리오: Windows 사용자(core.autocrlf) | 2026-10-20 |
| T-065 | fix | done | 1 | core.autocrlf=true인 Windows에서 클론하면 .sh가 CRLF로 체크아웃되어 bash가 모든 스크립트에서 실패 → .gitattributes로 *.sh·hook·fixture 스크립트 LF 고정 | autocrlf=true 클론에서 스크립트가 LF이고 실행되는 테스트 | 심화 발굴 2단계 시나리오: Windows 사용자 플러그인 설치 | 2026-10-20 |
| T-066 | fix | done | 1 | log.sh가 현지 시각을 씀 → 로컬(KST)과 클라우드(UTC)를 오가면 LOG가 9시간 거꾸로 감(시간 순서 검사도 깨짐) → UTC + Z | TZ를 바꿔도 같은 시각, Z 표기 테스트, eval 시간 순서 검사가 Z를 읽음 | 심화 발굴 2단계 시나리오: 같은 레포를 로컬·클라우드에서 번갈아 | 2026-10-20 |
| T-067 | fix | done | 1 | 스킬 스크립트 7개가 python3만 찾음 → Windows Git Bash처럼 python만 있으면 전부 실패. python3 → python 순으로 찾고 없으면 분명한 오류 | python만 있는 PATH에서 status·task·archive·runlock·finalstop·hook 동작 테스트 | 심화 발굴 2단계 시나리오: Windows Git Bash | 2026-10-20 |
| T-068 | enhance | done | 1 | eval이 실행마다 비용·턴 수를 보여 줌(claude -p --output-format json의 total_cost_usd, num_turns 합계) | 가짜 claude JSON으로 합계 테스트, JSON 없으면 unknown | 관찰성: --model 비교에 비용이 없음 | 2026-10-20 |
| T-069 | feature | done | 1 | 플러그인 명령 /autopilot:run [N]: 스킬을 세션 모드로 시작, N이 있으면 작업 수 예산(--tasks N) | 명령 파일 검사, 실제 claude -p "/autopilot:run 1"로 1작업 후 멈춤 | 사용성: 예산 기능이 / 메뉴에서 안 보임 | 2026-10-20 |
| T-070 | docs | done | 1 | docs/skill-design.md에 작업 수 예산(STOP이 유일한 종료 신호와의 관계)·scope·UTC LOG 시각의 근거 추가 | 문서 | CLAUDE.md 규칙: 설계 의도에 닿는 변경은 skill-design.md에 이유 기록 — 1.27·1.28 변경이 빠져 있음 | 2026-10-20 |
| T-071 | perf | done | 1 | scan.sh가 파일 5000개 레포에서 2분 18초: 검색 6번마다 파일 목록을 파일당 프로세스 여러 개로 다시 만듦 → 목록을 한 번, 일괄로 | 5000개 레포에서 10초 미만, 기존 scan 테스트 전부 통과, 같은 결과 | 심화 발굴 3단계(성능: 입력 10배) | 2026-10-20 |
| T-072 | fix | done | 1 | CRLF로 저장된 CONFIG의 scope 값 끝에 \r가 붙어 task.sh done이 범위 안 변경도 전부 거부 | CRLF CONFIG에서 범위 안 허용·밖 거부 테스트 | 심화 발굴 2단계 시나리오: Windows에서 CONFIG 편집 | 2026-10-20 |
| T-073 | fix | done | 1 | SKILL.md 정독 결과: branch/pr 모드에서 task.sh done 검사보다 push·PR·병합이 먼저(거부될 커밋이 이미 병합됨), "사람에게 남기지 않기"와 scope 규칙 충돌, CONFIG 설명·gitignore 목록·예산 문장 위치 낡음 | 순서 규칙 검사 테스트, validate | 심화 발굴 1단계(SKILL.md 전체 정독) | 2026-10-20 |
| T-074 | test | done | 1 | validate.sh 2분 16초 중 test_eval.sh가 90초: eval 감시 주기 2초 고정, 가짜 세션 sleep 2.5초 → 주기를 AUTOPILOT_EVAL_POLL로, 테스트는 짧게 | test_eval 30초 미만, 모든 검사 그대로 통과 | 품질(성능): 매 작업 도는 검증이 느림 | 2026-10-20 |
| T-075 | feature | done | 1 | 드라이버 비용 한도 AUTOPILOT_MAX_COST(USD): 실행마다 claude JSON 결과의 비용을 더해 넘으면 STOP 후 종료, 실행마다 비용 출력, 로그는 읽을 수 있는 텍스트 유지 | 가짜 claude JSON으로 한도·합계·출력 테스트 | 빠진 것: 무인 장시간 실행을 비용으로 제한할 수 없음 | 2026-10-20 |
| T-076 | fix | done | 1 | 드라이버 프롬프트 "exactly one task"를 모델이 사람의 작업 수 예산으로 해석 → runlock --tasks 1 → task.sh가 STOP → 드라이버가 1회 후 멈춤. 드라이버 모드에서는 예산 무시(runlock·task.sh), 프롬프트 명확히 | AUTOPILOT_DRIVER=1에서 --tasks 무시·STOP 안 씀 테스트, 실제 드라이버 2회 | T-075 실제 드라이버 실행 | 2026-10-20 |
| T-077 | fix | done | 1 | 계정 동기화 플러그인의 SKILL.md는 version: '1.10.2'(작은따옴표) → log.sh "skill unknown", status.sh 버전 줄 없음 | 작은·큰따옴표·따옴표 없음 모두 파싱 테스트 | T-075 실제 드라이버 실행(LOG "skill unknown") | 2026-10-20 |
| T-078 | fix | done | 1 | CONFIG.md가 없으면 task.sh done이 셸 리디렉션 오류를 출력(tr < 없는 파일) | CONFIG 없이 done 출력에 오류 없음 테스트 | T-075 실제 드라이버 실행 | 2026-10-20 |
| T-079 | test | done | 1 | eval 드라이버 모드가 자체 프롬프트("Read SKILL.md…")를 써서 실제 드라이버 프롬프트 결함(T-076)을 못 잡음 → autopilot.sh의 PROMPT와 허용 도구를 그대로 쓰고 작업 사본을 --plugin-dir로 | 가짜 claude로 프롬프트 일치 테스트, 실제 드라이버 eval 2회 | 회고: T-076은 eval로 안 보였음 | 2026-10-20 |
| T-080 | enhance | done | 1 | 드라이버 권한 모드 표시: skip이면 크게 경고, 오타(skp 등)는 알 수 없는 값 경고 후 허용 목록, 기본은 한 줄 안내 | 세 경우 출력 테스트 | 심화 발굴 3단계(안전한 기본값·관찰성) | 2026-10-20 |
| T-081 | enhance | done | 1 | 스크립트 --help: status는 말없이 exit 2, archive는 bash cd 도움말, scan·finalstop·workbranch·autopilot은 엉뚱한 오류 → 모든 스킬·레포 스크립트가 -h/--help에 머리 주석의 사용법을 보여 주고 exit 0 | 모든 스크립트 --help 테스트 | 심화 발굴 3단계(사용성: 도움말) | 2026-10-20 |
