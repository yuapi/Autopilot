# Changelog

버전 규칙: MAJOR.MINOR.PATCH
- MAJOR: 상태 파일 형식(BACKLOG/ROADMAP/LOG)이 바뀌어 기존 `.autopilot/`과 호환되지 않음
- MINOR: 루프 규칙·발굴 소스·중단 조건 변경
- PATCH: 드라이버 수정, 문구 정리, 버그 수정

## 1.5.1 — 2026-10-19
- 플러그인 마켓플레이스 구조로 재편, description 수정, 오픈소스 문서 추가

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
