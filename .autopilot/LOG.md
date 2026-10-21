# LOG (autopilot 실행 기록, append only)

## 2026-10-19T09:25 | - | discover | skill 1.5.1
- 레포 자체 autopilot 상태 초기화. 제품 이해·기능 지도 작성, T-001~T-012 발굴
- 막힘: 클라우드 세션에서 태그 push(403)·원격 브랜치 삭제 거부 → 태그는 `release.sh --catch-up`으로 사람이 처리

## 2026-10-19T09:32 | T-001,T-002 | done | skill 1.5.1
- 변경: assets/autopilot-stop.sh, SKILL.md(Phase 0·Stop 훅·중단), scripts/autopilot.sh, docs/skill-design.md, README, tests/test_hook.sh
- 검증: validate PASS, test_hook 17 통과
- 후속: 없음

## 2026-10-19T09:33 | T-003 | done | skill 1.5.1
- 변경: SKILL.md 1-B 보안 행
- 검증: validate PASS, 레포 전체에서 조직 전용 MCP 이름 0건
- 후속: 없음

## 2026-10-19T09:35 | T-004 | done | skill 1.6.0
- 변경: SKILL.md(Phase 1 조건, 1-B, 1-C, 1-E 신설, Phase 2 정렬, Phase 5 커밋), assets/ROADMAP.md, docs/skill-design.md, README
- 검증: validate PASS
- 태그 대기: v1.5.1, v1.6.0 (클라우드 세션 태그 push 403). 로컬에서 release.sh --catch-up 필요
- 후속: 없음

## 2026-10-19T09:37 | T-005 | done | skill 1.6.0
- 변경: SKILL.md(1-A 5·6, 탐색적 실행 규칙, 1-B), assets/ROADMAP.md, docs/skill-design.md, README
- 검증: validate PASS. 이 레포에 적용해 드라이버 결함 5건 관찰
- 후속: T-013 추가 (드라이버 결함)

## 2026-10-19T09:40 | T-013,T-012 | done | skill 1.6.0
- 변경: scripts/autopilot.sh, tests/test_driver.sh, scripts/validate.sh, README
- 검증: validate PASS, test_driver 22 통과. 수정 전 드라이버로 돌리면 숫자 아닌 인자에서 무한 반복으로 타임아웃(결함 재현)
- 후속: 없음

## 2026-10-19T09:41 | T-007 | done | skill 1.6.0
- 변경: SKILL.md(실질 작업 판정), assets/ROADMAP.md, docs/skill-design.md, README
- 검증: validate PASS
- 후속: 없음

## 2026-10-19T09:43 | T-011 | done | skill 1.6.0
- 변경: SKILL.md Phase 0-3, docs/skill-design.md
- 함께 수정: Phase 4 롤백이 .autopilot까지 되돌려 attempts가 사라지던 버그(무한 재시도), 실패 후 세션 연속 모드에서 멈추던 문제. tests/test_skill_rules.sh (수정 전 2건 실패 재현)
- 검증: validate PASS
- 후속: 없음

## 2026-10-19T09:45 | T-010 | done | skill 1.7.0
- 변경: SKILL.md(Phase 0.5, LOG 상태 값), assets/ROADMAP.md(last_retro, 배운 것), docs/skill-design.md, README
- 검증: validate PASS
- 태그 대기: v1.5.1, v1.6.0, v1.7.0
- 후속: 없음

## 2026-10-19T09:46 | T-006 | done | skill 1.7.0
- 변경: SKILL.md(상태 파일, 1-E, 1-F, 심화 4단계, Phase 3, 하지 않는 것, STOP 요약), assets/PROPOSALS.md, docs/skill-design.md, README. 이 레포에도 PROPOSALS.md 생성
- 검증: validate PASS
- 후속: 없음

## 2026-10-19T09:48 | T-008 | done | skill 1.7.0
- 변경: SKILL.md(상태 파일, Phase 0·5, 통합 정책 절, 하지 않는 것, 템플릿), assets/CONFIG.md, docs/skill-design.md, README, tests/test_skill_rules.sh. 이 레포에 CONFIG.md(pr/auto) 생성
- 검증: validate PASS
- 후속: 없음

## 2026-10-19T09:50 | T-009 | done | skill 1.7.0
- 변경: SKILL.md(Phase 0-1, 발굴 규칙), scripts/archive.sh, tests/test_archive.sh, docs/skill-design.md
- 검증: validate PASS, test_archive 16 통과(행·항목 손실 없음, 재실행 이어 붙이기)
- 후속: 큐 비어 있음 → 재발굴

## 2026-10-19T09:52 | - | retro | skill 1.7.0
- 구간: T-001~T-013 (11개 항목) done 11 / 실패 0 / blocked 0
- 발견: 직접 써보기와 명령 실행 테스트가 실제 버그(드라이버 5건, 롤백 무한 재시도)를 찾음. 정적 읽기만으로는 놓쳤던 것
- 환경: 태그 push·원격 브랜치 삭제 정책 거부 → 배운 것에 기록

## 2026-10-19T09:52 | - | discover | skill 1.7.0
- 큐 비어 재발굴. 정적 검토(SKILL.md 전체 정독)·시나리오 재검토·이슈 확인(0건)
- 추가: T-014(fix) T-015(docs) T-016(enhance) T-017(test) T-018(feature)

## 2026-10-19T09:53 | T-014,T-015 | done | skill 1.7.0
- 변경: SKILL.md(Phase 0-2, Phase 4, 반복 차단 규칙 제목), tests/test_skill_rules.sh
- 검증: validate PASS. 기존 git stash가 attempts 1→0으로 되돌림을 재현, 새 명령은 유지
- 후속: 없음

## 2026-10-19T09:54 | T-016 | done | skill 1.7.0
- 변경: SKILL.md frontmatter, marketplace.json·plugin.json description, scripts/validate.sh, tests/test_scripts.sh
- 검증: validate PASS (377자), 1100자 description FAIL 테스트
- 후속: 없음

## 2026-10-19T09:55 | T-018 | done | skill 1.7.0
- 변경: scripts/status.sh, tests/test_status.sh, SKILL.md(상태 확인), README
- 검증: validate PASS, test_status 15 통과, 이 레포에서 실행 확인
- 후속: 없음

## 2026-10-19T09:57 | T-017 | done | skill 1.7.0
- 변경: scripts/validate.sh, tests/test_scripts.sh, SKILL.md 1-D
- 검증: validate PASS(참조 10개). 참조 파일 삭제 시 FAIL, 미참조 템플릿은 WARN 확인
- 발견: feature-template.md가 SKILL.md에서 한 번도 언급되지 않아 쓰이지 않고 있었음
- 후속: 큐 비어 있음 → 재발굴

## 2026-10-19T10:02 | - | discover | skill 1.8.0
- 큐 비어 심화 발굴 4단계 수행(ROADMAP 심화 발굴 참조). 추가: T-019(fix) T-020(enhance)

## 2026-10-19T10:02 | T-019 | done | skill 1.8.0
- 변경: scripts/release.sh, scripts/validate.sh, tests/lib.sh, tests/test_driver.sh, tests/test_scripts.sh, tests/test_portability.sh
- 검증: validate PASS(테스트 118개). 수정 전 release.sh는 tac 없는 PATH에서 catch-up 실패(2건) 재현
- 후속: 없음

## 2026-10-19T10:04 | T-020 | done | skill 1.8.0
- 변경: scripts/status.sh, tests/test_status.sh, README.md, README.ko.md
- 검증: validate PASS, test_status 17 통과(구버전 훅 경고, 새 훅 무경고)
- 후속: 큐 비어 있음

## 2026-10-19T10:07 | - | discover | skill 1.8.1
- 1.8.1 릴리스 후 다음 세션을 위한 발굴: T-021(feature, 발굴 품질 평가) T-022(enhance, 동시 실행 방지) T-023(enhance, 드라이버 통합 도구 확인)
- 태그 대기: v1.5.1 v1.6.0 v1.7.0 v1.8.0 v1.8.1 → 로컬에서 `bash scripts/release.sh --catch-up`

