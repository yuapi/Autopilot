# 플러그인·마켓플레이스 구조 규칙

공식 문서 요약 (2026-10 확인). 규칙이 바뀌었을 수 있으니 매니페스트를 고치기 전에 원문을 다시 확인한다.

출처:
- 플러그인 개요: https://code.claude.com/docs/en/plugins
- 플러그인 매니페스트 레퍼런스: https://code.claude.com/docs/en/plugins-reference
- 마켓플레이스 만들기: https://code.claude.com/docs/en/plugin-marketplaces
- 마켓플레이스 레퍼런스: https://code.claude.com/docs/en/plugins/marketplace-reference

## 이 레포의 구조

```
.claude-plugin/marketplace.json                 ← 마켓플레이스 루트 = 레포 루트
plugins/autopilot/                              ← 플러그인 루트
plugins/autopilot/.claude-plugin/plugin.json    ← 매니페스트 (이 폴더엔 이것만)
plugins/autopilot/skills/autopilot/SKILL.md     ← 스킬 (skills/<name>/SKILL.md)
```

## marketplace.json

- 위치: `<마켓플레이스 루트>/.claude-plugin/marketplace.json`.
- 필수: `name`, `owner`(`owner.name` 필수, `email`·`url` 선택), `plugins` 배열.
- `description` 은 선택이지만 없으면 `claude plugin validate` 가 경고한다.
- `name`: 영문자·숫자·`.`·`_`·`-`, 영문자/숫자로 시작, `..` 금지. 사용자가 `<plugin>@<marketplace>` 로 입력한다.
- 플러그인 항목 필수: `name`, `source`. 선택: `description`, `version`, `category`, `tags`, `strict` 등.
- 상대경로 `source` 는 **마켓플레이스 루트 기준**(`.claude-plugin/` 기준 아님)이며 `./` 로 시작해야 한다. `..` 포함 시 validate 오류.
- 존재하지 않는 경로는 validate 는 통과하고 install 에서 `Source path does not exist` 로 실패한다.

### 예약된 마켓플레이스 이름 (사용 금지)

- 공식: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `anthropic-agent-skills`, `life-sciences`, `knowledge-work-plugins`, `claude-for-legal`, `claude-for-financial-services`, `financial-services-plugins`, `first-party-plugins`, `claude-tag-plugins`
- 커뮤니티: `claude-community`, `claude-plugins-community`, `healthcare`
- 디렉토리: `anthropic-plugin-directory`, `claude-plugin-directory`
- 공식 사칭(`official-claude-plugins`, `claude-plugins-v2` 등), 비ASCII 문자 포함 이름, 위 이름의 다른 표기(`claude.code.plugins`)
- 내부 예약: `inline`, `builtin`, `skills-dir`, `synced`, `claude-plugin-test`, `npm`, `pip`, `uv`, `cargo`, `github`, `gh`
- `claudeai-` 로 시작하는 이름, JS 객체 멤버 이름(`constructor`, `toString` 등)
- 등록된 GitHub 마켓플레이스의 다운로드 폴더 이름 `<owner>-<repo>`

## plugin.json

- 위치: `<플러그인 루트>/.claude-plugin/plugin.json`. 매니페스트 자체는 선택이지만 메타데이터를 위해 둔다.
- 필수 필드는 `name` 하나. kebab-case, 공백·`@`·`:`·경로 구분자 금지. 모든 컴포넌트가 이 이름으로 네임스페이스된다(`autopilot:autopilot`).
- 이름 금지: `claude-`·`anthropic-`·`anthropics-`·`cc-plugin-` 로 시작, `claude`·`anthropic`·`claude-code` 등 그 자체, `official` 과 `claude/anthropic` 조합. 단어로 `claude` 포함 시 경고.
- 권장: `version`, `description`, `author`(`name` 필수) — 없으면 validate 경고.
- 그 외: `homepage`(URL이어야 함, 아니면 로드 실패), `repository`(검증 안 함), `license`(SPDX), `keywords`.
- 알 수 없는 최상위 키는 제거되고 경고만 난다.
- `version` 을 설정하면 사용자는 그 값이 바뀔 때까지 해당 버전에 고정된다. marketplace 항목에도 `version` 이 있으면 plugin.json 이 우선하고 경고가 난다 → **이 레포는 marketplace 항목에 version을 넣지 않는다.**

## 디렉토리 규칙

- `.claude-plugin/` 안에는 `plugin.json` 만 둔다. `skills/`, `commands/`, `agents/`, `hooks/` 는 플러그인 루트에.
- 스킬: `skills/<name>/SKILL.md`. 훅: `hooks/hooks.json`. MCP: `.mcp.json`. 실행 파일: `bin/`(claude.ai·Cowork는 `bin/` 있는 플러그인을 설치하지 않음 → 쓰지 않는다).
- 매니페스트의 컴포넌트 경로는 플러그인 루트 기준 상대경로, `./` 로 시작, 루트 밖으로 나가면 안 되고 실제로 존재해야 한다.
- 플러그인 루트의 `CLAUDE.md` 는 컨텍스트로 로드되지 않고 validate 가 경고한다 (레포 루트의 CLAUDE.md 는 무관).
- 스크립트 경로는 `${CLAUDE_PLUGIN_ROOT}` 로 참조한다. 이 경로는 업데이트 때 바뀌므로 상태를 쓰지 않는다.

## 검증

```bash
claude plugin validate .                         # 마켓플레이스 루트 (각 상대경로 플러그인의 plugin.json도 검사)
claude plugin validate ./plugins/autopilot       # 플러그인 단독
claude plugin validate . --strict                # 경고도 실패로
```

결과: `Validation passed` / `passed with warnings` / `failed`. `scripts/validate.sh` 가 첫 번째 명령을 실행한다.

로컬 설치 테스트: `claude plugin marketplace add ./` → `claude plugin install autopilot@autopilot-marketplace` → `claude plugin list`.

## 흔한 실수

1. **`.claude-plugin/` 안에 skills 등을 넣음** — `plugin.json` 만 들어간다.
2. **`source` 경로 기준 착각** — `.claude-plugin/` 이 아니라 그 부모(마켓플레이스 루트) 기준. `../` 로 빠져나가려 하지 말 것. `./` 로 시작해야 한다.
3. **이름 불일치** — marketplace 항목의 `name`(설치 id)과 plugin.json 의 `name`(스킬 접두어)이 다르면 `Plugin "<name>" not found in marketplace` 류의 혼란이 생긴다. 둘 다 `autopilot` 으로 유지.
4. **버전 이중 선언** — marketplace 항목과 plugin.json 양쪽에 version을 두면 경고. plugin.json 하나에만.
5. **예약 이름 사용** — 마켓플레이스·플러그인 이름에 `claude-` 접두어 등을 쓰면 오류. (GitHub 레포 이름은 무관)
