# Versioning

Format: `MAJOR.MINOR.PATCH` (the skill and the plugin share the number)

| Kind | When | Examples |
|---|---|---|
| **MAJOR** | The format of the `.autopilot/` state files (BACKLOG/ROADMAP/LOG/features) changes so existing state no longer works | Changing the BACKLOG columns, renaming status values without accepting the old ones |
| **MINOR** | SKILL.md behavior rules change: loop rules, discovery sources, selection priority, stop conditions | A new task type, a different queue mix, a new run mode |
| **PATCH** | Script fixes, wording, bug fixes, docs and manifest cleanups | A driver bug, a typo, the README |

When unsure, pick the larger one.

## The only way to change the version

Feature work does not bump the version; it adds a line under `## Unreleased` in `CHANGELOG.md`. The version is bumped on a `release/<ver>` branch.

```bash
bash scripts/bump.sh <major|minor|patch> ["<extra summary>"]
```

- If `## Unreleased` has items, its heading becomes `## x.y.z — YYYY-MM-DD` and a new empty `## Unreleased` goes above it. A summary, if given, is appended to the items.
- If `## Unreleased` is missing or empty, the summary is required and becomes the new entry.

What `bump.sh` touches:

| File | Where |
|---|---|
| `plugins/autopilot/skills/autopilot/SKILL.md` | frontmatter `metadata.version` |
| 〃 | body `**Version x.y.z**` |
| 〃 | `skill x.y.z` in the LOG format example |
| `plugins/autopilot/.claude-plugin/plugin.json` | `version` |
| `CHANGELOG.md` | `## Unreleased` → `## x.y.z — YYYY-MM-DD` |

It does not commit.

## Why these must always match

- **SKILL.md `metadata.version`** — the skill writes this number on every LOG entry. It is the only way to tell from a user's `.autopilot/LOG.md` which rules a run followed.
- **plugin.json `version`** — Claude Code decides whether to update the plugin from this value. If it does not change, users never receive the new skill; if it changes wrongly, the same content ships under different versions.
- **The top of the CHANGELOG** — the release notes (`release.sh` uses this section as the GitHub Release body) and the `.skill` file name follow this number.

If any of them differ, "the version in the LOG ≠ the installed version ≠ the release notes" and bugs can no longer be reproduced. `validate.sh` compares all five values (including the body marker and the LOG example) and fails if they differ.
