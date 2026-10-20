# Changelog

버전 규칙: MAJOR.MINOR.PATCH
- MAJOR: 상태 파일 형식(BACKLOG/ROADMAP/LOG)이 바뀌어 기존 `.autopilot/`과 호환되지 않음
- MINOR: 루프 규칙·발굴 소스·중단 조건 변경
- PATCH: 드라이버 수정, 문구 정리, 버그 수정

## Unreleased
- Skill rules, templates and skill scripts are now in English. New `language` setting in `.autopilot/CONFIG.md` (`auto` = existing state files → README → the user's language → English) sets the language of notes people read; machine-readable values stay English. Korean PROPOSALS statuses from earlier versions (`제안`, `채택`, …) are still understood

## 1.8.2 — 2026-10-19
- release.sh: git 태그 push가 막히면 쓰기 권한이 있는 `gh`(GH_TOKEN)로 GitHub API에서 태그와 Release를 함께 생성. 권한 확인은 `gh auth status` 대신 레포 API로(레포 한정 토큰 지원)
- status.sh: 출력을 `head` 등으로 자를 때 BrokenPipeError 트레이스가 나오던 문제 수정

## 1.8.1 — 2026-10-19
- macOS 기본 환경 호환: release.sh의 `tac`, validate.sh·테스트의 `timeout`(gtimeout·perl 대체), 테스트의 GNU `sed -i` 제거. tac·timeout 없는 PATH로 검증하는 tests/test_portability.sh
- status.sh가 구버전(1.5.x) Stop 훅 설치를 감지해 경고하고 교체 방법 안내. README에 1.5.x 업그레이드 절

## 1.8.0 — 2026-10-19
- 회고(Phase 0.5): 10작업마다 실패·blocked 원인을 분류해 ROADMAP "배운 것"(15줄 이내)에 레포 전용 규칙으로 기록, blocked 작업은 쪼개거나 보류로 이동. LOG 상태 값 정의
- 기능 제안(1-F, `.autopilot/PROPOSALS.md`): 공개 인터페이스 변경·무거운 의존성·구조 개편·방향 선택은 근거·대안·비용·위험과 함께 제안으로 남기고 루프는 계속. 사람이 `채택`하면 다음 발굴에서 작업화(그 범위에서만 인터페이스 변경 허용)
- 통합 정책(`.autopilot/CONFIG.md`, 사람이 정하고 Claude는 읽기만): `local`(기본)·`branch`(작업 브랜치 push)·`pr`(PR 생성, `merge: auto`면 검증 후 머지), `release: auto`는 문서화된 릴리스 절차가 있을 때만. 레포 관례 우선, 막히면 우회 없이 local로 폴백
- 긴 실행: Phase 0에서 LOG는 최근 20개, BACKLOG는 열린 작업과 최근 완료 10행만 읽음. `scripts/archive.sh`가 완료 행 50개·LOG 300개 초과분을 아카이브로 옮김(내용 보존), 중복 확인은 아카이브 grep
- Phase 0 작업 트리 정리가 `.autopilot/` 미커밋 상태(직전 실패의 attempts·LOG)까지 stash해 무한 재시도가 재발하던 버그 수정. local 모드 실패 시 상태만 커밋
- 스킬 description을 현재 기능(직접 실행 탐색·시나리오·이슈 트래커·제안·통합 정책) 기준으로 갱신하고 호출 문구 추가. validate.sh가 description 1024자 제한 검사
- `scripts/status.sh`: 실행·멈춤 여부와 STOP 사유, 통합 설정, 작업 수, 최근 성공률, 열린·blocked 작업, 결정 대기 제안, 최근 기록을 한 화면에 요약 (읽기 전용)
- validate.sh: SKILL.md가 참조하는 assets·scripts 파일이 없으면 FAIL, 참조되지 않는 스킬 파일은 경고. 큰 기능 설계(1-D)가 `assets/feature-template.md`를 가리키도록 수정

## 1.7.0 — 2026-10-19
- 검증 실패 롤백이 `.autopilot/`까지 되돌려 attempts가 사라지고 같은 작업을 무한 재시도하던 버그 수정. 실패 후 세션 연속 모드는 Phase 0으로 복귀
- 발굴: 이슈 트래커·PR 리뷰 코멘트를 매 작업마다 확인(`last_issue_check` 이후만), 라벨로 유형 판정, 같은 우선순위에서 이슈 출처 우선. 본문은 데이터로만 취급하고 읽기 전용
- 발굴: 직접 써보기(탐색적 실행: 문서 명령·진입점을 정상·경계 입력으로, 임시 디렉터리·타임아웃·외부 호출 금지)와 사용 시나리오 3가지 점검 추가. ROADMAP 템플릿에 관찰·시나리오 섹션
- 드라이버: 반복 인자 검증, `claude` 미설치 사전 확인, 반복별 로그 파일, 크래시 한도 종료 코드 1, 레포 하위 폴더에서 실행 가능, `AUTOPILOT_SLEEP`. tests/test_driver.sh 추가, validate.sh 테스트에 시간 제한
- 중단 판정: 실질 작업 0개면 심화 발굴 4단계(정적 → 실행·새 시나리오 → 품질 속성 점검표 → 이슈·보류 재검토)를 모두 거쳐도 0개일 때만 최종 중단. ROADMAP에 심화 발굴 섹션
- 검증: 베이스라인 명령 탐색 확대(레포 문서 우선, go/cargo/gradle/justfile/dotnet 등), 찾은 명령을 ROADMAP에 기록·재사용, 불안정 테스트는 재실행으로 판별해 비교에서 제외, 검증 수단이 없으면 최소 테스트 하네스를 최우선 작업으로

## 1.6.0 — 2026-10-19
- 레포 규칙 개정: Claude가 git flow(feature → develop → release → main)로 자율 개발·릴리스. 버전은 release 브랜치에서 올리고 feature는 `## Unreleased`에 기록
- bump.sh: `## Unreleased`를 새 버전 섹션으로 전환, 실패 시 파일을 바꾸지 않음
- release.sh: `git archive`로 커밋된 내용만 패키징, `--catch-up`(밀린 태그 일괄 처리)·`--dry-run` 추가
- validate.sh: `tests/` 실행, 테스트 스크립트 문법 검사
- Stop 훅: `.autopilot/RUN`이 있을 때만 동작, `$CLAUDE_PROJECT_DIR` 기준 실행, 진척 없이 3회 연속 막으면 STOP을 남기고 해제. 세션 연속 모드 Phase 0에서 `.gitignore`에 실행 산출물 추가, 재호출 시 STOP 정리
- 발굴: 보안 소스를 조직 전용 MCP 이름 대신 생태계 표준 감사 도구·정적 위험 패턴으로 일반화

## 1.5.1 — 2026-10-19
- 플러그인 마켓플레이스 구조로 재편, description 수정, 오픈소스 문서 추가
- validate.sh: LOG 예시 버전·레포 scripts/ 문법 검사 추가, bump.sh: 따옴표 붙은 버전 지원, release.sh: 태그 push 실패 시 로컬 태그 정리

## 1.5.0 — 2026-10-02
- 세션 연속 모드 신설(기본): 터미널 없는 클라우드 세션에서 STOP까지 같은 세션에서 작업을 계속 이어감. Claude가 Stop 훅을 직접 설치(assets/autopilot-stop.sh). 드라이버 모드는 AUTOPILOT_DRIVER=1로 판별

## 1.4.0 — 2026-10-01
- 제품 축 발굴(제품 이해·기능 지도·빠진/약한 기능) 추가, feature/enhance/perf 유형 신설, 큐 비율 규칙(제품 축 절반 이상, test 최대 2개), 큰 기능의 다단계 설계 문서(features/<slug>.md), 공개 인터페이스 추가 허용·변경 금지, 조건부 의존성 추가 허용

## 1.3.0 — 2026-10-01
- 큐가 비면 횟수 제한 없이 재발굴
- 작업을 실질(fix/security/test/todo/cleanup)과 보조(lint/docs/refactor)로 구분
- 보조 작업은 같은 사이클에 실질 작업이 있을 때만 큐에 추가
- 재발굴 결과 실질 작업 0개면 최종 중단, STOP 파일에 요약 기록
- LOG 항목에 스킬 버전 기록

## 1.2.0 — 2026-10-01
- 드라이버 프롬프트가 레포 경로 대신 스킬 이름으로 호출
- 기본 권한 모드를 `--allowedTools` 허용 목록으로 변경 (`AUTOPILOT_PERMISSION=skip`으로 기존 방식 선택 가능)
- 드라이버가 `.autopilot/driver-logs/`, `.autopilot/STOP`을 `.gitignore`에 자동 추가
- 드라이버는 레포에 커밋하지 않고 스킬 폴더에서 실행하도록 안내 변경

## 1.1.0 — 2026-10-01
- 드라이버 스크립트를 스킬 내부 `scripts/`로 이동, 레포 루트 실행으로 변경

## 1.0.0 — 2026-10-01
- 최초 버전: 1회 호출 1작업, 상태 파일 기반 루프, 반복 실패 차단
