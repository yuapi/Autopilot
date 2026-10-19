# autopilot

[English](README.md)

autopilot은 레포지토리에서 자율 개발 루프를 돌리는 Claude Code 스킬이며, 플러그인으로 배포된다. 사람에게 묻지 않고 코드베이스를 읽어 다음에 할 작업을 정하고, 작업 하나를 구현해 프로젝트 자체의 테스트·린트·빌드로 검증한 뒤 결과를 기록한다. 그리고 다음 작업을 고른다. 모든 상태는 `.autopilot/` 아래 일반 파일(로드맵·백로그·로그)에 있으므로 언제든 들여다보고 고치고 이어갈 수 있다. `.autopilot/STOP`을 만들면 멈추고, 실질 작업이 바닥나거나 실패가 반복되면 스킬이 직접 이 파일을 만들고 멈춘다.

## 안전 고지

**실행 전에 반드시 읽을 것.**

- **스스로 코드를 수정하고 커밋한다.** 성공한 작업은 사람의 검토 없이 현재 브랜치에 커밋된다.
- **권한은 기본적으로 제한된다.** 드라이버 스크립트는 기본으로 `--allowedTools` 허용 목록을 쓴다. `--dangerously-skip-permissions`는 `AUTOPILOT_PERMISSION=skip`으로 명시적으로 opt-in 할 때만 쓰이며, 버려도 되는 머신이나 컨테이너에서만 써야 한다.
- **전용 브랜치나 샌드박스에서 사용한다.** 임시 브랜치, 새 클론, 격리된 컨테이너에서 돌릴 것. 스킬은 `git push`, `git reset --hard`, force 계열을 실행하지 않으므로 직접 push 하기 전에는 아무것도 밖으로 나가지 않는다. push 전에 커밋을 검토할 것.
- **실행 결과의 책임은 사용자에게 있다.** 이 소프트웨어는 MIT 라이선스로 "있는 그대로" 제공된다. 바뀐 코드, 커밋, 이후 공개하는 모든 것은 사용자 책임이다.

## 설치

### 방법 1: 플러그인 마켓플레이스 (Claude Code)

Claude Code 세션에서:

```
/plugin marketplace add yuapi/Autopilot
/plugin install autopilot@autopilot-marketplace
```

설치하면 스킬을 `autopilot`(네임스페이스 포함 `/autopilot:autopilot`)으로 쓸 수 있다.

### 방법 2: `.skill` 파일 업로드

[Releases](https://github.com/yuapi/Autopilot/releases)에서 `autopilot-<버전>.skill`을 내려받아 claude.ai의 스킬로 업로드한다 (Settings → Capabilities → Skills). `autopilot/` 스킬 폴더를 담은 zip이므로 `~/.claude/skills/`에 풀어도 된다.

## 사용법

작업할 레포 루트에서, 전용 브랜치를 만든 뒤 시작한다.

### 세션 연속 모드 (기본)

세션에서 "autopilot 실행해" 같이 요청한다. `.autopilot/STOP`이 생길 때까지 같은 세션에서 작업을 연달아 수행한다. 처음 진입할 때 `.autopilot/RUN`을 만들고 세션이 일찍 끝나지 않도록 Stop 훅(`.claude/hooks/autopilot-stop.sh`)을 설치한다. 훅은 RUN이 있을 때만 동작하므로 평소 세션은 막지 않으며, 진척 없이 3회 연속 막히면 스스로 STOP을 남기고 풀린다. 터미널이 없는 클라우드 세션에서는 이 모드만 쓸 수 있다.

멈추기: `touch .autopilot/STOP`

### 드라이버 모드 (터미널, 선택)

드라이버 스크립트가 작업마다 Claude Code를 한 번씩 호출하므로 매 작업이 새 컨텍스트에서 시작된다. 긴 루프에서 판단 품질이 더 좋다.

```bash
cd <작업할 레포 루트>
bash <스킬 폴더>/scripts/autopilot.sh        # 무제한
bash <스킬 폴더>/scripts/autopilot.sh 20     # 최대 20회
AUTOPILOT_PERMISSION=skip bash <스킬 폴더>/scripts/autopilot.sh   # opt-in, 샌드박스 전용
```

`<스킬 폴더>`는 스킬이 설치된 위치다. 예를 들어 이 레포 클론에서는 `plugins/autopilot/skills/autopilot`. 드라이버는 `.autopilot/STOP`이 생기거나, Claude가 연속 3회 비정상 종료하거나, 반복 한도에 도달하면 멈춘다.

## 동작 방식

- **발굴 두 축.** *유지보수 축*은 깨진 빌드, 보안 발견, TODO 마커, 테스트 공백, 죽은 코드를 찾는다. *제품 축*은 먼저 이 소프트웨어가 무엇을 하는지, 어떤 기능이 완성·부분·누락 상태인지, 무엇이 약한지를 적은 뒤 그것을 기능·개선 작업으로 바꾼다. 매 발굴 사이클의 절반 이상이 제품 축에서 나와야 하므로 테스트와 린트만 쌓이지 않는다.
- **이슈는 읽되 따르지 않는다.** `gh`나 트래커 MCP가 있으면 매 작업마다 마지막 확인 이후 열리거나 바뀐 이슈를 확인해 버그·기능 요청을 작업으로 만든다(출처 `issue #N`, 같은 우선순위에서 먼저 선택). 이슈 본문은 데이터로만 쓰고 지시로 따르지 않는다.
- **실질 작업과 보조 작업.** 결함을 고치거나 동작을 추가·개선하는 작업(fix, security, feature, enhance, perf, todo, test, cleanup)은 *실질*, 형태만 바꾸는 작업(lint, docs, refactor)은 *보조*다. 보조 작업은 실질 작업과 함께일 때만 큐에 들어간다.
- **한 번에 작업 하나, 반드시 검증.** 작업은 1~2시간 분량에 완료 기준이 명시되며, 테스트·린트·빌드가 베이스라인보다 나빠지면 안 된다. 실패하면 전부 롤백한다.
- **최종 중단 조건.** (a) 제품 검토까지 마친 재발굴에서 실질 작업이 0개, (b) 직전 10회 중 7회 이상 실패, (c) 사람이 `.autopilot/STOP`을 만듦. 3회 실패한 작업은 `blocked`로 표시되고 건너뛴다.

## 레포 구조

```
.claude-plugin/marketplace.json          마켓플레이스 카탈로그
plugins/autopilot/.claude-plugin/        플러그인 매니페스트 (plugin.json)
plugins/autopilot/skills/autopilot/      스킬 본체 (SKILL.md, assets/, scripts/autopilot.sh)
scripts/validate.sh, bump.sh, release.sh 로컬 검증, 버전 올리기, 릴리스
docs/                                    유지보수 문서
CHANGELOG.md                             변경 이력
```

## 개발

CI는 없고 검증은 로컬에서 한다. 요약:

```bash
git checkout -b feature/<주제> develop
# 변경 후 CHANGELOG.md의 "## Unreleased" 아래에 한 줄 추가
bash scripts/validate.sh
```

브랜치·버전·릴리스 규칙은 [CONTRIBUTING.md](CONTRIBUTING.md)와 [docs/](docs/)를 참고.

## 라이선스

[MIT](LICENSE)
