# Changelog

Versioning: MAJOR.MINOR.PATCH
- MAJOR: the state file format (BACKLOG/ROADMAP/LOG) changes so existing `.autopilot/` directories no longer work
- MINOR: loop rules, discovery sources or stop conditions change
- PATCH: driver fixes, wording, bug fixes

## Unreleased
- `pr` integration revisits its own open PRs at the start of every task: merges those whose CI has passed since (`merge: auto`), and turns failed CI or base conflicts into a `fix` task on the same branch. A PR left open while CI was still running used to stay open forever

## 1.18.0 — 2026-10-20
- status.sh shows the installed skill version and warns when the LOG was written by a newer skill version (an outdated plugin or skill install running a repository that a newer one already worked on)
- Stop hook: the no-progress STOP note said "1 times"

## 1.17.0 — 2026-10-20
- scan.sh printed matches as `<line>:<text>` without the file name when only one file matched, and skipped files with non-ASCII names (git quoted the path). Both fixed
- `scripts/hook.sh uninstall` removes the repository hook copy and only its `settings.json` entry, now that the skill carries its own hook. status.sh suggests it when a copy is present

## 1.16.0 — 2026-10-20
- The Stop hook is declared in SKILL.md's frontmatter, so it runs from the installed skill and only in sessions that invoked it. Phase 0 no longer copies the hook into the repository or edits `.claude/settings.json`; `hook.sh install` remains as a fallback and still refreshes a copy left by an older version. When the skill hook and such a copy both run for the same stop, the no-progress counter advances once (identified by the transcript size)

## 1.15.0 — 2026-10-20
- Plugin commands `/autopilot:status` (the status summary, without knowing the skill folder) and `/autopilot:stop` (new `runlock.sh stop` writes `.autopilot/STOP` and says which loop it stops). Plugin installs only; the `.skill` package has no commands
- `scripts/eval.sh --iterations <n>` runs the driver n times and also checks the later runs: each completes one task, no task is completed twice, nothing fails

