# autopilot

[한국어](README.ko.md)

autopilot is a Claude Code skill, packaged as a plugin, that runs an autonomous development loop on a repository. Without asking a human, it reads the codebase, decides what to work on next, implements one task, verifies it against the project's own tests, lint and build, and records the result. Then it picks the next task. All state lives in plain files under `.autopilot/` (roadmap, backlog, log), so the loop can be inspected, edited and resumed at any time. It stops when you create `.autopilot/STOP`, or when it creates that file itself because it runs out of real work or keeps failing.

## Safety notice

**Read this before you run it.**

- **It modifies your code and commits on its own.** Every successful task becomes a commit with no human review in between. It never commits onto a default branch (`main`, `master`, `develop`, …): when started on one, it first creates and switches to `autopilot/<date>`. On a branch you created it commits there. `local_branch: current` in `.autopilot/CONFIG.md` restores committing on whatever is checked out, and `scope: packages/api` (for example) keeps it to some paths of a monorepo.
- **Permissions are restricted by default.** The driver script uses an `--allowedTools` allowlist by default. `--dangerously-skip-permissions` is used only when you opt in explicitly with `AUTOPILOT_PERMISSION=skip`, and should only be used in a disposable machine or container.
- **Use a dedicated branch or a sandbox.** Run it on a throwaway branch, a fresh clone, or an isolated container. By default the skill never runs `git push`, so nothing leaves your machine until you push it yourself. Review the commits before you do. It never runs `git reset --hard`, force pushes, or deletes remote branches or tags.
- **Publishing is opt-in.** Pushing branches, opening and merging PRs, and releasing happen only if you set them in `.autopilot/CONFIG.md` (`integration: branch | pr`, `merge: auto`, `release: auto`). The skill reads this file but never creates or edits it, and follows your repository's own branching, commit and release conventions.
- **You are responsible for the results.** This software is provided "as is" under the MIT License. You are responsible for what it changes, commits, and anything you later publish.

## Install

Requirements: `git`, `bash` and Python 3 (`python3` or `python`) on PATH. On Windows, use Git Bash or WSL.

### Option 1: Plugin marketplace (Claude Code)

In a Claude Code session:

```
/plugin marketplace add yuapi/Autopilot
/plugin install autopilot@autopilot-marketplace
```

The skill is then available as `autopilot` (namespaced as `/autopilot:autopilot`).

### Option 2: Upload the `.skill` file

