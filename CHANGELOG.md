# Changelog

버전 규칙: MAJOR.MINOR.PATCH
- MAJOR: 상태 파일 형식(BACKLOG/ROADMAP/LOG)이 바뀌어 기존 `.autopilot/`과 호환되지 않음
- MINOR: 루프 규칙·발굴 소스·중단 조건 변경
- PATCH: 드라이버 수정, 문구 정리, 버그 수정

## Unreleased

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