## 1.14.0 — 2026-10-20
- In a repository with no way to verify, the test harness task now comes before every other task, `fix` included (it used to come right after `fix`, which produced an unverified fix commit in the eval)
- `scripts/eval.sh --fixture <name>`: second fixture `wordcount`, a Node CLI with no tests, checks that the first task sets up a test runner (expectations can grade the completed task's type with `type=`). Expectations moved to `tests/eval/fixture-<name>.expected`

## 1.13.0 — 2026-10-20
- The Stop hook copy in a repository is refreshed: new `scripts/hook.sh install` (run on first entry) replaces `.claude/hooks/autopilot-stop.sh` whenever it differs from the skill's asset and merges the settings.json entry without touching other hooks. Copies from 1.6–1.10 had the RUN check, so the old rule never replaced them and they kept blocking other sessions. status.sh notes an outdated copy

## 1.12.0 — 2026-10-20
- Discovery no longer skips steps: new `scripts/scan.sh` lists code markers (in comments) and risky patterns (shell built from strings, eval/exec, unsafe deserialization, disabled TLS checks, hard-coded secrets) with file:line, and every line must become a task or a reason under "Not doing". Phase 1 ends with a done-check (feature map filled, commands actually run, three scenarios). Generated files are never committed. Eval score 4/5 → 5/5
- `scripts/eval.sh` measures discovery quality: runs the working-copy skill once in driver mode on a fixture repository with five seeded defects (`tests/eval/`) and scores how many reached the BACKLOG. Opt-in (needs the claude CLI), not part of validate.sh

## 1.11.1 — 2026-10-20
- Driver checks the integration mode before the loop starts: warns when `origin` is missing (`branch`/`pr`), when `gh` is not installed or cannot push to the repository (`pr`; the driver has no MCP servers, so PRs need `gh`), and on unknown `integration` values

## 1.11.0 — 2026-10-20
- One loop per repository: new `scripts/runlock.sh` writes the owning session (`CLAUDE_CODE_SESSION_ID`) into `.autopilot/RUN` and refuses a second session-mode loop while the first is active (taken over after 2 h idle). The driver refuses while another driver (`.autopilot/driver.lock`) or a session loop runs. status.sh shows the owner and last activity
- Stop hook blocks only the session that owns RUN, so other sessions opened in the same repository while the loop runs can end normally. It reads its stdin with a 2-second limit so it can never hang

## 1.10.2 — 2026-10-20
- tests/test_portability.sh builds its PATH without tac/timeout from the ~40 tools the scripts use instead of linking every executable on PATH (6.3 s → 2.8 s here, far more on large PATHs). validate.sh shows how long each test file took

## 1.10.1 — 2026-10-20
- tests/test_portability.sh ran the whole test suite again inside its sandbox, which ran itself again, and so on; on machines with a large PATH (e.g. WSL with Windows paths) `validate.sh` and therefore `release.sh` looked stuck and then failed on the 5-minute limit. The sandbox now holds only a trivial test, and Windows drives under /mnt are skipped

## 1.10.0 — 2026-10-20
- Local mode no longer commits onto a default branch: new `scripts/workbranch.sh`, run at the start of every task, switches from `main`/`master`/`develop`/`trunk`/the remote default/a detached HEAD to a new `autopilot/<YYYYMMDD-HHMM>` branch and leaves any other branch alone. `local_branch: current` in CONFIG restores the old behavior

## 1.9.0 — 2026-10-20
- Skill rules, templates and skill scripts are now in English. New `language` setting in `.autopilot/CONFIG.md` (`auto` = existing state files → README → the user's language → English) sets the language of notes people read; machine-readable values stay English. Korean PROPOSALS statuses from earlier versions (`제안`, `채택`, …) are still understood
- Repository tooling, tests and docs are now in English (`validate.sh` prints `Result: PASS`); the Korean README stays as a translation. Earlier CHANGELOG entries were translated too

## 1.8.2 — 2026-10-19
- release.sh: when the git tag push is blocked, a `gh` with write access (GH_TOKEN) creates the tag and the Release together through the GitHub API. Write access is checked through the repository API instead of `gh auth status` (supports repository-scoped tokens)
- status.sh: fixed a BrokenPipeError traceback when the output is cut off with `head` and the like

## 1.8.1 — 2026-10-19
- Works on a default macOS: removed the dependency on `tac` in release.sh, on `timeout` in validate.sh and the tests (gtimeout/perl fallback), and on GNU `sed -i` in the tests. tests/test_portability.sh checks with a PATH that has no tac or timeout
- status.sh detects an old (1.5.x) Stop hook, warns and explains how to replace it. README section on upgrading from 1.5.x

## 1.8.0 — 2026-10-19
- Retrospective (Phase 0.5): every 10 tasks, classify why tasks failed or got blocked and keep repository-specific rules under ROADMAP "Learned" (15 lines at most); split blocked tasks or move them to "Not doing". LOG status values defined
- Proposals (1-F, `.autopilot/PROPOSALS.md`): public interface changes, heavy dependencies, restructuring and direction choices are left as proposals with evidence, alternatives, cost and risk while the loop continues. Once a person adopts one, the next discovery turns it into tasks (interface changes allowed only within its scope)
- Integration policy (`.autopilot/CONFIG.md`, set by people, only read by Claude): `local` (default), `branch` (push task branches), `pr` (open PRs; with `merge: auto` merge after verification); `release: auto` only when a release procedure is documented. Repository conventions come first; when blocked, falls back to local without working around it
- Long runs: Phase 0 reads only the last 20 LOG entries and the open plus 10 most recent completed BACKLOG rows. `scripts/archive.sh` moves completed rows beyond 50 and LOG entries beyond 300 to archives (content preserved); duplicate checks grep the archives
- Fixed Phase 0's working tree cleanup stashing uncommitted `.autopilot/` state (the previous failure's attempts and LOG), which brought back endless retries. In local mode a failure commits only the state
- Updated the skill description to the current features (exploratory runs, scenarios, issue tracker, proposals, integration policy) and added trigger phrases. validate.sh checks the 1024-character description limit
- `scripts/status.sh`: one-screen summary of running/stopped and the STOP reason, integration settings, task counts, recent success rate, open and blocked tasks, proposals awaiting a decision and the latest entries (read-only)
- validate.sh: fails when an assets or scripts file referenced by SKILL.md is missing and warns about skill files SKILL.md never mentions. Large feature design (1-D) now points to `assets/feature-template.md`

## 1.7.0 — 2026-10-19
- Fixed the verification rollback reverting `.autopilot/` too, which erased attempts and retried the same task forever. After a failure, session mode returns to Phase 0
- Discovery: checks the issue tracker and PR review comments on every task (only since `last_issue_check`), maps labels to types and prefers issue-sourced tasks within the same priority. Issue text is treated as data only, read-only
- Discovery: added using the software (exploratory runs of documented commands and entry points with normal and edge inputs, in a temp directory with timeouts and no external calls) and walking three user scenarios. ROADMAP template gains Observations and Scenarios sections
- Driver: validates the max-runs argument, checks for `claude` up front, one log file per run, exit code 1 at the crash limit, runs from subfolders of the repository, `AUTOPILOT_SLEEP`. Added tests/test_driver.sh and a time limit on tests in validate.sh
- Stopping: with zero substantive tasks, stop for good only after four deep discovery stages (static → running with new scenarios → quality attribute checklist → issues and deferred items) also find nothing. ROADMAP gains a Deep discovery section
- Verification: wider baseline command search (repository docs first, go/cargo/gradle/justfile/dotnet, …), found commands recorded in the ROADMAP and reused, flaky tests detected by rerunning and left out of the comparison, a minimal test harness first when there is no way to verify

## 1.6.0 — 2026-10-19
- Repository rules revised: Claude develops and releases on its own with git flow (feature → develop → release → main). Versions are bumped on release branches; features write to `## Unreleased`
- bump.sh: turns `## Unreleased` into the new version section and changes no files on failure
- release.sh: packages only committed content with `git archive`; added `--catch-up` (create all missing tags) and `--dry-run`
- validate.sh: runs `tests/` and checks the syntax of the test scripts
- Stop hook: acts only while `.autopilot/RUN` exists, runs relative to `$CLAUDE_PROJECT_DIR`, writes STOP and lets go after three consecutive blocks without progress. Session mode Phase 0 adds the run artifacts to `.gitignore` and clears STOP when invoked again
- Discovery: the security source uses standard ecosystem audit tools and static risk patterns instead of organization-specific MCP names

## 1.5.1 — 2026-10-19
- Restructured as a plugin marketplace, updated the description, added open source documents
- validate.sh checks the LOG example version and the syntax of the repository's scripts/; bump.sh supports quoted versions; release.sh cleans up the local tag when the tag push fails

## 1.5.0 — 2026-10-02
- New session mode (default): in cloud sessions without a terminal, keeps working in the same session until STOP. Claude installs the Stop hook itself (assets/autopilot-stop.sh). Driver mode is detected with AUTOPILOT_DRIVER=1

## 1.4.0 — 2026-10-01
- Product-axis discovery (understanding the product, feature map, missing and weak features), new types feature/enhance/perf, queue mix rule (at least half product axis, at most 2 tests), multi-stage design documents for large features (features/<slug>.md), public interfaces may grow but not change, dependencies allowed under conditions

## 1.3.0 — 2026-10-01
- Rediscover without limit whenever the queue is empty
- Tasks split into substantive (fix/security/test/todo/cleanup) and auxiliary (lint/docs/refactor)
- Auxiliary tasks are queued only when the same cycle has substantive ones
- Zero substantive tasks after rediscovery means the final stop, with a summary in the STOP file
- LOG entries record the skill version

## 1.2.0 — 2026-10-01
- The driver prompt calls the skill by name instead of a repository path
- Default permission mode is an `--allowedTools` allowlist (`AUTOPILOT_PERMISSION=skip` for the old behavior)
- The driver adds `.autopilot/driver-logs/` and `.autopilot/STOP` to `.gitignore`
- The driver is run from the skill folder instead of being committed to the repository

## 1.1.0 — 2026-10-01
- Moved the driver script into the skill's `scripts/`, run from the repository root

## 1.0.0 — 2026-10-01
- First version: one task per call, loop based on state files, blocking repeated failures