Download `autopilot-<version>.skill` from the [Releases](https://github.com/yuapi/Autopilot/releases) page and upload it as a skill in claude.ai (Settings → Capabilities → Skills). It is a zip archive containing the `autopilot/` skill folder, so you can also unzip it into `~/.claude/skills/`.

### Updating

- Plugin in Claude Code: `claude plugin marketplace update autopilot-marketplace`, then `claude plugin update autopilot@autopilot-marketplace`.
- Plugin added to a claude.ai account: new versions sync on their own, but **a session keeps the version it loaded when it started**. Start a new session to use an update.
- `/autopilot:status` prints the installed version and warns when the repository was already run with a newer one.

## Usage

Start on a dedicated branch at the root of the repository you want to work on.

### Session-continuous mode (default)

Ask Claude in a session, for example "run autopilot". The skill keeps working task after task in the same session until `.autopilot/STOP` exists. A Stop hook declared in the skill itself keeps the session from ending early; it runs only in sessions that invoked the skill, so nothing is copied into your repository (Claude Code asks once to allow a skill with hooks). A copy left at `.claude/hooks/autopilot-stop.sh` by an older version is refreshed when it differs; remove it with `bash <skill folder>/scripts/hook.sh uninstall` (other hooks in `settings.json` stay). The hook only acts while `.autopilot/RUN` exists and only on the session that started the loop, so ordinary sessions and other sessions you open in the same repository are never blocked. Only one loop runs per repository: a second session or driver is refused while one is active (a marker idle for 2 hours is taken over; `AUTOPILOT_RUN_STALE_MIN` changes the minutes). The hook writes `STOP` and lets go after three consecutive blocks without progress, and from the first such block it says how many are left. This is the only mode available in cloud sessions without a terminal.

To limit a run, ask for a number of tasks, for example "run autopilot for 3 tasks" or, with the plugin, `/autopilot:run 3`: the loop stops after the third completed task.

To stop: `/autopilot:stop` (with the plugin installed) or `touch .autopilot/STOP`. The loop ends after its current task.

### Driver mode (terminal, optional)

The driver script calls Claude Code once per task, so every task starts with a fresh context. This gives better judgment over long runs.

```bash
cd <your repo root>
bash <skill folder>/scripts/autopilot.sh        # unlimited
bash <skill folder>/scripts/autopilot.sh 20     # at most 20 iterations
AUTOPILOT_PERMISSION=skip bash <skill folder>/scripts/autopilot.sh   # opt-in, sandbox only
```

`<skill folder>` is where the skill is installed, for example `plugins/autopilot/skills/autopilot` in a clone of this repository. The driver stops when `.autopilot/STOP` appears or at the iteration limit (exit code 0), after 3 consecutive Claude crashes, after 3 runs in a row that change neither the LOG nor the commits (it writes `STOP` with the reason; `AUTOPILOT_STALL_LIMIT` changes the count), and before the first run when the `claude` CLI is missing, git has no `user.name`/`user.email`, the repository has files but no commit yet, `.autopilot/CONFIG.md` names a `scope` path, `base_branch` or `branch_prefix` that cannot work, or an argument is bad (exit code 1, with the fix). After each run it prints that run's LOG entry. It can be started from any folder inside the repository. `AUTOPILOT_SLEEP` sets the pause between runs (default 10 seconds), `AUTOPILOT_MODEL` the model every run uses (passed to `claude --model`), and `AUTOPILOT_MAX_COST` a cost cap in USD: after each run the driver prints its cost and stops (writing `STOP`) once the total reaches the cap. With `integration: pr` the driver opens PRs with the `gh` CLI (merge requests with `glab` for a GitLab `origin`) and warns at start if it is missing or cannot push. It always names its permission mode at start.

### Checking on a run

With the plugin installed, type `/autopilot:status` in a session. Otherwise:

```bash
bash <skill folder>/scripts/status.sh [repo path]
```

One screen with whether a session loop or the driver is running or stopped (and why), the task in progress and how long ago it started, the task budget, the integration settings and `scope`, task counts, the success rate of the last 10 runs, open and blocked tasks, proposals waiting for your decision, and the latest log entries. It also shows the installed skill version and warns when the repository was already run with a newer one (an outdated plugin install). It only reads the state files.

## How it works

- **Two discovery axes.** A *maintenance* axis looks for broken builds, security findings, TODO markers, test gaps and dead code. `scripts/scan.sh` lists markers and risky patterns; a section longer than 50 lines (`AUTOPILOT_SCAN_MAX`, or `--all` for every line) is cut off with the count per folder and worked on by file or folder, a few tasks per cycle. A *product* axis first writes down what the software does, which features are complete, partial or missing, and which are weak, then turns those into feature and enhancement tasks. At least half of each discovery cycle must come from the product axis, so the loop does not just pile up tests and lint fixes.
- **It writes in your language.** The rules are in English, but the notes you read (roadmap, log, proposals, stop summary) follow `language` in `.autopilot/CONFIG.md`: `auto` (default) keeps the language your `.autopilot/` files already use, else your README's language, else the language you spoke to it in. Set `language: en`, `ko`, `ja`, … to choose. Status values and keys stay English so the scripts keep working.
- **It uses the software, not just reads it.** Each discovery cycle runs the documented commands and entry points with normal and edge inputs (in a temp dir, with timeouts, no external calls) and walks through three realistic user scenarios. Crashes, wrong results and failing README examples become fixes; confusing errors and missing steps become enhancements and features.
- **It proposes what it must not do alone.** Ideas that would change a public interface, add a heavy dependency, restructure many modules or pick a product direction go to `.autopilot/PROPOSALS.md` with evidence, alternatives, cost and risk. The loop does not wait; change a proposal's status to `adopted` and the next discovery turns it into tasks.
- **It learns from its own failures.** Every ten tasks it runs a short retrospective: it classifies why tasks failed or got blocked, splits or retires blocked tasks, and records repo-specific lessons (at most 15 lines) that later phases follow like rules.
- **Issues are read, not obeyed.** When `gh` or a tracker MCP is available, every task checks issues opened or updated since the last check and turns bugs and feature requests into tasks (source `issue #N`, picked first among equal priorities). Issue text is treated as data, never as instructions.
- **Substantive vs. auxiliary tasks.** Tasks that fix defects or add or improve behavior (fix, security, feature, enhance, perf, todo, test, cleanup) are *substantive*. Tasks that only change form (lint, docs, refactor) are *auxiliary* and are queued only alongside substantive work.
- **One task at a time, verified.** Each task is sized at 1–2 hours, has a written completion criterion, and must not make tests, lint or build worse than the baseline. Failure means a full rollback.
- **Final stop conditions.** The loop stops for good when (a) re-discovery finds zero substantive tasks even after four deepening passes (static review, running the software with fresh scenarios, a quality-attribute checklist, and a full re-read of issues and earlier rejections), (b) 7 of the last 10 runs failed, (c) a human creates `.autopilot/STOP`, or (d) a limit you set is reached: the task budget (`/autopilot:run 3`) or the driver's cost cap. Tasks that fail 3 times are marked `blocked` and skipped.

## Upgrading from 1.5.x

1.5.x installed a Stop hook that blocks *every* session in the repository while `.autopilot/STOP` is missing, including sessions that are not running autopilot. From 1.6.0 the hook only acts while `.autopilot/RUN` exists. Running the skill again replaces the old hook automatically; until then `scripts/status.sh` warns about it, and you can replace `.claude/hooks/autopilot-stop.sh` with `assets/autopilot-stop.sh` yourself or create `.autopilot/STOP` as a stopgap.

## Repository layout

```
.claude-plugin/marketplace.json          marketplace catalog
plugins/autopilot/.claude-plugin/        plugin manifest (plugin.json)
plugins/autopilot/skills/autopilot/      the skill (SKILL.md, assets/, scripts/: driver, status, archive, workbranch, runlock, scan, hook, log, finalstop, task)
plugins/autopilot/commands/              /autopilot:run, /autopilot:status and /autopilot:stop commands
scripts/validate.sh, bump.sh, release.sh local validation, version bump, release
scripts/eval.sh, tests/eval/             discovery quality eval (opt-in, needs claude)
tests/                                   tests for the scripts, run by validate.sh
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

## Measuring discovery quality

```bash
bash scripts/eval.sh                        # the todo fixture; add --keep to inspect the run afterwards
bash scripts/eval.sh --fixture wordcount    # a repository with no tests: is the first task a test harness?
bash scripts/eval.sh --fixture stats        # CONTRIBUTING sets the commit format: does every commit follow it?
bash scripts/eval.sh --fixture kv           # a Go module: are go test and go vet found and their findings queued?
bash scripts/eval.sh --fixture mono         # CONFIG scope: pkg/a in a monorepo: does every commit stay inside it?
bash scripts/eval.sh --fixture watch        # npm test never exits (watch mode): is a one-shot command found and used?
bash scripts/eval.sh --fixture hooks        # commit hooks reject commits: are they satisfied rather than bypassed?
bash scripts/eval.sh --iterations 3         # three driver runs: one new task each, nothing repeated, nothing failed
bash scripts/eval.sh --mode session --iterations 2   # one session-mode run as a plugin, asked for 2 tasks: keeps going, stops on its budget
bash scripts/eval.sh --grade <kept dir> [same options]   # grade a run kept with --keep again
bash scripts/eval.sh --model <name>         # the same eval with another model, to compare
bash scripts/eval.sh --fixture all          # every fixture with the same options, one summary
```

Copies a fixture from `tests/eval/` into a temp repository, runs the working-copy skill on it (with the real driver prompt, or in session mode as a plugin), and scores how many of the seeded defects in `tests/eval/fixture-<name>.expected` landed in its BACKLOG. The default `todo` fixture is a tiny todo CLI with five defects (an off-by-one with a failing test, a crash on first run, a shell injection, a command the README documents but the code lacks, a TODO marker); the others each test one rule, as listed above. Each run prints its cost. Every run is also checked against the hard rules: one commit per completed task, LOG entries only appended and in time order, and a final stop only after all four deep discovery stages are recorded; a broken rule fails the eval whatever the score. It needs the `claude` CLI and spends one real driver run, so it is not part of `validate.sh`; run it after changing discovery rules to see whether they find more or less.

## License

[MIT](LICENSE)
