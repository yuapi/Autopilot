# 버전 규칙

형식: `MAJOR.MINOR.PATCH` (스킬과 플러그인이 같은 번호를 쓴다)

| 구분 | 언제 | 예 |
|---|---|---|
| **MAJOR** | `.autopilot/` 상태 파일(BACKLOG/ROADMAP/LOG/features) 형식이 바뀌어 기존 상태와 호환되지 않음 | BACKLOG 열 구조 변경, 상태 값 이름 변경 |
| **MINOR** | 루프 규칙·발굴 소스·선택 우선순위·중단 조건 등 SKILL.md의 동작 규칙 변경 | 새 작업 유형, 큐 비율 변경, 실행 모드 추가 |
| **PATCH** | 스크립트 수정, 문구 정리, 버그 수정, 문서·매니페스트 정리 | 드라이버 버그, 오탈자, README |

애매하면 큰 쪽을 고른다.

## 버전을 바꾸는 유일한 방법

feature 작업은 버전을 올리지 않고 `CHANGELOG.md`의 `## Unreleased` 아래에 한 줄을 쓴다. 버전은 `release/<ver>` 브랜치에서 올린다.

```bash
bash scripts/bump.sh <major|minor|patch> ["<추가 요약>"]
```

- `## Unreleased`에 항목이 있으면 그 제목을 `## x.y.z — YYYY-MM-DD`로 바꾸고, 빈 `## Unreleased`를 새로 위에 둔다. 요약을 주면 항목 끝에 덧붙인다.
- `## Unreleased`가 없거나 비어 있으면 요약이 필수이고, 그 요약으로 새 항목을 만든다.

`bump.sh`가 건드리는 곳:

| 파일 | 위치 |
|---|---|
| `plugins/autopilot/skills/autopilot/SKILL.md` | frontmatter `metadata.version` |
| 〃 | 본문 `**버전 x.y.z**` |
| 〃 | LOG 형식 예시의 `skill x.y.z` |
| `plugins/autopilot/.claude-plugin/plugin.json` | `version` |
| `CHANGELOG.md` | `## Unreleased` → `## x.y.z — YYYY-MM-DD` |

커밋은 하지 않는다.

## 세 곳이 항상 같아야 하는 이유

- **SKILL.md `metadata.version`** — 스킬이 매 LOG 항목에 이 번호를 남긴다. 사용자의 `.autopilot/LOG.md` 를 보고 어느 규칙으로 돌았는지 추적하는 유일한 근거다.
- **plugin.json `version`** — Claude Code가 플러그인 업데이트 여부를 이 값으로 판단한다. 바뀌지 않으면 사용자는 새 스킬을 받지 못하고, 잘못 바뀌면 같은 내용이 다른 버전으로 배포된다.
- **CHANGELOG 최상단** — 릴리스 노트(`release.sh` 가 이 섹션을 GitHub Release 본문으로 쓴다)와 `.skill` 파일 이름이 이 번호를 따른다.

하나라도 어긋나면 "LOG에 찍힌 버전 ≠ 설치된 버전 ≠ 릴리스 노트" 가 되어 버그 재현이 불가능해진다. `validate.sh` 가 다섯 값(본문 표기·LOG 예시 포함)을 비교해 다르면 FAIL 한다.
