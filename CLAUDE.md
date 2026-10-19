# CLAUDE.md

이 레포는 자율 개발 루프 스킬 `autopilot`을 Claude Code 플러그인 마켓플레이스 형태로 배포하는 오픈소스 레포다.

## 작업 전 반드시

`docs/` 를 먼저 읽는다: `plugin-structure.md`, `versioning.md`, `release-process.md`, `open-source-checklist.md`, `skill-design.md`.

## 절대 규칙

- GitHub Actions 워크플로(`.github/workflows/`)를 만들지 않는다.
- 버전은 `scripts/bump.sh` 로만 바꾼다. 버전 문자열을 손으로 고치지 않는다.
- 커밋 전에 `bash scripts/validate.sh` 를 실행하고 PASS를 확인한다.
- `scripts/release.sh` 는 사람이 실행한다. 에이전트는 실행하지 않는다.
- 스킬 본체(`plugins/autopilot/skills/autopilot/`)를 고치면 `CHANGELOG.md` 항목이 반드시 있어야 한다.
- 브랜치는 git flow: `feature/*` 는 `develop` 에서 따고 `develop` 으로 병합, `main` 은 릴리스 전용 (`CONTRIBUTING.md`).
