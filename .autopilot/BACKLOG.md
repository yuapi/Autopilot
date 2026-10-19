# BACKLOG (autopilot 작업 큐)

next_id: 19

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
| T-016 | enhance | open | 0 | frontmatter description을 현재 기능(이슈·제안·PR 통합·심화 발굴) 기준으로 갱신해 호출 조건 개선 | 1024자 이내, validate PASS | 약한 것 | |
| T-017 | test | open | 0 | validate.sh: SKILL.md가 참조하는 `assets/`·`scripts/` 파일이 실제로 있는지 검사 | 없는 파일을 참조하면 FAIL하는 테스트 | 빠진 것 | |
| T-018 | feature | open | 0 | `scripts/status.sh`: 완료·실패·blocked 수, 열린 작업, 최근 LOG, 결정 대기 제안, STOP 사유를 한 화면에 요약 | tests/test_status.sh 통과, README 반영 | 시나리오 2 | |
