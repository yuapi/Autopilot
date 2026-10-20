# Plugin and marketplace structure

A summary of the official docs (checked 2026-10). The rules may have changed, so re-read the originals before editing the manifests.

Sources:
- Plugins overview: https://code.claude.com/docs/en/plugins
- Plugin manifest reference: https://code.claude.com/docs/en/plugins-reference
- Creating marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Marketplace reference: https://code.claude.com/docs/en/plugins/marketplace-reference

## This repository's layout

```
.claude-plugin/marketplace.json                 ← marketplace root = repository root
plugins/autopilot/                              ← plugin root
plugins/autopilot/.claude-plugin/plugin.json    ← manifest (nothing else in this folder)
plugins/autopilot/skills/autopilot/SKILL.md     ← skill (skills/<name>/SKILL.md)
plugins/autopilot/commands/status.md, stop.md   ← /autopilot:status, /autopilot:stop
```

Commands run the skill's scripts through `${CLAUDE_PLUGIN_ROOT}`, which Claude Code substitutes in command files too (checked with `claude -p "/autopilot:status" --plugin-dir plugins/autopilot`). The `.skill` package contains only the skill folder, so the commands exist only for plugin installs.

## marketplace.json

- Location: `<marketplace root>/.claude-plugin/marketplace.json`.
- Required: `name`, `owner` (`owner.name` required, `email` and `url` optional), the `plugins` array.
- `description` is optional, but `claude plugin validate` warns without it.
- `name`: letters, digits, `.`, `_`, `-`; starts with a letter or digit; no `..`. Users type `<plugin>@<marketplace>`.
- Required per plugin entry: `name`, `source`. Optional: `description`, `version`, `category`, `tags`, `strict`, ….
- A relative `source` is relative to the **marketplace root** (not `.claude-plugin/`) and must start with `./`. `..` is a validate error.
- A path that does not exist passes validate and fails at install with `Source path does not exist`.

### Reserved marketplace names (do not use)

- Official: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `anthropic-agent-skills`, `life-sciences`, `knowledge-work-plugins`, `claude-for-legal`, `claude-for-financial-services`, `financial-services-plugins`, `first-party-plugins`, `claude-tag-plugins`
- Community: `claude-community`, `claude-plugins-community`, `healthcare`
- Directories: `anthropic-plugin-directory`, `claude-plugin-directory`
- Names impersonating official ones (`official-claude-plugins`, `claude-plugins-v2`, …), names with non-ASCII characters, other spellings of the names above (`claude.code.plugins`)
- Internal: `inline`, `builtin`, `skills-dir`, `synced`, `claude-plugin-test`, `npm`, `pip`, `uv`, `cargo`, `github`, `gh`
- Names starting with `claudeai-`, JavaScript object member names (`constructor`, `toString`, …)
- The download folder name `<owner>-<repo>` of a registered GitHub marketplace

## plugin.json

- Location: `<plugin root>/.claude-plugin/plugin.json`. The manifest itself is optional, but it is kept for the metadata.
- The only required field is `name`: kebab-case, no spaces, `@`, `:` or path separators. Every component is namespaced with it (`autopilot:autopilot`).
- Forbidden names: starting with `claude-`, `anthropic-`, `anthropics-`, `cc-plugin-`; exactly `claude`, `anthropic`, `claude-code`, …; combinations of `official` with `claude`/`anthropic`. Containing the word `claude` is a warning.
- Recommended: `version`, `description`, `author` (`name` required) — validate warns without them.
- Others: `homepage` (must be a URL or loading fails), `repository` (not validated), `license` (SPDX), `keywords`.
- Unknown top-level keys are dropped with a warning.
- When `version` is set, users stay on that version until the value changes. If the marketplace entry also has `version`, plugin.json wins with a warning → **this repository never puts a version in the marketplace entry.**

## Directory rules

- `.claude-plugin/` contains only `plugin.json`. `skills/`, `commands/`, `agents/` and `hooks/` go in the plugin root.
- Skills: `skills/<name>/SKILL.md`. Hooks: `hooks/hooks.json`. MCP: `.mcp.json`. Executables: `bin/` (claude.ai and Cowork do not install plugins that have `bin/` → not used).
- Component paths in the manifest are relative to the plugin root, start with `./`, must not leave the root and must exist.
- A `CLAUDE.md` in the plugin root is not loaded as context and validate warns about it (the repository root's CLAUDE.md is unrelated).
- Refer to script paths with `${CLAUDE_PLUGIN_ROOT}`. The path changes on updates, so never store state there.

## Validation

```bash
claude plugin validate .                         # marketplace root (also checks each relative plugin's plugin.json)
claude plugin validate ./plugins/autopilot       # the plugin alone
claude plugin validate . --strict                # warnings fail too
```

Results: `Validation passed` / `passed with warnings` / `failed`. `scripts/validate.sh` runs the first command.

Local install test: `claude plugin marketplace add ./` → `claude plugin install autopilot@autopilot-marketplace` → `claude plugin list`.

## Common mistakes

1. **Putting skills etc. inside `.claude-plugin/`** — only `plugin.json` goes there.
2. **Getting the `source` base wrong** — it is the parent of `.claude-plugin/` (the marketplace root). Do not try to escape with `../`. Start with `./`.
3. **Mismatched names** — if the marketplace entry `name` (install id) differs from the plugin.json `name` (skill prefix), you get confusion like `Plugin "<name>" not found in marketplace`. Keep both `autopilot`.
4. **Declaring the version twice** — a version in both the marketplace entry and plugin.json gives a warning. Only in plugin.json.
5. **Using reserved names** — a `claude-` prefix etc. in marketplace or plugin names is an error. (The GitHub repository name does not matter.)
