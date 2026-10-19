# CLAUDE.md

이 레포는 자율 개발 루프 스킬 `autopilot`을 Claude Code 플러그인 마켓플레이스로 배포한다.
**이 레포는 Claude가 자율적으로 개발·릴리스한다.** 사람의 지시가 없어도 아래 절차대로 다음 일을 찾아 끝까지 진행한다.

## 세션 시작 시

1. `docs/`를 읽는다. 특히 `skill-design.md`는 SKILL.md를 고치기 전에 반드시 읽는다.
2. `.autopilot/ROADMAP.md`, `.autopilot/BACKLOG.md`, `.autopilot/LOG.md`의 최근 항목, `.autopilot/PROPOSALS.md`를 읽는다. 이 레포 자체의 개발 상태다. `.autopilot/CONFIG.md`(integration: pr, merge·release: auto)가 아래 흐름을 스킬 설정으로 표현한 것이다.
3. 사람이 구체적인 요청을 했으면 그것이 우선이다. 요청이 없거나 "알아서"라면 BACKLOG에서 다음 작업을 골라 진행한다. BACKLOG 운영 방식은 autopilot 스킬 절차를 따른다(발굴·선택·검증·기록).

## 개발 흐름 (git flow, Claude가 끝까지 수행)

| 브랜치 | 용도 |
|---|---|
| `main` | 릴리스된 코드만. 커밋마다 태그 `v<ver>` 대상 |
| `develop` | 통합 브랜치 |
| `feature/<slug>` | 작업 하나. `develop`에서 따고 PR로 `develop`에 병합 |
| `release/<ver>` | 릴리스 준비. `develop`에서 따고 PR로 `main`에 병합 |
| `hotfix/<ver>` | `main`의 긴급 수정. `main`에 병합 후 `develop`에 역병합 |

작업 하나의 순서:

1. `git checkout -b feature/<slug> origin/develop`
2. 구현. 스킬·스크립트·문서를 바꾸면 `CHANGELOG.md`의 `## Unreleased` 아래에 한 줄을 추가한다.
3. `bash scripts/validate.sh` → `결과: PASS` 확인 (테스트 포함). 실패하면 고치거나 버린다.
4. 커밋 규칙(아래)에 맞춰 커밋 → `git push -u origin feature/<slug>`
5. PR(`feature/<slug>` → `develop`)을 만들고, 본문에 변경·검증 결과를 쓴 뒤 **merge commit 방식으로 직접 머지**한다.

## 릴리스 (Claude가 판단해 수행)

`develop`의 `## Unreleased`에 실질 변경(스킬 동작 변경, 버그 수정, 스크립트 기능)이 쌓이면 릴리스한다. 문서·문구만 바뀐 경우는 다음 실질 변경과 묶는다.

1. 버전 종류 결정: 상태 파일 형식 비호환 → `major`, SKILL.md 동작 규칙 변경·기능 추가 → `minor`, 그 외 → `patch` (`docs/versioning.md`).
2. `git checkout -b release/<ver> origin/develop` → `bash scripts/bump.sh <kind>` (Unreleased 항목이 새 버전 섹션이 된다) → validate → 커밋·push
3. PR `release/<ver>` → `main` 생성·머지, 이어서 PR `main` → `develop` 역병합 생성·머지
4. `main`을 받아 `bash scripts/release.sh` 실행 (태그·`.skill` 패키지·GitHub Release)
5. git 태그 push가 막힌 환경(클라우드 세션)에서는 `release.sh`가 환경의 `GH_TOKEN`(사람이 넣어 둔 PAT)으로 GitHub API를 써서 태그와 Release를 만든다. `gh`도 쓸 수 없으면 우회하지 않고 LOG에 "태그 대기"로 남긴 뒤 다음 작업을 계속한다. 밀린 릴리스는 `bash scripts/release.sh --catch-up`으로 한 번에 처리한다.

## 커밋 규칙 (Conventional Commits)

```
<type>(<scope>): <한국어 요약, 명령형·마침표 없음>

<본문: 무엇을 왜. 72자 줄바꿈>
```

- type: `feat` `fix` `docs` `test` `refactor` `chore` `build` / 릴리스 커밋은 `chore(release): <ver>`
- scope 예: `skill` `hook` `driver` `validate` `bump` `release` `repo` `autopilot`(이 레포의 `.autopilot/` 상태)
- 작업 하나 = PR 하나. 한 PR 안에서 성격이 다른 변경은 커밋을 나눈다.

## 절대 규칙

- GitHub Actions 워크플로를 만들지 않는다. 검증은 `scripts/validate.sh`로 로컬에서 한다.
- 버전 문자열은 `scripts/bump.sh`로만 바꾼다.
- `main`·`develop`에 직접 push하거나 force push하지 않는다. 공유 브랜치의 기록을 다시 쓰지 않는다. 태그를 지우거나 다시 쓰지 않는다.
- 권한 검사·정책에 막힌 동작은 우회하지 않는다. 막힌 지점을 LOG에 기록하고 나머지 작업을 계속한다.
- 스킬 본체를 고칠 때 `docs/skill-design.md`의 설계 의도를 깨면 그 문서도 같은 PR에서 고치고 이유를 쓴다.
- 비밀값·토큰을 만들거나 커밋하지 않는다.

## 브랜치 정리

GitHub 레포 설정의 "Automatically delete head branches"로 머지된 PR의 head 브랜치를 자동 삭제한다. 그래서 `develop`을 PR의 head로 쓰지 않는다(역병합은 `main` → `develop`).
