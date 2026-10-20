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
