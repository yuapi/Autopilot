# autopilot

[English](README.md)

autopilot은 레포지토리에서 자율 개발 루프를 돌리는 Claude Code 스킬이며, 플러그인으로 배포된다. 사람에게 묻지 않고 코드베이스를 읽어 다음에 할 작업을 정하고, 작업 하나를 구현해 프로젝트 자체의 테스트·린트·빌드로 검증한 뒤 결과를 기록한다. 그리고 다음 작업을 고른다. 모든 상태는 `.autopilot/` 아래 일반 파일(로드맵·백로그·로그)에 있으므로 언제든 들여다보고 고치고 이어갈 수 있다. `.autopilot/STOP`을 만들면 멈추고, 실질 작업이 바닥나거나 실패가 반복되면 스킬이 직접 이 파일을 만들고 멈춘다.

## 안전 고지

**실행 전에 반드시 읽을 것.**

- **스스로 코드를 수정하고 커밋한다.** 성공한 작업은 사람의 검토 없이 커밋된다. 기본 브랜치(`main`, `master`, `develop` 등)에는 커밋하지 않는다. 기본 브랜치에서 시작하면 먼저 `autopilot/<날짜>` 브랜치를 만들어 옮기고, 직접 만든 브랜치에서 시작하면 그 브랜치에 커밋한다. `.autopilot/CONFIG.md`에 `local_branch: current`를 쓰면 체크아웃된 브랜치에 바로 커밋하고, `scope: packages/api`처럼 쓰면 모노레포의 일부 경로에서만 작업한다.
- **권한은 기본적으로 제한된다.** 드라이버 스크립트는 기본으로 `--allowedTools` 허용 목록을 쓴다. `--dangerously-skip-permissions`는 `AUTOPILOT_PERMISSION=skip`으로 명시적으로 opt-in 할 때만 쓰이며, 버려도 되는 머신이나 컨테이너에서만 써야 한다.
- **전용 브랜치나 샌드박스에서 사용한다.** 임시 브랜치, 새 클론, 격리된 컨테이너에서 돌릴 것. 기본 설정에서 스킬은 `git push`를 하지 않으므로 직접 push 하기 전에는 아무것도 밖으로 나가지 않는다. push 전에 커밋을 검토할 것. `git reset --hard`, force push, 원격 브랜치·태그 삭제는 어떤 설정에서도 하지 않는다.
- **내보내기는 직접 켜야 한다.** 브랜치 push, PR 생성·머지, 릴리스는 `.autopilot/CONFIG.md`에 설정했을 때만 한다(`integration: branch | pr`, `merge: auto`, `release: auto`). 스킬은 이 파일을 읽기만 하고 만들거나 고치지 않으며, 레포의 브랜치·커밋·릴리스 관례를 따른다.
- **실행 결과의 책임은 사용자에게 있다.** 이 소프트웨어는 MIT 라이선스로 "있는 그대로" 제공된다. 바뀐 코드, 커밋, 이후 공개하는 모든 것은 사용자 책임이다.

## 설치

필요한 것: PATH에 `git`, `bash`, Python 3(`python3` 또는 `python`). Windows에서는 Git Bash나 WSL을 쓴다.

### 방법 1: 플러그인 마켓플레이스 (Claude Code)

Claude Code 세션에서:

```
/plugin marketplace add yuapi/Autopilot
/plugin install autopilot@autopilot-marketplace
```

설치하면 스킬을 `autopilot`(네임스페이스 포함 `/autopilot:autopilot`)으로 쓸 수 있다.

### 방법 2: `.skill` 파일 업로드