## 2026-10-19T10:09 | T-024 | done | skill 1.8.1
- 변경: scripts/status.sh, tests/test_status.sh
- 검증: validate PASS, 수정 전 실패·수정 후 통과 확인
- 출처: 직접 써보기(`status.sh | head`)

## 2026-10-19T10:54 | - | release | skill 1.8.2
- 1.8.2 main 머지·역병합 완료(PR #33, #34). release.sh에 gh API 대체 경로 추가(PR #32)
- 막힘: 사람이 PAT를 추가했으나 Release API가 "Creating, editing, or deleting releases is not permitted for this session type"(403)로 거부. 세션 정책이므로 우회하지 않음. 원격 태그·Release 0개 유지 확인
- 태그 대기: v1.5.1 v1.6.0 v1.7.0 v1.8.0 v1.8.1 v1.8.2 → 로컬에서 `bash scripts/release.sh --catch-up`

## 2026-10-20T01:01 | - | release | skill 1.9.0
- 사람 요청: 기본 영어 + 다국어 지원. 스킬 규칙·템플릿·스크립트 영어화와 language 설정(PR #36), 레포 도구·테스트·문서 영어화(PR #37)
- 이 레포의 .autopilot 기록은 language: auto에 따라 기존 언어(한국어) 유지
- 태그 대기: v1.5.1 ~ v1.8.2, v1.9.0 → 로컬에서 `bash scripts/release.sh --catch-up`

## 2026-10-20T01:11 | T-025 | done | skill 1.9.0
- 변경: scripts/workbranch.sh(신규), SKILL.md Phase 0·통합 정책 표, assets/CONFIG.md(local_branch), README, docs/skill-design.md, tests/test_workbranch.sh
- 검증: validate PASS, test_workbranch 17 통과(레포 밖 실행 버그를 테스트가 잡아 수정)
- 참고: 사람은 1.5에 있던 기능이라 했으나 레포에 남은 1.5.0 원본(SKILL.md·드라이버)에는 없음. README의 '전용 브랜치에서 시작' 안내만 있었음

## 2026-10-20T09:51 | T-022 | done | skill 1.10.2
- 변경: scripts/runlock.sh(신규), assets/autopilot-stop.sh(소유 세션만 차단, stdin 2초 제한), scripts/autopilot.sh(driver.lock·세션 루프 감지), scripts/status.sh(소유 세션·활동 시각), SKILL.md, README, docs/skill-design.md, 테스트(runlock 21, hook +5, driver +9, status +2)
- 검증: validate PASS(테스트 169개)
- 발견: 루프가 도는 동안 같은 레포에서 연 다른 세션도 훅에 막히던 버그를 함께 수정. 닫히지 않는 stdin에서 훅이 멈추는 문제를 테스트가 잡아 read -t로 수정
- 이 레포: Phase 0에서 Stop 훅 설치(.claude/), RUN을 이 세션 소유로 기록

## 2026-10-20T09:55 | T-023 | done | skill 1.11.0
- 변경: scripts/autopilot.sh(통합 사전 점검), SKILL.md 드라이버 절, README, tests/test_driver.sh(+7)
- 검증: validate PASS
- 릴리스: 1.11.0 main 반영(PR #48, #49). 태그·Release는 세션 정책으로 막힘 → 태그 대기 v1.11.0. 사람이 로컬 catch-up으로 v1.5.1~v1.10.2 태그·Release 10개 생성 완료 확인

## 2026-10-20T10:02 | T-021 | done | skill 1.11.1
- 변경: scripts/eval.sh(신규), tests/eval/(결함 5개 예제 레포·expected.txt), tests/test_eval.sh(가짜 claude로 12개), README 2종, CLAUDE.md(발굴 규칙 변경 시 eval 점수 기록), .gitignore
- 검증: validate PASS. 실제 eval 1회: 4/5(0.80), 42초, 커밋 1개(T-001 off-by-one 수정)
- 발견: 스킬이 탐색적 실행·시나리오·기능 지도·코드 마커 검사를 건너뜀 → T-026. claude plugin eval은 있으나 case.yaml 스키마 문서가 없어 자체 하네스로 구현
- 발견: 예제 레포에 __pycache__가 섞여 커밋됨 → 예제 .gitignore 추가, eval이 복사 후 제거

## 2026-10-20T10:08 | T-026 | done | skill 1.11.1
- 변경: scripts/scan.sh(신규, 주석 속 마커·보안 패턴, fixture/testdata·ignore 표시 제외), SKILL.md(Phase 1 scan.sh·발굴 완료 조건·1-C 예외·생성 파일 커밋 금지), tests/test_scan.sh(22), scripts/eval.sh(로그를 레포 밖에), docs/skill-design.md
- 검증: validate PASS. eval 전 4/5(관찰·기능 지도 비어 있음) → 규칙 1차 4/5(관찰·시나리오 채움, 마커는 Missing에만) → 1-C 보강 후 5/5
- 이 레포: scan.sh 결과 0건(예제 레포는 fixture로 제외, 설명용 두 곳은 ignore 표시)

## 2026-10-20T10:11 | - | retro | skill 1.12.0
- 구간: T-014~T-026 중 12개 항목 done 12 / 실패 0 / blocked 0
- 원인 분류할 실패 없음. 배운 것 3개 추가(단계 생략은 스크립트·완료 조건으로, stdin 시간 제한, LOG 정확한 줄 편집)

## 2026-10-20T10:11 | - | discover | skill 1.12.0
- 큐 비어 재발굴. scan.sh 0건, 이슈·PR 0건, 직접 실행(훅 사본 재현·status·scan), 시나리오 3개
- 추가: T-027(fix, 훅 사본 갱신) T-028(feature, 테스트 없는 레포 eval 예제)
- 태그 대기: v1.11.0 v1.11.1 v1.12.0

## 2026-10-20T10:12 | T-027 | done | skill 1.12.0
- 변경: scripts/hook.sh(신규, 설치·갱신·settings 병합), SKILL.md(Phase 0·훅 설치 절), scripts/status.sh(사본이 다르면 안내, 상대 경로 실행 버그도 수정), tests/test_hook_install.sh(22), README 2종, docs/skill-design.md
- 검증: validate PASS. 1.6.0 훅 사본이 다른 세션을 막는 것을 재현 → 교체 후 막지 않음

## 2026-10-20T10:20 | T-028 | done | skill 1.13.0
- 변경: tests/eval/fixture-wordcount(테스트 없는 Node CLI)·.expected, expected.txt → fixture-todo.expected, scripts/eval.sh(--fixture, type= 채점), tests/test_eval.sh(+5), SKILL.md(검증 수단 없으면 하네스를 fix보다 먼저), README 2종, CLAUDE.md, docs/skill-design.md
- 검증: validate PASS. eval wordcount 2/3(규칙대로 fix 먼저 → 검증 없는 커밋) → 규칙 수정 후 3/3(node:test 하네스 먼저). todo 4/5(채점 정규식이 'DB file missing' 어순을 못 받음) → 정규식 보강 후 5/5

## 2026-10-20T10:23 | - | discover | skill 1.14.0
- 큐 비어 재발굴. scan.sh 0건, 이슈·PR 0건. 시나리오: 밤새 드라이버(2회째 이후 동작 미측정), 플러그인 사용자가 status.sh 경로를 모름, SKILL.md 길이와 단계 생략
- 추가: T-029(enhance, eval 반복 실행) T-030(feature, 플러그인 명령). 제안 P-001(SKILL.md 분리, 구조 개편이라 사람 결정 대기)
- 태그 대기: v1.11.0 v1.11.1 v1.12.0 v1.13.0 v1.14.0

## 2026-10-20T10:26 | T-029 | done | skill 1.14.0
- 변경: scripts/eval.sh(--iterations, 반복 검사 3개), tests/test_eval.sh(+8), README 2종
- 검증: validate PASS. 실제 todo 3회: 8/8, 111초, 우선순위 순서(fix→fix→security)로 서로 다른 작업 3개, 테스트 통과, 작업 트리 깨끗
- 이 사이클 발굴 기록(T-029, T-030, 제안 P-001)도 이 PR에 포함

## 2026-10-20T10:29 | T-030 | done | skill 1.14.0
- 변경: plugins/autopilot/commands/status.md·stop.md(신규), scripts/runlock.sh stop, SKILL.md 상태 확인 절, README 2종, docs/plugin-structure.md, tests(runlock +5, skill_rules 명령 검사)
- 검증: validate PASS(claude plugin validate 포함). claude -p "/autopilot:status"·"/autopilot:stop" --plugin-dir로 실제 실행해 동작 확인(${CLAUDE_PLUGIN_ROOT}가 명령 파일에서도 치환됨)
- 발견: 스킬 frontmatter에 훅을 선언할 수 있다는 흔적(skill hooks). 레포에 훅을 복사하지 않아도 될 가능성 → 다음 발굴에서 조사

## 2026-10-20T10:40 | T-031 | done | skill 1.15.0
- 변경: SKILL.md(frontmatter hooks.Stop, Phase 0는 기존 사본만 갱신, "The Stop hook" 절), assets/autopilot-stop.sh(transcript 크기로 같은 종료를 1회만 집계), tests/test_hook.sh(+7), README 2종, docs/skill-design.md·plugin-structure.md
- 검증: validate PASS(claude plugin validate 포함). CLAUDE_PLUGIN_ROOT=플러그인 루트·스킬 폴더 둘 다에서 frontmatter 명령이 block
- 판단: 이 레포의 .claude 훅 사본은 대체 수단으로 남김(두 훅이 같이 돌아도 카운터는 1회)

## 2026-10-20T10:50 | - | release | skill 1.16.0
- 1.16.0 릴리즈: release/1.16.0 → main 병합, main → develop 역병합
- 태그 대기: v1.16.0 (git 태그 push 403, Release API "not permitted for this session type"). 누적 대기 v1.11.0~v1.16.0

## 2026-10-20T10:52 | - | discover | skill 1.16.0
- 큐 비어 재발굴. scan.sh 0건, 이슈 0건. 시나리오: 1.15 이하에서 1.16으로 업그레이드한 사용자 — 레포 사본이 남아 스킬 훅과 같이 돔(카운터는 T-031로 1회), 지울 방법 없음
- 추가: T-032(feature, hook.sh uninstall)

## 2026-10-20T10:58 | T-032 | done | skill 1.16.0
- 변경: scripts/hook.sh(uninstall), scripts/status.sh(사본 있으면 uninstall 안내), tests/test_hook_install.sh(+9), SKILL.md, README 2종
- 검증: validate PASS
- 판단: 이 레포의 .claude 사본은 아직 지우지 않음(다른 세션에 동기화된 플러그인이 1.16 미만이면 사본이 유일한 훅)

## 2026-10-20T11:05 | T-033 | done | skill 1.16.0
- 발견: 탐색 실행에서 파일 하나짜리 레포의 scan.sh 출력이 `1:# ...`(파일 이름 없음). grep에 파일이 하나만 넘어가면 이름을 생략함. 한글 이름 파일은 core.quotePath 때문에 아예 빠짐
- 변경: scripts/scan.sh(grep -H, git -c core.quotePath=false), tests/test_scan.sh(+1), CHANGELOG
- 검증: validate PASS

## 2026-10-20T11:12 | - | release | skill 1.17.0
- 1.17.0 릴리즈: release/1.17.0 → main, main → develop 역병합. 태그 대기: v1.17.0 (403, 누적 v1.11.0~v1.17.0)

## 2026-10-20T11:20 | T-034 | done | skill 1.17.0
- 발굴(탐색 실행): 스크립트 경계 입력(git 아님, 빈 레포, 잘못된 인자, 3000건 LOG/BACKLOG 0.03초) 이상 없음
- 실제 확인: claude -p --plugin-dir로 스킬을 호출한 세션에서 frontmatter Stop 훅이 동작(RUN 있으면 block, STALL_LIMIT=1에서 STOP 작성). 스킬을 호출하지 않은 세션에서는 동작 안 함(RUN 그대로)
- 변경: assets/autopilot-stop.sh STOP 메모 "1 times" → "time(s)", CHANGELOG
- 검증: validate PASS

## 2026-10-20T11:30 | T-035 | done | skill 1.17.0
- 근거: 이 세션에 로드된 플러그인 스킬이 1.10.2였는데 레포는 1.15 규칙으로 돌고 있었음. 사용자는 알 방법이 없음
- 변경: scripts/status.sh(Skill: 버전, 새 버전 LOG 경고), tests/test_status.sh(+4), SKILL.md 상태 확인 절, README 2종, CHANGELOG
- 검증: validate PASS

## 2026-10-20T11:40 | - | release | skill 1.18.0
- 1.18.0 릴리즈: release/1.18.0 → main, main → develop 역병합. 태그 대기: v1.18.0 (403). release.sh --catch-up --dry-run이 v1.11.0~v1.18.0 9개를 올바른 커밋에 매핑함을 확인

## 2026-10-20T11:45 | T-036 | done | skill 1.18.0
- 발굴: 스크립트 오류 입력(bump/release/eval) 이상 없음. 통합 정책 정독에서 결함: merge: auto는 CI 통과를 요구하지만 CI가 돌고 있으면 PR을 열어 두고 넘어가며, 그 PR로 돌아오는 규칙이 없음 → 영원히 열림, 이후 작업은 그 파일을 피함
- 변경: SKILL.md PR 규칙(자기 open PR 재확인), docs/skill-design.md(근거), tests/test_skill_rules.sh(+3), CHANGELOG
- 검증: validate PASS

## 2026-10-20T11:50 | - | retro | skill 1.18.0
- 범위: T-027~T-036 (10건). done 10 / failed 0 / blocked 0. 유형: feature 3, enhance 4, fix 3. 출처: 탐색 실행 3, 시나리오 3, 정독·관찰 4
- 실패 원인 없음. 반복된 사실: 태그·Release 403(매 릴리스), 자기 CHANGELOG 문장이 scan.sh에 걸림 1회
- "배운 것"에 3줄 추가(실제 세션 확인 방법, 표식 단어, 최소 입력 탐색)

## 2026-10-20T11:58 | - | release | skill 1.19.0
- 1.19.0 릴리즈: release/1.19.0 → main, main → develop 역병합. 태그 대기: v1.19.0 (403)

## 2026-10-20T12:05 | T-037 | done | skill 1.19.0
- 발굴(품질 속성: 관찰성·안전한 기본값): 드라이버는 비정상 종료만 세고, 권한 거부로 아무것도 못 하고 정상 종료하는 실행은 끝없이 반복(비용만 듦). 실행 결과도 출력하지 않음
- 변경: scripts/autopilot.sh(정체 한도, 실행별 LOG 항목 출력), tests/test_driver.sh(가짜 claude ok는 LOG 기록, idle 모드, +7), README 2종, docs/skill-design.md, CHANGELOG
- 검증: validate PASS

## 2026-10-20T12:15 | - | release | skill 1.19.1
- 1.19.1 릴리즈: release/1.19.1 → main, main → develop 역병합. 태그 대기: v1.19.1 (403)

## 2026-10-20T12:40 | T-038 | done | skill 1.19.1
- 변경: scripts/eval.sh(--mode session, 실행 공용 함수, LOG 없을 때 0), tests/test_eval.sh(+11), fixture-todo.expected(missing-db 정규식에 "DB missing", "without a DB"), README 2종, CHANGELOG
- 검증: validate PASS. 실제 eval --mode session --iterations 2: 163초, 9/10(missing-db는 정규식이 "DB missing"을 못 받음 → 보강), 세션이 STOP 후 스스로 끝남, RUN 삭제. 모델이 8작업 후 스스로 최종 정지
- 관찰: LOG 항목 역순·지어낸 시각(163초 동안 11:20~12:00) → T-039. 복합 셸 명령이 allowlist에서도 승인을 요구해 단계가 늘어남

## 2026-10-20T11:26 | T-039 | done | skill 1.19.1
- 변경: scripts/log.sh(신규: 파일 끝에 현재 시각·스킬 버전으로 추가, 본문은 stdin), SKILL.md(LOG 형식 절·Phase 5), docs/skill-design.md(근거), tests/test_log.sh(15), CHANGELOG
- 검증: validate PASS. 실제 eval --mode session --iterations 2: 64초, 10/10, LOG 6개 항목이 순서대로 실제 시각(11:25)
- 관찰: 이 레포 LOG도 시각을 지어냈음(실제 11:21인데 12:40까지 적음). 지난 항목은 고치지 않고 이후부터 log.sh 사용
- 관찰(같은 실행): 5작업을 커밋 하나로, 심화 발굴 없이 최종 정지, 마지막 커밋이 LOG 5줄 삭제 → T-040

## 2026-10-20T11:32 | T-040 | done | skill 1.19.1
- 변경: scripts/eval.sh(규칙 검사 4개: 작업당 커밋, LOG 추가만, LOG 시간 순서, 심화 발굴 후 최종 정지 / --grade로 남긴 실행 재채점), tests/test_eval.sh(+10, 가짜 claude는 작업마다 커밋), README 2종, CHANGELOG
- 검증: validate PASS. 남겨 둔 실제 실행 2개 재채점: 1회차 시간 순서 위반(6건), 2회차 작업당 커밋·LOG 삭제·심화 발굴 생략 위반 — 둘 다 점수는 10/10인데 이제 실패
- 다음: T-041(위반을 막는 규칙 수정)

## 2026-10-20T11:39 | T-041 | done | skill 1.19.1
- 변경: scripts/finalstop.sh(신규: 심화 발굴 4단계·빈 큐·커밋 안 된 코드 없음을 확인해야 STOP), SKILL.md(최종 정지는 finalstop.sh, Phase 2 시작에 이전 작업 커밋 확인, "사람에게 남기지 않기" 원칙), scripts/log.sh(done인데 마지막 커밋이 여러 작업이면 경고), tests/test_finalstop.sh(15)·test_log.sh(+4), docs/skill-design.md, CHANGELOG
- 검증: validate PASS. 실제 eval --mode session 2회: 3회차(iterations 3) 규칙 검사 전부 ok·10/10, 2회차 1건 위반(T-003,T-004 한 커밋)·나머지 ok. 수정 전 2회차는 위반 3건
- 판단: 커밋 묶음은 규칙과 log.sh 경고까지만. 이미 만든 커밋을 쪼개는 것은 히스토리 재작성이라 하지 않음

## 2026-10-20T11:49 | T-042 | done | skill 1.20.0
- 발굴(eval 반복 측정): session 모드 todo 2회·wordcount 1회 모두 규칙 검사 ok(T-041 후 위반 0/3). 복합 명령 승인 문제는 재현 안 됨(allowlist에서 && 실행됨)
- 변경: tests/eval/fixture-todo.expected(off-by-one에 "[01]-based", "mark item n"), tests/test_eval.sh(+4, 실제 표현 회귀), CHANGELOG
- 검증: validate PASS. 남긴 실행 재채점 9/10 → 10/10, 다른 행에 오탐 없음

## 2026-10-20T11:51 | - | release | skill 1.20.0
- 1.20.0 릴리즈(11:42경): release/1.20.0 → main, main → develop 역병합. 태그 대기: v1.20.0 (403, 누적 v1.11.0~v1.20.0)
- 이 항목은 log.sh가 release 상태를 거부해 그때 못 남겼음(T-043에서 고침)

## 2026-10-20T11:51 | T-043 | done | skill 1.20.0
- 변경: scripts/log.sh(release 상태), SKILL.md(LOG 상태 목록, Release 절에 release 항목 내용), tests/test_log.sh(+8: SKILL.md 목록의 모든 상태를 받는지), CHANGELOG
- 검증: validate PASS

## 2026-10-20T11:59 | - | release | skill 1.20.1
- 1.20.1 릴리즈: release/1.20.1 → main, main → develop 역병합. 태그 대기: v1.20.1 (403)

## 2026-10-20T11:59 | T-044 | done | skill 1.20.1
- 발굴: driver eval 3회 8/8·규칙 검사 전부 ok. 문서 정확성 확인에서 README 파일 트리가 스크립트 4개와 commands/를 빠뜨림
- 변경: README 2종 트리, tests/test_skill_rules.sh(+16: 트리가 모든 스킬 스크립트를 언급)
- 검증: validate PASS

## 2026-10-20T12:01 | T-045 | done | skill 1.20.1
- 변경: assets/autopilot-stop.sh(block 이유에 finalstop.sh 안내), .claude/hooks 사본 갱신, tests/test_hook.sh(+2: 유효한 JSON, finalstop 언급), CHANGELOG
- 검증: validate PASS

## 2026-10-20T12:08 | T-046 | done | skill 1.20.2
- 발굴: ROADMAP 제품 절이 1.12 기준이라 갱신(기능 지도·빠진 것·약한 것·관찰·시나리오). 새 시나리오(클라우드 첫 실행)에서 local 모드 결과가 컨테이너와 함께 사라지는 문제 발견
- 변경: SKILL.md Phase 0(클라우드+local이면 첫 진입에 한 줄 안내·LOG), scripts/status.sh(경고), tests/test_status.sh(+3), CHANGELOG. 제안 P-002(클라우드 기본값을 branch로)
- 검증: validate PASS

## 2026-10-20T12:08 | - | retro | skill 1.20.2
- 범위: T-037~T-046 (10건). done 10 / failed 0 / blocked 0. 유형: fix 3, test 3, enhance 2, feature 1, docs 1. 출처: eval 실제 실행 관찰 5, 정독 2, 탐색·시나리오 3
- 실패 원인 없음. 반복된 사실: 모델 실행 결과(세션 eval)가 규칙 위반의 가장 큰 발견 원천. 채점 정규식 누락 2회(T-038, T-042)
- "배운 것"에 2줄 추가(규칙 검사 우선, LOG는 log.sh로만)

## 2026-10-20T12:21 | - | release | skill 1.21.0
- 1.21.0 릴리즈: release/1.21.0 → main, main → develop 역병합. 태그 대기: v1.21.0 (403)

## 2026-10-20T12:21 | T-047 | done | skill 1.21.0
- 변경: scripts/task.sh(신규), SKILL.md(Phase 2 start, Phase 4 fail, Phase 5 done, .gitignore에 .autopilot/.task), scripts/autopilot.sh(.gitignore 항목), tests/test_task.sh(23)·test_driver.sh, README 2종 트리, docs/skill-design.md, CHANGELOG
- 검증: validate PASS. 실제 eval --mode session --iterations 3 두 번: 둘 다 10/10, 규칙 검사 전부 ok, 두 실행 모두 task.sh 사용(.gitignore에 .autopilot/.task), 작업마다 커밋 하나

## 2026-10-20T12:25 | - | release | skill 1.22.0
- 1.22.0 릴리즈: release/1.22.0 → main, main → develop 역병합. 태그 대기: v1.22.0 (403, 누적 v1.11.0~v1.22.0)

## 2026-10-20T12:28 | T-048 | done | skill 1.22.0
- 변경: scripts/autopilot.sh(GitLab origin이면 glab 사전 점검), SKILL.md(1-E glab issue, Phase 5 glab mr create, 드라이버 절), tests/test_driver.sh(+4), CHANGELOG, .gitignore(.autopilot/.task)
- 검증: validate PASS. task.sh start → 구현 → 커밋 → task.sh done 순서로 처음 사용(먼저 구현하자 start가 거부함: 의도대로)
- 발견: task.sh 거부 시에도 .gitignore를 고침 → T-049

## 2026-10-20T12:30 | T-049 | done | skill 1.22.0
- 변경: scripts/task.sh(.gitignore 추가를 start 성공 뒤로), tests/test_task.sh(+2: 거부 시 트리·.gitignore 그대로, .task 없음), CHANGELOG
- 검증: validate PASS

## 2026-10-20T12:34 | - | release | skill 1.23.0
- 1.23.0 릴리즈: release/1.23.0 → main, main → develop 역병합. 태그 대기: v1.23.0 (403, 누적 v1.11.0~v1.23.0)

## 2026-10-20T12:38 | T-050 | done | skill 1.23.0
- 변경: scripts/task.sh(drop), SKILL.md Phase 3(불필요한 작업은 drop + 하지 않기로 한 것에 근거), tests/test_task.sh(+6), CHANGELOG
- 검증: validate PASS

## 2026-10-20T12:42 | - | release | skill 1.24.0
- 1.24.0 릴리즈: release/1.24.0 → main, main → develop 역병합. 태그 대기: v1.24.0 (403, 누적 v1.11.0~v1.24.0)

## 2026-10-20T12:53 | T-051 | done | skill 1.24.0
- 변경: tests/eval/fixture-stats(CONTRIBUTING: Conventional Commits·make test, 실패 테스트, README와 동작 불일치)·.expected, scripts/eval.sh(commit= 기대값, 상태 전용 커밋은 묶음 검사에서 제외), tests/test_eval.sh(+6), README 2종, CHANGELOG
- 검증: validate PASS. 실제 eval --fixture stats --mode session --iterations 2: 8/8, 모든 커밋이 Conventional Commits. 채점 오탐 1건(상태 전용 커밋 "chore: record T-1 and queue T-4"를 묶음으로 판정) → 수정 후 재채점 규칙 전부 ok
- 발견: task.sh done도 같은 커밋 때문에 거부할 것 → T-052

## 2026-10-20T12:55 | T-052 | done | skill 1.24.0
- 변경: scripts/task.sh(다른 작업 ID 검사는 .autopilot/·.gitignore 밖을 바꾼 커밋만), tests/test_task.sh(+1), CHANGELOG
- 검증: validate PASS. 재현: start → 코드 커밋 → "chore: record T-001 and queue T-004"(상태 전용) → done 거부 → 수정 후 허용

## 2026-10-20T12:59 | - | release | skill 1.24.1
- 1.24.1 릴리즈: release/1.24.1 → main, main → develop 역병합. 태그 대기: v1.24.1 (403, 누적 v1.11.0~v1.24.1)

## 2026-10-20T13:03 | T-053 | done | skill 1.24.1
- 변경: scripts/autopilot.sh(AUTOPILOT_MODEL → --model), scripts/eval.sh(--model, 사용법에 --grade도), tests(driver +3, eval +1), SKILL.md 드라이버 절, README 2종, CHANGELOG
- 검증: validate PASS

## 2026-10-20T13:07 | - | release | skill 1.25.0
- 1.25.0 릴리즈: release/1.25.0 → main, main → develop 역병합. 태그 대기: v1.25.0 (403, 누적 v1.11.0~v1.25.0)

## 2026-10-20T13:13 | T-054 | done | skill 1.25.0
- 변경: tests/eval/fixture-kv(Go 모듈, 결함 5)·.expected, tests/test_eval.sh(+3: 시작 상태 확인, go 없으면 건너뜀), README 2종, CHANGELOG
- 검증: validate PASS. 실제 eval --fixture kv --mode session --iterations 2: 10/10, 규칙 검사 전부 ok, 기준선에 go test ./...·go vet ./... 기록
- 메모: printf 형식 오류는 go test가 vet 일부를 돌려 빌드가 깨져 실패 테스트를 가림 → go test가 안 돌리는 unreachable로 바꿈

## 2026-10-20T13:17 | T-055 | done | skill 1.25.0
- 발굴: driver eval stats 2회 6/6·규칙 ok. 심화 발굴 1단계(SKILL.md 정독)에서 Phase 0 단계 2(작업 트리 stash)와 Phase 2 첫 검사(이전 작업 끝내기)가 충돌
- 변경: SKILL.md Phase 0 단계 2(in_progress 행이 있으면 stash하지 않음), tests/test_skill_rules.sh(+1), CHANGELOG
- 검증: validate PASS(정리 명령 추출 테스트 그대로 통과)

## 2026-10-20T13:19 | T-056 | done | skill 1.25.0
- 변경: scripts/status.sh("Now:" 줄), SKILL.md 상태 확인 절, tests/test_status.sh(+3), CHANGELOG
- 검증: validate PASS. 이 레포에서 "Now: T-056 … (attempt 1, started 0 min ago)" 확인

## 2026-10-20T13:20 | - | retro | skill 1.25.0
- 범위: T-047~T-056 (10건). done 10 / failed 0 / blocked 0. 유형: enhance 3, test 3, fix 3, feature 2(T-048, T-053). 출처: eval 실제 실행 3, 직접 사용 2, 정독 2, 시나리오·품질 3
- 실패 원인 없음. 반복된 사실: 새 장치(task.sh)는 이 레포에서 직접 써 보면서 결함 2건이 나옴(T-049, T-052)
- "배운 것"에 2줄 추가(task.sh 순서, eval 예제 결함 가림)

## 2026-10-20T13:24 | - | release | skill 1.26.0
- 1.26.0 릴리즈: release/1.26.0 → main, main → develop 역병합. 태그 대기: v1.26.0 (403, 누적 v1.11.0~v1.26.0)

## 2026-10-20T13:29 | T-057 | done | skill 1.26.0
- 변경: scripts/runlock.sh(start --tasks N, 인자 파싱), scripts/task.sh(done이 예산을 세고 N개째에 STOP), scripts/status.sh(예산 진행 표시), SKILL.md Phase 0(사람이 작업 수를 말하면 --tasks), README 2종, tests/test_task.sh(+12), CHANGELOG
- 검증: validate PASS

## 2026-10-20T13:30 | - | discover | skill 1.26.0
- T-057 실제 확인: claude -p "… for 2 tasks" --plugin-dir(todo 예제)에서 모델이 runlock.sh start --tasks 2를 쓰고 2작업(작업마다 커밋) 후 task.sh done이 STOP 작성, 훅이 세션을 놓아 줌, RUN 삭제

## 2026-10-20T13:35 | - | release | skill 1.27.0
- 1.27.0 릴리즈: release/1.27.0 → main, main → develop 역병합. 태그 대기: v1.27.0 (403, 누적 v1.11.0~v1.27.0)

## 2026-10-20T13:40 | T-058 | done | skill 1.27.0
- 변경: scripts/eval.sh(세션 모드 프롬프트 "for N tasks", 감시자는 N+1, "예산 또는 최종 정지로 끝남" 검사), tests/test_eval.sh(가짜 claude가 예산을 따르거나 무시, +4), README 2종, CHANGELOG
- 검증: validate PASS. 실제 eval --mode session --iterations 2(todo): 38초, 11/11, 예산으로 스스로 멈춤, 규칙 검사 전부 ok

## 2026-10-20T13:43 | T-059 | done | skill 1.27.0
- 관찰: 이 세션은 시작 때 동기화본 1.10.2를 로드. 계정 동기화본은 이미 1.27.0(generation 3, manifest.json). 새 세션부터 최신 버전 사용
- 변경: README 2종 "업데이트" 절(claude plugin marketplace update / plugin update, 계정 동기화와 세션 버전, /autopilot:status)
- 검증: validate PASS. 명령은 claude plugin --help로 확인
- 판단: 이 레포의 .claude/hooks 사본은 유지(스킬 훅과 같이 돌아도 카운터 1회, 동기화된 계정 플러그인에서 skill hook 동작은 아직 직접 확인 못 함)

## 2026-10-20T13:47 | T-060 | done | skill 1.27.0
- 변경: scripts/eval.sh(--fixture all: 예제마다 같은 옵션으로 실행, 요약, 하나라도 실패하면 1, claude 없으면 3, --grade와 함께는 거부), tests/test_eval.sh(+11), CLAUDE.md, README 2종, CHANGELOG
- 검증: validate PASS

## 2026-10-20T13:52 | - | release | skill 1.27.1
- 1.27.1 릴리즈: release/1.27.1 → main, main → develop 역병합. 태그 대기: v1.27.1 (403, 누적 v1.11.0~v1.27.1)

## 2026-10-20T13:55 | T-061 | done | skill 1.27.1
- 변경: scripts/task.sh(칸 수 오류에 기대 형식·예시 행), tests/test_task.sh(+3), CHANGELOG
- 검증: validate PASS

## 2026-10-20T14:03 | T-062 | done | skill 1.27.1
- 발굴(심화 3단계 이식성): bash 4 전용 문법·GNU 전용 옵션 없음. 새 시나리오(모노레포 패키지 하나만)에서 범위 지정 수단 없음 발견
- 변경: assets/CONFIG.md(scope), scripts/task.sh(done이 범위 밖 변경 거부), scripts/status.sh(scope 표시), SKILL.md Phase 1·3, README 2종, tests(task +6, skill_rules CONFIG 키 목록), CHANGELOG
- 검증: validate PASS

## 2026-10-20T14:08 | - | release | skill 1.28.0
- 1.28.0 릴리즈: release/1.28.0 → main, main → develop 역병합. 태그 대기: v1.28.0 (403, 누적 v1.11.0~v1.28.0)

## 2026-10-20T14:13 | T-063 | done | skill 1.28.0
- 변경: tests/eval/fixture-mono(CONFIG scope: pkg/a, 두 패키지 모두 결함)·.expected, scripts/eval.sh(nofile= 기대값), tests/test_eval.sh(+4), README 2종, CHANGELOG
- 검증: validate PASS. 실제 eval --fixture mono --mode session --iterations 2: 8/8, 커밋 3개 모두 pkg/a·.autopilot만, ROADMAP에 "pkg/b off limits" 기록

## 2026-10-20T14:22 | T-064 | done | skill 1.28.0
- 발굴: eval --fixture all --mode session --iterations 2 — 5개 예제 모두 100%, 규칙 위반 0. 새 시나리오(Windows CRLF 체크아웃)에서 task.sh가 BACKLOG 전체를 LF로 바꾸는 것을 재현
- 변경: scripts/task.sh·archive.sh(newline="" 읽기·쓰기, 고친 행의 \r 유지), scripts/log.sh(CRLF 파일엔 CRLF 줄), tests(archive +3, task +2, log +2), CHANGELOG
- 검증: validate PASS. 수정 전 새 검사 5개 실패 → 수정 후 통과

## 2026-10-20T14:27 | - | release | skill 1.28.1
- 1.28.1 릴리즈: release/1.28.1 → main, main → develop 역병합. 태그 대기: v1.28.1 (403, 누적 v1.11.0~v1.28.1)

## 2026-10-20T14:31 | T-065 | done | skill 1.28.1
- 변경: .gitattributes(신규: *.sh·*.json eol=lf), tests/test_scripts.sh(+2: autocrlf=true 체크아웃에서 .sh가 LF이고 bash -n 통과), CHANGELOG
- 검증: validate PASS. .gitattributes 없이 새 검사 2개 실패(.sh 32개가 CRLF) → 있으면 통과

## 2026-10-20T14:36 | - | release | skill 1.28.2
- 1.28.2 릴리즈: release/1.28.2 → main, main → develop 역병합. 태그 대기: v1.28.2 (403, 누적 v1.11.0~v1.28.2)

## 2026-10-20T14:39Z | T-066 | done | skill 1.28.2
- 변경: scripts/log.sh(date -u, Z), SKILL.md LOG 형식 예시·대체 명령, tests/test_log.sh(+1: 서울·LA 같은 시각), CHANGELOG
- 검증: validate PASS. 이 항목부터 UTC+Z (이 컨테이너는 원래 UTC라 이전 항목과 순서 그대로)
- 판단: 대체 수단인 레포 훅 사본은 사용자 레포에 .gitattributes가 없으면 Windows에서 CRLF가 될 수 있으나, 기본은 스킬 frontmatter 훅이라 사용자 레포의 .gitattributes는 건드리지 않음

## 2026-10-20T14:39Z | - | retro | skill 1.28.2
- 범위: T-057~T-066 (10건). done 10 / failed 0 / blocked 0. 유형: fix 5, feature 2, test 2, enhance 1, docs 1(T-059). 출처: 시나리오 6, eval·관찰 3, 정독 1
- 실패 원인 없음. eval --fixture all(세션 모드) 5개 예제 100%. 새 결함은 대부분 플랫폼·환경 시나리오(Windows CRLF 2건, 시간대 1건)에서 나옴
- "배운 것"에 1줄 추가(Windows 시나리오)

## 2026-10-20T14:45Z | - | release | skill 1.28.3
- 1.28.3 릴리즈: release/1.28.3 → main, main → develop 역병합. 태그 대기: v1.28.3 (403, 누적 v1.11.0~v1.28.3)

## 2026-10-20T14:50Z | T-067 | done | skill 1.28.3
- 변경: 스킬 스크립트 7개(autopilot·finalstop·task·status·hook·runlock·archive)에 PY=python3||python, 없으면 분명한 오류. tests/test_portability.sh(+6: python만 있는 PATH에서 runlock·task·status·archive, Python 없음 오류), README 2종 요구 사항, CHANGELOG
- 검증: validate PASS. 수정 전 새 검사 4개 실패 → 통과

## 2026-10-20T14:55Z | - | release | skill 1.28.4
- 1.28.4 릴리즈: release/1.28.4 → main, main → develop 역병합. 태그 대기: v1.28.4 (403, 누적 v1.11.0~v1.28.4)

## 2026-10-20T14:56Z | - | discover | skill 1.28.4
- 심화 발굴 3단계(문서 예제 정확성): 격리된 CLAUDE_CONFIG_DIR에서 README대로 claude plugin marketplace add ./ → install → list/details 동작. 스킬 3개(autopilot, status, stop), 상시 ~403 토큰, 호출 시 ~14.5k 토큰
- 제안 P-001 근거 갱신(423줄·14.5k 토큰, 스크립트화 후 eval 100%). 상태는 그대로 proposed(사람 결정)

## 2026-10-20T15:02Z | T-068 | done | skill 1.28.4
- 변경: scripts/eval.sh(--output-format json, 비용·턴 합계 출력), tests/test_eval.sh(+3), CHANGELOG
- 검증: validate PASS. 실제 todo 드라이버 1회: 46초, "Cost: $0.20 over 1 run(s), 9 turns", 5/5

## 2026-10-20T15:08Z | T-069 | done | skill 1.28.4
- 변경: plugins/autopilot/commands/run.md(신규), SKILL.md 상태 확인 절, README 2종, docs/plugin-structure.md, tests/test_skill_rules.sh(+1), CHANGELOG
- 검증: validate PASS(claude plugin validate 포함). 실제 claude -p "/autopilot:run 1" --plugin-dir(todo): T-001 한 개 후 "Stopped after 1 task(s) as asked"로 끝남

## 2026-10-20T15:14Z | - | release | skill 1.29.0
- 1.29.0 릴리즈: release/1.29.0 → main, main → develop 역병합. 태그 대기: v1.29.0 (403, 누적 v1.11.0~v1.29.0)

## 2026-10-20T15:17Z | T-070 | done | skill 1.29.0
- 변경: docs/skill-design.md(작업 수 예산은 사람이 미리 쓴 STOP, scope가 CONFIG이고 done에서 검사되는 이유, LOG가 UTC인 이유)
- 검증: validate PASS

## 2026-10-20T15:30Z | T-071 | done | skill 1.29.0
- 발굴: eval --fixture all --mode session --iterations 3 — 5개 예제 100%, 실행당 약 $0.21·10턴(실제 측정, 세션 전체 비용). 심화 3단계(성능 10배 입력)에서 scan.sh 5000파일 2분 18초
- 변경: scripts/scan.sh(파일 목록을 Python 한 번으로, NUL 구분, 검색 6번이 공유; git 모드와 walk 모드 구분), tests/test_scan.sh(+3: 3000파일 10초 미만, 마지막 파일 찾음, 빈 git 레포에서 무시 파일 안 읽음), CHANGELOG
- 검증: validate PASS. 5000파일 2분 18초 → 0.25초, 출력 동일(diff)

## 2026-10-20T15:36Z | - | release | skill 1.29.1
- 1.29.1 릴리즈: release/1.29.1 → main, main → develop 역병합. 태그 대기: v1.29.1 (403, 누적 v1.11.0~v1.29.1)

## 2026-10-20T15:39Z | T-072 | done | skill 1.29.1
- 변경: scripts/task.sh(CONFIG에서 \r 제거 후 scope 파싱), tests/test_task.sh(+2), CHANGELOG
- 검증: validate PASS. 재현(CRLF CONFIG에서 pkg/a/f가 범위 밖으로 거부) → 수정 후 허용
- 다른 CONFIG 파서 확인: autopilot.sh·status.sh는 공백 클래스에서 멈춰 \r 영향 없음

## 2026-10-20T15:45Z | - | release | skill 1.29.2
- 1.29.2 릴리즈: release/1.29.2 → main, main → develop 역병합. 태그 대기: v1.29.2 (403, 누적 v1.11.0~v1.29.2)

## 2026-10-20T15:49Z | T-073 | done | skill 1.29.2
- 발굴: SKILL.md 전체 정독(심화 1단계). 결함 1(branch/pr에서 publish가 task.sh done 검사보다 먼저), 불일치 5(사람에게 남기지 않기↔scope, CONFIG 설명, 예산 문장 위치, 템플릿 설명, gitignore 목록)
- 변경: SKILL.md Phase 5 순서(커밋 → done → publish), 원칙·표·Phase 0·Templates·마지막 절 갱신, tests/test_skill_rules.sh(+3), CHANGELOG
- 검증: validate PASS

## 2026-10-20T15:54Z | - | release | skill 1.30.0
- 1.30.0 릴리즈: release/1.30.0 → main, main → develop 역병합. 태그 대기: v1.30.0 (403, 누적 v1.11.0~v1.30.0)

## 2026-10-20T16:00Z | T-074 | done | skill 1.30.0
- 발굴(심화 4단계): 하지 않기로 한 것(Actions CI) 이유 유지, 이슈 0, 제안 2개 결정 대기. validate.sh 2분 16초 중 test_eval 90초 발견
- 변경: scripts/eval.sh(AUTOPILOT_EVAL_POLL), tests/test_eval.sh(주기 0.1초, 가짜 대기 단축), CHANGELOG
- 검증: test_eval 90초 → 24초, 3회 연속 83/83, validate PASS

## 2026-10-20T16:04Z | T-075 | done | skill 1.30.0
- 변경: scripts/autopilot.sh(--output-format json, read_result로 로그는 결과 텍스트+턴·비용, 실행별·누적 비용 출력, AUTOPILOT_MAX_COST), tests/test_driver.sh(+8), SKILL.md 드라이버 절, README 2종, CHANGELOG
- 검증: validate PASS. 실제 드라이버(todo, 한도 $0.01): #1 $0.1753 출력, 로그에 결과 텍스트와 비용
- 같은 실행에서 발견: 모델이 "exactly one task"를 예산으로 해석해 1회 후 STOP(T-076), 동기화본 version 작은따옴표로 "skill unknown"(T-077), CONFIG 없을 때 task.sh 오류 출력(T-078)

## 2026-10-20T16:08Z | T-076 | done | skill 1.30.0
- 변경: scripts/runlock.sh(AUTOPILOT_DRIVER=1이면 RUN·예산 없이 안내만), scripts/task.sh(드라이버 모드에선 예산 무시), scripts/autopilot.sh(프롬프트: 예산 아님, runlock 쓰지 말 것), SKILL.md 실행 모드 표, tests(task +3, driver +1), CHANGELOG
- 검증: validate PASS. 실제 드라이버 2회(todo, 동기화된 1.27 스킬): 2회 모두 작업 완료, STOP 없음(수정 전 1회 후 멈춤). eval 드라이버 2회 8/8

## 2026-10-20T16:10Z | T-077 | done | skill 1.30.0
- 변경: scripts/log.sh·status.sh(version 값의 작은따옴표 허용), tests(log +3: 따옴표 없음·큰·작은, status +1), CHANGELOG
- 검증: validate PASS. 실제 동기화본(autopilot~g3, version: '1.30.0')에서 1.30.0 파싱

## 2026-10-20T16:12Z | T-078 | done | skill 1.30.0
- 변경: scripts/task.sh(CONFIG.md가 있을 때만 scope 읽기), tests/test_task.sh(+1: stderr 비어 있음), CHANGELOG
- 검증: validate PASS. 이 레포에서 done 실행 시 오류 출력 사라짐

## 2026-10-20T16:13Z | - | retro | skill 1.30.0
- 범위: T-067~T-078 (12건). done 12 / failed 0 / blocked 0. 유형: fix 7, feature 2, test 2, docs 1, perf 1(T-071). 출처: 시나리오·이식성 5, 실제 실행(eval·드라이버) 4, 정독 2, 품질 점검 1
- 가장 큰 결함은 실제 드라이버 실행에서 나옴(T-076: 1.27부터 드라이버가 1회 후 멈춤). 단위 테스트·세션 eval로는 안 보였음
- 정정: T-078 항목의 "이 레포에서 done 실행 시 오류 출력 사라짐"은 틀림. 이 레포엔 CONFIG가 있어 원래 오류가 없었음; 오류는 CONFIG 없는 테스트 레포와 실제 드라이버 실행에서 보였음
- "배운 것"에 2줄 추가(새 기능은 드라이버로도 실행, 배포본으로 파서 확인)

## 2026-10-20T16:16Z | - | release | skill 1.31.0
- 1.31.0 릴리즈: release/1.31.0 → main, main → develop 역병합. 태그 대기: v1.31.0 (403, 누적 v1.11.0~v1.31.0)

## 2026-10-20T16:22Z | T-079 | done | skill 1.31.0
- 변경: scripts/eval.sh(드라이버 모드가 autopilot.sh의 PROMPT·허용 도구를 읽어 쓰고 --plugin-dir로 작업 사본), tests/test_eval.sh(+3), CHANGELOG
- 검증: validate PASS. 실제 eval 드라이버 2회 3번: 7/8, 8/8, 8/8 (7/8은 발굴 1건 누락, 다시 돌리면 재현 안 됨 → 변동)

## 2026-10-20T16:31Z | T-080 | done | skill 1.31.0
- 발굴: eval --fixture all(드라이버, 실제 프롬프트) 5개 예제 100%. docs/versioning.md 정확. 안전한 기본값 점검에서 skip 모드 무음·오타 무음 발견
- 변경: scripts/autopilot.sh(권한 모드 안내, skip 경고, 알 수 없는 값 경고), tests/test_driver.sh(+5), CHANGELOG
- 검증: validate PASS

## 2026-10-20T16:35Z | - | release | skill 1.31.1
- 1.31.1 릴리즈: release/1.31.1 → main, main → develop 역병합. 태그 대기: v1.31.1 (403, 누적 v1.11.0~v1.31.1)

## 2026-10-20T16:37Z | T-081 | done | skill 1.31.1
- 변경: 스킬 스크립트 10개·레포 스크립트 4개에 -h/--help(머리 주석 출력, exit 0), tests/test_scripts.sh(+43: 모든 스크립트 exit 0·사용법 줄·-h, 아무것도 만들지 않음), CHANGELOG
- 검증: validate PASS

## 2026-10-20T16:41Z | - | release | skill 1.32.0
- 1.32.0 릴리즈: release/1.32.0 → main, main → develop 역병합. 태그 대기: v1.32.0 (403, 누적 v1.11.0~v1.32.0)

## 2026-10-20T16:43Z | T-082 | done | skill 1.32.0
- 변경: 스킬 스크립트 8개에 없는 경로 검사("[이름] no such directory: <경로>"), tests/test_scripts.sh(+9), CHANGELOG
- 검증: validate PASS

## 2026-10-20T16:47Z | - | release | skill 1.32.1
- 1.32.1 릴리즈: release/1.32.1 → main, main → develop 역병합. 태그 대기: v1.32.1 (403, 누적 v1.11.0~v1.32.1)

## 2026-10-20T16:51Z | T-083 | done | skill 1.32.1
- 변경: SKILL.md Phase 0 단계 3(비대화·시간 제한·watch 모드는 1회 실행 형태로), Phase 4 단계 1(같은 방식, 시간 초과는 기준보다 나쁨), tests/test_skill_rules.sh(+3), CHANGELOG
- 검증: validate PASS
- 정정: 처음엔 "영원히 멈춤"이라 적었으나 Claude Code의 Bash 도구가 몇 분 뒤 명령을 끝내므로 "도구 호출이 끊길 때까지, 매 작업마다"가 정확함. 규칙·CHANGELOG 문구 수정

## 2026-10-20T16:57Z | T-084 | done | skill 1.32.1
- 변경: tests/eval/fixture-watch(npm test = node --test --watch)·.expected, scripts/eval.sh(roadmap= 기대값), tests/test_eval.sh(+3), README 2종, CHANGELOG
- 검증: validate PASS. 실제 eval --fixture watch --mode session --iterations 1: 170초, 8/8, ROADMAP에 "node --test", "npm test hangs (--watch)" 기록하고 스크립트 수정 작업(T-002) 추가. 평소(약 60초)보다 길어 한 번은 watch에 걸렸다가 빠져나온 것으로 보임

## 2026-10-20T17:00Z | - | release | skill 1.33.0
- 1.33.0 릴리즈: release/1.33.0 → main, main → develop 역병합. 태그 대기: v1.33.0 (403, 누적 v1.11.0~v1.33.0)

## 2026-10-20T17:03Z | T-085 | done | skill 1.33.0
- 변경: scripts/autopilot.sh(git 정체 없으면 첫 실행 전 이유·고치는 법과 함께 exit 1), SKILL.md Phase 0(정체 없으면 STOP, 스스로 설정 금지), tests/test_driver.sh(+5, 테스트 레포에 로컬 정체 설정), CHANGELOG
- 검증: validate PASS. GIT_CONFIG_GLOBAL=/dev/null로 정체 없는 환경 재현

## 2026-10-20T17:06Z | - | release | skill 1.34.0
- 1.34.0 릴리즈: release/1.34.0 → main, main → develop 역병합. 태그 대기: v1.34.0 (403, 누적 v1.11.0~v1.34.0)

## 2026-10-20T17:09Z | T-086 | done | skill 1.34.0
- 변경: scripts/autopilot.sh(첫 커밋 없고 파일이 있으면 첫 실행 전 고치는 법과 함께 exit 1), SKILL.md Phase 0(같은 경우 STOP, 대신 커밋하지 않음), tests/test_driver.sh(+5: 파일 있음 → 멈춤, 빈 새 레포는 실행), CHANGELOG
- 검증: validate PASS. 재현: stash "You do not have the initial commit yet", task.sh start "uncommitted changes (?? app.py)"

## 2026-10-20T17:13Z | - | release | skill 1.35.0
- 1.35.0 릴리즈: release/1.35.0 → main, main → develop 역병합. 태그 대기: v1.35.0 (403, 누적 v1.11.0~v1.35.0)

## 2026-10-20T17:15Z | T-087 | done | skill 1.35.0
- 발굴: 공백·한글 경로("내 프로젝트 (copy)")에서 runlock·task·log·status·archive·scan·finalstop 전체 흐름 정상. 그 과정에서 finalstop이 .gitignore 변경으로 거부하는 불일치 발견
- 변경: scripts/finalstop.sh(.gitignore 제외), tests/test_finalstop.sh(+1), CHANGELOG
- 검증: validate PASS

## 2026-10-20T17:18Z | - | release | skill 1.35.1
- 1.35.1 릴리즈: release/1.35.1 → main, main → develop 역병합. 태그 대기: v1.35.1 (403, 누적 v1.11.0~v1.35.1)

## 2026-10-20T17:20Z | T-088 | done | skill 1.35.1
- 발굴: git worktree에서 전체 흐름 정상(.git이 파일). 드라이버 실행 중 status.sh가 "idle"인 관찰성 공백
- 변경: scripts/status.sh(driver.lock pid 확인), tests/test_status.sh(+3), CHANGELOG
- 검증: validate PASS

## 2026-10-20T17:21Z | - | retro | skill 1.35.1
- 범위: T-079~T-088 (10건). done 10 / failed 0 / blocked 0. 유형: fix 4, enhance 3, test 2, feature 1(T-075 이전 포함 시 T-080 등). 출처: 품질 점검(도움말·오류·관찰성) 4, 처음 쓰는 환경 시나리오 3, 실제 실행 2, 회고 후속 1
- 실패 원인 없음. eval: 6개 예제(세션·드라이버) 모두 100%
- "배운 것"에 1줄 추가(처음 쓰는 환경은 미리 확인하고 STOP)

## 2026-10-20T17:25Z | - | release | skill 1.36.0
- 1.36.0 릴리즈: release/1.36.0 → main, main → develop 역병합. 태그 대기: v1.36.0 (403, 누적 v1.11.0~v1.36.0)

## 2026-10-20T17:27Z | T-089 | done | skill 1.36.0
- 변경: README 2종(드라이버 종료 조건·glab·권한 모드, 상태 화면, 최종 정지 조건 (d), eval 설명), CHANGELOG
- 검증: validate PASS

## 2026-10-21T02:43Z | - | discover | skill 1.36.0
- eval --mode session --iterations 2 --model claude-haiku-5-5(todo): 10/11, 148초, $0.04, 규칙 검사 전부 ok. 놓친 것: TODO 마커(마감일)를 작업 대신 제안으로 보냄 — scan.sh 줄은 작업이나 "하지 않기로 한 것"이어야 하나, 기능 추가를 방향 선택으로 판단. 한 번뿐이라 규칙 변경 근거로는 부족, 관찰로만 남김

## 2026-10-21T02:53Z | T-090 | done | skill 1.36.0
- 변경: SKILL.md 발굴 완료 조건(scan 줄은 1-F가 요구할 때만 제안으로 처리, 추가 요청 마커는 feature 작업), tests/test_skill_rules.sh(+1), CHANGELOG
- 검증: validate PASS. Haiku 세션 eval 전 10/11(TODO를 제안으로) → 후 2회 11/11·10/11(TODO는 둘 다 작업, 놓친 것은 remove 1건). --fixture all 세션 1작업: kv 11/11, mono 8/8, stats 8/9, todo 10/11, watch 8/8, wordcount 9/9, 규칙 위반 0. todo를 2번 다시 돌려 둘 다 11/11 → 놓친 것은 변동으로 판단

## 2026-10-21T02:57Z | - | release | skill 1.37.0
- 1.37.0 릴리즈: release/1.37.0 → main, main → develop 역병합. 태그 대기: v1.37.0 (403, 누적 v1.11.0~v1.37.0)

## 2026-10-21T03:00Z | T-091 | done | skill 1.37.0
- 변경: SKILL.md Phase 5 6단계(STOP이 생겼으면 .autopilot/만 커밋하고 끝냄, 기존 6단계는 7로), tests/test_skill_rules.sh(+1), CHANGELOG
- 검증: validate PASS. 실제 claude -p "/autopilot:run 1"(todo): 끝난 뒤 작업 트리 깨끗, 마지막 커밋 "autopilot: record state"

## 2026-10-21T03:04Z | - | release | skill 1.38.0
- 1.38.0 릴리즈: release/1.38.0 → main, main → develop 역병합. 태그 대기: v1.38.0 (403, 누적 v1.11.0~v1.38.0)
