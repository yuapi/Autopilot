# BACKLOG (autopilot 작업 큐)

next_id: 44

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