[Releases](https://github.com/yuapi/Autopilot/releases)에서 `autopilot-<버전>.skill`을 내려받아 claude.ai의 스킬로 업로드한다 (Settings → Capabilities → Skills). `autopilot/` 스킬 폴더를 담은 zip이므로 `~/.claude/skills/`에 풀어도 된다.

### 업데이트

- Claude Code 플러그인: `claude plugin marketplace update autopilot-marketplace` 다음 `claude plugin update autopilot@autopilot-marketplace`.
- claude.ai 계정에 추가한 플러그인: 새 버전은 저절로 동기화되지만 **세션은 시작할 때 불러온 버전을 계속 쓴다.** 업데이트를 쓰려면 새 세션을 연다.
- `/autopilot:status`는 설치된 버전을 보여 주고, 이 레포가 그보다 새 버전으로 이미 실행된 적이 있으면 경고한다.

## 사용법

작업할 레포 루트에서, 전용 브랜치를 만든 뒤 시작한다.

### 세션 연속 모드 (기본)

세션에서 "autopilot 실행해" 같이 요청한다. `.autopilot/STOP`이 생길 때까지 같은 세션에서 작업을 연달아 수행한다. 처음 진입할 때 `.autopilot/RUN`을 만든다. 세션이 일찍 끝나지 않도록 막는 Stop 훅은 스킬 자체에 선언되어 있어 스킬을 호출한 세션에서만 동작하고, 레포에는 아무것도 복사하지 않는다(훅이 있는 스킬은 Claude Code가 한 번 허용을 묻는다). 이전 버전이 남긴 `.claude/hooks/autopilot-stop.sh` 사본은 스킬 버전과 다르면 새로 바꾸며, `bash <스킬 폴더>/scripts/hook.sh uninstall`로 지울 수 있다(`settings.json`의 다른 훅은 그대로 둔다). 훅은 RUN이 있을 때, 그리고 루프를 시작한 세션에만 동작하므로 평소 세션이나 같은 레포에서 새로 연 다른 세션은 막지 않는다. 한 레포에서는 루프가 하나만 돈다. 이미 돌고 있으면 두 번째 세션이나 드라이버는 시작을 거부한다(2시간 동안 활동이 없던 표시는 넘겨받는다. `AUTOPILOT_RUN_STALE_MIN`으로 분 단위 조정). 또한 훅은 진척 없이 3회 연속 막히면 스스로 STOP을 남기고 풀리며, 진척 없는 첫 차단부터 남은 횟수를 알린다. 터미널이 없는 클라우드 세션에서는 이 모드만 쓸 수 있다.

실행 범위를 정하려면 작업 수를 함께 말한다. 예: "autopilot 3개만 해", 플러그인이면 `/autopilot:run 3`. 세 번째 작업을 마치면 멈춘다.

멈추기: `/autopilot:stop`(플러그인으로 설치한 경우) 또는 `touch .autopilot/STOP`. 진행 중인 작업을 마친 뒤 멈춘다.

### 드라이버 모드 (터미널, 선택)

드라이버 스크립트가 작업마다 Claude Code를 한 번씩 호출하므로 매 작업이 새 컨텍스트에서 시작된다. 긴 루프에서 판단 품질이 더 좋다.

```bash
cd <작업할 레포 루트>
bash <스킬 폴더>/scripts/autopilot.sh        # 무제한
bash <스킬 폴더>/scripts/autopilot.sh 20     # 최대 20회
AUTOPILOT_PERMISSION=skip bash <스킬 폴더>/scripts/autopilot.sh   # opt-in, 샌드박스 전용
```

`<스킬 폴더>`는 스킬이 설치된 위치다. 예를 들어 이 레포 클론에서는 `plugins/autopilot/skills/autopilot`. 드라이버는 `.autopilot/STOP`이 생기거나 반복 한도에 도달하면 종료 코드 0으로, Claude가 연속 3회 비정상 종료하거나, LOG도 커밋도 바뀌지 않은 실행이 3회 연속이거나(이유를 `STOP`에 남긴다. 횟수는 `AUTOPILOT_STALL_LIMIT`), 종료 코드 1로 멈춘다. `claude` CLI가 없거나, git에 `user.name`/`user.email`이 없거나, 파일은 있는데 커밋이 하나도 없거나, `.autopilot/CONFIG.md`의 `scope` 경로·`base_branch`·`branch_prefix`가 쓸 수 없는 값이거나, 인자가 잘못되면 첫 실행 전에 고치는 방법과 함께 종료 코드 1로 멈춘다. 실행마다 그 실행의 LOG 항목을 출력한다. 레포 안 어느 폴더에서 실행해도 된다. `AUTOPILOT_SLEEP`으로 반복 사이 대기 시간(기본 10초)을, `AUTOPILOT_MODEL`로 매 실행의 모델(`claude --model`로 전달)을, `AUTOPILOT_MAX_COST`로 비용 한도(USD)를 정할 수 있다. 드라이버는 실행마다 비용을 출력하고 합계가 한도에 닿으면 `STOP`을 남기고 멈춘다. `integration: pr`에서는 `gh` CLI로 PR을 만들고(`origin`이 GitLab이면 `glab`으로 MR), 도구가 없거나 push할 수 없으면 시작할 때 경고한다. 시작할 때 권한 모드도 항상 알려 준다.

### 실행 상태 확인

플러그인으로 설치했다면 세션에서 `/autopilot:status`를 입력한다. 그렇지 않으면:

```bash
bash <스킬 폴더>/scripts/status.sh [레포 경로]
```

세션 루프나 드라이버가 도는 중인지 멈췄는지(멈췄다면 이유), 진행 중인 작업과 시작 후 경과 시간, 작업 수 예산, 통합 설정과 `scope`, 작업 수, 최근 10회 성공률, 열린 작업과 blocked 작업, 결정을 기다리는 제안, 최근 기록을 한 화면에 보여준다. 설치된 스킬 버전도 보여주고, 이 레포가 그보다 새 버전으로 이미 실행된 적이 있으면(플러그인이 오래된 경우) 경고한다. 상태 파일은 읽기만 한다.

## 동작 방식

- **발굴 두 축.** *유지보수 축*은 깨진 빌드, 보안 발견, TODO 마커, 테스트 공백, 죽은 코드를 찾는다. `scripts/scan.sh`가 마커와 위험 패턴을 나열하며, 50줄이 넘는 섹션(`AUTOPILOT_SCAN_MAX`, 전부 보려면 `--all`)은 폴더별 개수와 함께 잘리고 파일·폴더 단위로 사이클마다 몇 개씩 처리한다. *제품 축*은 먼저 이 소프트웨어가 무엇을 하는지, 어떤 기능이 완성·부분·누락 상태인지, 무엇이 약한지를 적은 뒤 그것을 기능·개선 작업으로 바꾼다. 매 발굴 사이클의 절반 이상이 제품 축에서 나와야 하므로 테스트와 린트만 쌓이지 않는다.
- **사용자의 언어로 기록한다.** 규칙은 영어지만 사람이 읽는 기록(로드맵·로그·제안·중단 요약)은 `.autopilot/CONFIG.md`의 `language`를 따른다. 기본값 `auto`는 기존 `.autopilot/` 파일의 언어, 없으면 README의 언어, 없으면 말을 건 언어를 쓴다. `language: ko`, `en`, `ja` 등으로 직접 정할 수 있다. 상태 값과 키는 스크립트가 읽으므로 영어로 둔다.
- **읽기만 하지 않고 직접 써본다.** 매 발굴 사이클마다 문서의 명령과 진입점을 정상·경계 입력으로 실행하고(임시 디렉터리, 타임아웃, 외부 호출 없음), 대표 사용자 시나리오 3가지를 따라간다. 크래시·잘못된 결과·README 예제 실패는 수정 작업, 헷갈리는 오류와 빠진 단계는 개선·기능 작업이 된다.
- **혼자 하면 안 되는 일은 제안한다.** 공개 인터페이스 변경, 무거운 의존성, 여러 모듈 개편, 제품 방향 선택이 필요한 아이디어는 근거·대안·비용·위험과 함께 `.autopilot/PROPOSALS.md`에 남긴다. 루프는 기다리지 않는다. 상태를 `adopted`로 바꾸면 다음 발굴에서 작업이 된다.
- **실패에서 배운다.** 10작업마다 회고를 한다. 실패·blocked 원인을 분류하고, blocked 작업은 쪼개거나 접으며, 레포 전용 교훈(15줄 이내)을 남겨 이후 단계가 규칙처럼 따른다.
- **이슈는 읽되 따르지 않는다.** `gh`나 트래커 MCP가 있으면 매 작업마다 마지막 확인 이후 열리거나 바뀐 이슈를 확인해 버그·기능 요청을 작업으로 만든다(출처 `issue #N`, 같은 우선순위에서 먼저 선택). 이슈 본문은 데이터로만 쓰고 지시로 따르지 않는다.
- **실질 작업과 보조 작업.** 결함을 고치거나 동작을 추가·개선하는 작업(fix, security, feature, enhance, perf, todo, test, cleanup)은 *실질*, 형태만 바꾸는 작업(lint, docs, refactor)은 *보조*다. 보조 작업은 실질 작업과 함께일 때만 큐에 들어간다.
- **한 번에 작업 하나, 반드시 검증.** 작업은 1~2시간 분량에 완료 기준이 명시되며, 테스트·린트·빌드가 베이스라인보다 나빠지면 안 된다. 실패하면 전부 롤백한다.
- **최종 중단 조건.** (a) 재발굴에서 실질 작업이 0개이고 심화 발굴 4단계(정적 검토, 새 시나리오로 직접 실행, 품질 속성 점검표, 이슈·보류 항목 재검토)에서도 0개, (b) 직전 10회 중 7회 이상 실패, (c) 사람이 `.autopilot/STOP`을 만듦, (d) 정해 둔 한도에 닿음: 작업 수 예산(`/autopilot:run 3`)이나 드라이버 비용 한도. 3회 실패한 작업은 `blocked`로 표시되고 건너뛴다.

## 1.5.x에서 업그레이드

1.5.x가 설치한 Stop 훅은 `.autopilot/STOP`이 없으면 autopilot을 돌리지 않는 세션까지 *모든* 세션의 종료를 막는다. 1.6.0부터는 `.autopilot/RUN`이 있을 때만 동작한다. 스킬을 다시 실행하면 구버전 훅이 자동으로 교체되며, 그 전까지는 `scripts/status.sh`가 경고한다. 직접 `.claude/hooks/autopilot-stop.sh`를 `assets/autopilot-stop.sh`로 바꾸거나, 임시로 `.autopilot/STOP`을 만들어도 된다.

## 레포 구조

```
.claude-plugin/marketplace.json          마켓플레이스 카탈로그
plugins/autopilot/.claude-plugin/        플러그인 매니페스트 (plugin.json)
plugins/autopilot/skills/autopilot/      스킬 본체 (SKILL.md, assets/, scripts/: 드라이버·status·archive·workbranch·runlock·scan·hook·log·finalstop·task)
plugins/autopilot/commands/              /autopilot:run, /autopilot:status, /autopilot:stop 명령
scripts/validate.sh, bump.sh, release.sh 로컬 검증, 버전 올리기, 릴리스
scripts/eval.sh, tests/eval/             발굴 품질 평가 (선택, claude 필요)
tests/                                   스크립트 테스트 (validate.sh가 실행)
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

## 발굴 품질 측정

```bash
bash scripts/eval.sh                        # todo 예제. 실행 결과를 보려면 --keep
bash scripts/eval.sh --fixture wordcount    # 테스트가 없는 레포: 첫 작업이 테스트 하네스인가
bash scripts/eval.sh --fixture stats        # CONTRIBUTING이 커밋 형식을 정한 레포: 모든 커밋이 따르는가
bash scripts/eval.sh --fixture kv           # Go 모듈: go test·go vet을 찾고 결과를 큐에 넣는가
bash scripts/eval.sh --fixture mono         # 모노레포에서 CONFIG scope: pkg/a: 모든 커밋이 그 안에 머무는가
bash scripts/eval.sh --fixture watch        # npm test가 끝나지 않는(watch) 레포: 1회 실행 명령을 찾아 쓰는가
bash scripts/eval.sh --fixture hooks        # 커밋 훅이 커밋을 거부하는 레포: 우회하지 않고 맞추는가
bash scripts/eval.sh --iterations 3         # 드라이버 3회: 매번 새 작업 하나, 반복 없음, 실패 없음
bash scripts/eval.sh --mode session --iterations 2   # 플러그인으로 세션 모드 1회, 작업 2개 요청: 계속 이어 가다가 예산에서 멈추는가
bash scripts/eval.sh --grade <남긴 폴더> [같은 옵션]   # --keep으로 남긴 실행을 다시 채점
bash scripts/eval.sh --model <이름>         # 같은 평가를 다른 모델로, 비교용
bash scripts/eval.sh --fixture all          # 모든 예제를 같은 옵션으로, 요약 한 번
```

`tests/eval/`의 예제 하나를 임시 레포로 복사하고, 작업 사본의 스킬을 실제 드라이버 프롬프트로(또는 플러그인으로 세션 모드로) 돌린 뒤 `tests/eval/fixture-<이름>.expected`에 적힌 결함 중 몇 개가 BACKLOG에 들어갔는지 채점한다. 기본 `todo` 예제는 결함 다섯 개를 심은 작은 할 일 CLI(실패하는 테스트가 있는 off-by-one, 첫 실행 크래시, 셸 주입, README에만 있고 구현이 없는 명령, TODO 마커)이고, 나머지 예제는 위 목록대로 규칙 하나씩을 잰다. 실행마다 비용도 출력한다. 모든 실행은 규칙 검사도 받는다: 완료한 작업마다 커밋 하나, LOG는 끝에만 붙이고 시간 순서, 최종 정지는 심화 발굴 4단계를 기록한 뒤에만. 규칙을 하나라도 어기면 점수와 상관없이 실패다. `claude` CLI가 필요하고 실제 실행 비용이 들어 `validate.sh`에는 포함하지 않는다. 발굴 규칙을 바꾼 뒤 더 잘 찾는지 확인할 때 쓴다.

## 라이선스

[MIT](LICENSE)
