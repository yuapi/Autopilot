# autopilot

[한국어](README.ko.md)

autopilot is a Claude Code skill, packaged as a plugin, that runs an autonomous development loop on a repository. Without asking a human, it reads the codebase, decides what to work on next, implements one task, verifies it against the project's own tests, lint and build, and records the result. Then it picks the next task. All state lives in plain files under `.autopilot/` (roadmap, backlog, log), so the loop can be inspected, edited and resumed at any time. It stops when you create `.autopilot/STOP`, or when it creates that file itself because it runs out of real work or keeps failing.

## Safety notice

**Read this before you run it.**

- **It modifies your code and commits on its own.** Every successful task becomes a commit in the current branch, with no human review in between.
- **Permissions are restricted by default.** The driver script uses an `--allowedTools` allowlist by default. `--dangerously-skip-permissions` is used only when you opt in explicitly with `AUTOPILOT_PERMISSION=skip`, and should only be used in a disposable machine or container.
- **Use a dedicated branch or a sandbox.** Run it on a throwaway branch, a fresh clone, or an isolated container. The skill never runs `git push`, `git reset --hard` or force operations, so nothing leaves your machine until you push it yourself. Review the commits before you do.
- **You are responsible for the results.** This software is provided "as is" under the MIT License. You are responsible for what it changes, commits, and anything you later publish.

## Install

### Option 1: Plugin marketplace (Claude Code)

In a Claude Code session:

```
/plugin marketplace add yuapi/Autopilot
/plugin install autopilot@autopilot-marketplace
```

The skill is then available as `autopilot` (namespaced as `/autopilot:autopilot`).

### Option 2: Upload the `.skill` file

Download `autopilot-<version>.skill` from the [Releases](https://github.com/yuapi/Autopilot/releases) page and upload it as a skill in claude.ai (Settings → Capabilities → Skills). It is a zip archive containing the `autopilot/` skill folder, so you can also unzip it into `~/.claude/skills/`.

## Usage

Start on a dedicated branch at the root of the repository you want to work on.

### Session-continuous mode (default)

Ask Claude in a session, for example "run autopilot". The skill keeps working task after task in the same session until `.autopilot/STOP` exists. On first entry it installs a Stop hook (`.claude/hooks/autopilot-stop.sh`) so the session does not end early. The hook only acts while `.autopilot/RUN` exists, so ordinary sessions are never blocked, and it writes `STOP` and lets go after three consecutive blocks without progress. This is the only mode available in cloud sessions without a terminal.

To stop: `touch .autopilot/STOP`.

### Driver mode (terminal, optional)

The driver script calls Claude Code once per task, so every task starts with a fresh context. This gives better judgment over long runs.

```bash
cd <your repo root>
bash <skill folder>/scripts/autopilot.sh        # unlimited
bash <skill folder>/scripts/autopilot.sh 20     # at most 20 iterations
AUTOPILOT_PERMISSION=skip bash <skill folder>/scripts/autopilot.sh   # opt-in, sandbox only
```

`<skill folder>` is where the skill is installed, for example `plugins/autopilot/skills/autopilot` in a clone of this repository. The driver stops when `.autopilot/STOP` appears, after 3 consecutive Claude crashes, or at the iteration limit.

## How it works

- **Two discovery axes.** A *maintenance* axis looks for broken builds, security findings, TODO markers, test gaps and dead code. A *product* axis first writes down what the software does, which features are complete, partial or missing, and which are weak, then turns those into feature and enhancement tasks. At least half of each discovery cycle must come from the product axis, so the loop does not just pile up tests and lint fixes.
- **Substantive vs. auxiliary tasks.** Tasks that fix defects or add or improve behavior (fix, security, feature, enhance, perf, todo, test, cleanup) are *substantive*. Tasks that only change form (lint, docs, refactor) are *auxiliary* and are queued only alongside substantive work.
- **One task at a time, verified.** Each task is sized at 1–2 hours, has a written completion criterion, and must not make tests, lint or build worse than the baseline. Failure means a full rollback.
- **Final stop conditions.** The loop stops for good when (a) re-discovery, after a real product review, finds zero substantive tasks, (b) 7 of the last 10 runs failed, or (c) a human creates `.autopilot/STOP`. Tasks that fail 3 times are marked `blocked` and skipped.

## Repository layout

```
.claude-plugin/marketplace.json          marketplace catalog
plugins/autopilot/.claude-plugin/        plugin manifest (plugin.json)
plugins/autopilot/skills/autopilot/      the skill (SKILL.md, assets/, scripts/autopilot.sh)
scripts/validate.sh, bump.sh, release.sh local validation, version bump, release
docs/                                    maintainer documentation
CHANGELOG.md                             version history
```

## Development

There is no CI; validation is local. The short version:

```bash
git checkout -b feature/<topic> develop
# change things, add a line under "## Unreleased" in CHANGELOG.md
bash scripts/validate.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/](docs/) for branching, versioning and release details.

## License

[MIT](LICENSE)
