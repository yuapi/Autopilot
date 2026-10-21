# Changelog

Versioning: MAJOR.MINOR.PATCH
- MAJOR: the state file format (BACKLOG/ROADMAP/LOG) changes so existing `.autopilot/` directories no longer work
- MINOR: loop rules, discovery sources or stop conditions change
- PATCH: driver fixes, wording, bug fixes

## Unreleased

## 1.47.0 — 2026-10-21
- A CONFIG `branch_prefix` that git rejects as a branch name (a space, `~`, `..`) in `branch`/`pr` mode: `status.sh` warns, the driver stops before the first run with the fix, and SKILL.md Phase 0 writes STOP with it

## 1.46.0 — 2026-10-21
- A CONFIG `base_branch` that exists neither locally nor on origin (a typo) in `branch`/`pr` mode: `status.sh` warns, the driver stops before the first run with the fix, and SKILL.md Phase 0 writes STOP with it

## 1.45.0 — 2026-10-21
- A CONFIG `scope` path that does not exist no longer passes silently (discovery found nothing and every change was refused, heading for a false final stop): `status.sh` warns, the driver stops before the first run with the fix, and SKILL.md Phase 0 writes STOP with it

## 1.44.0 — 2026-10-21
- `scan.sh` prints at most 50 lines per section (`AUTOPILOT_SCAN_MAX`, `--all` for every line), then the count left and the hits per folder; SKILL.md 1-B groups such a section by file or folder, at most 10 tasks per cycle, instead of one task per line (400 TODOs used to mean 400 tasks and about 20k tokens of scan output)

## 1.43.0 — 2026-10-21
- A CONFIG value that is not one of the documented ones (a typo such as `integration: prr`) now counts as the safest one: `workbranch.sh` treats it as `local` and leaves a default branch instead of committing on it, and `status.sh` warns with the allowed values

## 1.42.0 — 2026-10-21
- `runlock.sh start` adds the run artifacts (STOP, RUN, .hook-state, driver-logs/, driver.lock, .task) to `.gitignore` itself, as the driver does; Phase 0 no longer edits it by hand, so a missed step cannot commit RUN

## 1.41.1 — 2026-10-21
- Seventh eval fixture `hooks`: commit-msg and pre-commit hooks installed by a new `fixture-<name>.setup` script; new `body=` expectations check every commit message, so a bypassed hook shows up

## 1.41.0 — 2026-10-21
- Repository commit hooks count as verification: files a hook rewrote are staged and committed again, a rejected commit is fixed or treated as a failure, and hooks are never bypassed (`--no-verify`, `core.hooksPath`)

## 1.40.0 — 2026-10-21
- status.sh explains a task left in progress while no loop runs: the last run ended in the middle of it, and the next run finishes or rolls it back

## 1.39.1 — 2026-10-21
- `release.sh --catch-up` builds the version → commit map once instead of rescanning every commit for every version: 44 missing versions took 49 s in a dry run, now 13 s with the same result

## 1.39.0 — 2026-10-21
- Every task ends by committing `.autopilot/` alone, in every mode (generalizes the rule for runs that stop). In `local` mode nothing said to commit the state: one driver eval run left `.autopilot/` untracked to the end. New eval rule check: the working tree is clean at the end

## 1.38.0 — 2026-10-21
- When the loop ends on a task budget or a person's STOP, Phase 5 commits the state written after the last task's commit (`done` row, LOG entry); it was left uncommitted, which Stop hooks that check for a clean tree reported

## 1.37.0 — 2026-10-21
- Discovery done-check: a proposal settles a `scan.sh` line only when 1-F requires one; a marker asking for something new is a `feature` task. A Haiku eval run had sent a TODO for a new option to a proposal
- README (EN/KO) brought up to date: driver stop conditions and `glab`, the status screen, the stop conditions including the task budget and cost cap, and the eval section

## 1.36.0 — 2026-10-20
- status.sh shows a running driver (`Run: running (driver, pid N, started M min ago)`) and a stale driver.lock, instead of "idle" while the driver works

## 1.35.1 — 2026-10-20
- finalstop.sh refused the final stop because of the `.gitignore` line `task.sh start` adds; it now treats `.gitignore` as state, like task.sh

## 1.35.0 — 2026-10-20
- A repository with files but no commit yet: Phase 0's stash failed and `task.sh start` refused forever. The driver now stops before the first run and Phase 0 writes STOP, both saying to commit the existing files first; neither commits them

## 1.34.0 — 2026-10-20
- Without a git `user.name`/`user.email` every commit fails and the loop only burned attempts. The driver now stops before the first run and Phase 0 writes STOP, both with the fix; neither sets an identity itself

## 1.33.0 — 2026-10-20
- Sixth eval fixture `watch`: `npm test` runs `node --test --watch` and never exits. New `roadmap=` expectations grade what the run recorded, here a one-shot test command
- Verification commands run non-interactively (`CI=1`, no stdin) with a time limit in Phase 0 and Phase 4. A watch-mode test command (`jest --watch`, plain `vitest`) or one waiting for input hung until the tool call was killed, on every task; a timeout is recorded and its one-shot form used instead

## 1.32.1 — 2026-10-20
- A repository path that does not exist gets `[script] no such directory: <path>` from every skill script, instead of a raw `cd` error (status, archive, log) or "not inside a git repository" (runlock, task, finalstop, hook, workbranch)

## 1.32.0 — 2026-10-20
- Every script answers `-h`/`--help` with its usage and exits 0. Before, status.sh exited 2 silently, archive.sh printed bash's own `cd` help, and others reported `--help` as a missing directory

## 1.31.1 — 2026-10-20
- The driver names its permission mode at start: a loud warning for `AUTOPILOT_PERMISSION=skip`, and a warning when the value is unknown (a typo used to fall back to the allowlist silently)
- eval.sh driver mode sends the real driver's prompt and allowlist (read from autopilot.sh) and loads the working copy as a plugin. Its own prompt hid the driver-only bug fixed in 1.31

## 1.31.0 — 2026-10-20
- task.sh done printed a shell error (`.autopilot/CONFIG.md: No such file or directory`) in repositories without a CONFIG
- log.sh and status.sh read the skill version when it is single-quoted, as the claude.ai account plugin sync writes it (`version: '1.27.0'`); LOG entries said `skill unknown` and status showed no version
- Driver mode no longer stops after one run: the model read the driver's "do exactly one task" as a person's task budget, claimed RUN with `--tasks 1`, and `task.sh done` wrote STOP. In driver mode `runlock.sh start` now writes no run marker (which would also let the Stop hook keep the call going), `task.sh` ignores budgets, and the driver prompt and SKILL.md say that one task per call is not a budget
- Driver cost cap: runs use `claude --output-format json`, the driver prints each run's cost and the total, and `AUTOPILOT_MAX_COST` (USD) writes STOP and exits once the total reaches it. Run logs keep the readable result text plus turns and cost
- tests/test_eval.sh 90 s → 24 s: the eval's polling interval is `AUTOPILOT_EVAL_POLL` (default 2 s) and the tests use a short one with shorter fake waits

## 1.30.0 — 2026-10-20
- In `branch` and `pr` modes the task is published (push, PR, merge) only after `task.sh done` accepts it; the rules published first, so a commit the check then refused could already be pushed or merged. Also aligned the "nothing left for a person" principle with `scope`, and refreshed stale lists in SKILL.md

## 1.29.2 — 2026-10-20
- A CONFIG saved with CRLF line endings no longer breaks `scope`: task.sh read `pkg/a\r` and refused every commit

## 1.29.1 — 2026-10-20
- scan.sh builds its file list once, in one process: 5000 files took 2 min 18 s (several processes per file for each of the six searches), now 0.25 s with the same output

## 1.29.0 — 2026-10-20
- Plugin command `/autopilot:run [N]` starts the loop, with N as the task budget (`/autopilot:run 3` stops after three tasks)
- eval.sh prints the cost and turns claude reported for the runs (`--output-format json`), so `--model` comparisons include cost

## 1.28.4 — 2026-10-20
- Skill scripts find Python as `python3` or `python` (Windows Git Bash often has only `python`) and say clearly when there is none; seven scripts called `python3` only

## 1.28.3 — 2026-10-20
- LOG times are UTC with a `Z` (`2026-10-01T14:30Z`). Local time made entries from machines in different time zones (a laptop and a cloud session) run backwards

## 1.28.2 — 2026-10-20
- `.gitattributes` keeps shell scripts LF: a clone or plugin install with `core.autocrlf=true` (common on Windows) checked them out with CRLF, and bash failed on every script

## 1.28.1 — 2026-10-20
- State files with CRLF line endings (a Windows checkout) keep them: task.sh and archive.sh rewrote the whole file as LF, and log.sh appended LF lines
- Fifth eval fixture `mono`: a monorepo whose CONFIG sets `scope: pkg/a`, with defects in both packages. New `nofile=` expectations fail when any commit changes a matching path

## 1.28.0 — 2026-10-20
- New CONFIG key `scope` (set by people) limits autopilot to some paths, e.g. one package of a monorepo: discovery reads and runs only there, tasks change only files there, `task.sh done` refuses a commit that changes anything outside, and status.sh shows it
- task.sh shows the expected BACKLOG layout and an example row when a row has the wrong number of columns, instead of only the count

## 1.27.1 — 2026-10-20
- `eval.sh --fixture all` runs every fixture with the same options and prints one summary of the scores (exit 1 if any fails); CLAUDE.md points to it for discovery rule changes
- `eval.sh --mode session` asks for `--iterations` tasks and checks that the run stopped itself on that task budget; the eval writes STOP only one task later, as a safety net

## 1.27.0 — 2026-10-20
- Task budget for session mode: `runlock.sh start --tasks N` (when the person asks for N tasks) records it in RUN, `task.sh done` writes STOP after the Nth completed task, and status.sh shows the progress. Until now only the driver could be limited

## 1.26.0 — 2026-10-20
- status.sh shows the task in progress (ID, type, title, attempt) and how long ago `task.sh start` claimed it
- Phase 0 no longer stashes uncommitted changes while a task is `in_progress`: they are that unfinished task's work, which is finished or rolled back instead. Stashing them hid the task from the Phase 2 check
- Fourth eval fixture `kv`, a Go module with a failing test, a `go vet` finding that `go test` does not run, a panic on malformed input, an ignored file error and a README flag that does not exist: checks baseline detection beyond Python and Node

## 1.25.0 — 2026-10-20
- Model choice: the driver passes `AUTOPILOT_MODEL` to `claude --model` for every run, and `scripts/eval.sh --model <name>` runs an eval with another model to compare

## 1.24.1 — 2026-10-20
- `task.sh done` refused when a bookkeeping commit since `start` (changing only `.autopilot/`, e.g. queueing a follow-up task) named another task ID; only commits that change code count now
- Third eval fixture `stats`: a repository whose CONTRIBUTING requires Conventional Commits and `make test`, with a failing test and a README/behavior mismatch. New `commit=` expectations grade every commit subject against the repository's convention. The rule check for combined commits ignores bookkeeping commits that change only `.autopilot/`

## 1.24.0 — 2026-10-20
- `task.sh drop <ID>` closes a task that turned out unnecessary (does not reproduce, already fixed) as `blocked` without a commit, and SKILL.md says to record the evidence under "Not doing". `done` requires a code commit and `fail` retries three times, so such a task had no honest way out

## 1.23.0 — 2026-10-20
- task.sh added its `.gitignore` entry even when it refused to start a task; a refusal now changes nothing
- `pr` integration on GitLab: merge requests and issues through `glab` when `origin` is on GitLab; the driver preflight checks `glab` (installed, logged in) instead of warning that `gh` is missing

## 1.22.0 — 2026-10-20
- New `scripts/task.sh start|done|fail <ID>` makes BACKLOG transitions mechanical: `start` refuses while another task is in progress or code changes are uncommitted; `done` refuses unless the task has its own commit that names no other task; `fail` returns it to open or blocks it from the third attempt. Phases 2, 4 and 5 use it. A session-mode eval run still combined two tasks in one commit after 1.20

## 1.21.0 — 2026-10-20
- Cloud sessions with `integration: local`: the loop's commits live only in the container and are lost when it is reclaimed. Phase 0 now tells the person once on first entry (and logs it), and status.sh warns; CONFIG is still never changed by Claude

## 1.20.2 — 2026-10-20
- The Stop hook's block message points to `finalstop.sh` when Claude believes nothing is left, so an early stop gets the list of missing conditions instead of only "keep going"

## 1.20.1 — 2026-10-20
- `release` is a LOG status (log.sh rejected the release entries the Release rule produces); SKILL.md says what a release entry records
- Eval grader: the todo fixture's off-by-one pattern accepts "mark item N (1-based)" wording a real run used

## 1.20.0 — 2026-10-20
- New `scripts/finalstop.sh` takes the STOP summary and refuses the final stop while ROADMAP "Deep discovery" lacks a stage, a task is open or in progress, or changes outside `.autopilot/` are uncommitted; otherwise writes STOP, removes RUN and logs it. Phase 2 starts by checking that the previous task was committed or rolled back (one task = one commit), and noticed defects are queued instead of being "left for a person". A session-mode eval run had broken all three
- eval.sh rule checks on every run: one commit per completed task, LOG entries only appended and in time order, a final stop only after all four deep discovery stages are recorded. A broken rule fails the eval whatever the score. `--grade <dir>` grades a kept run again without running anything
- New `scripts/log.sh <task ID|-> <status>` appends a LOG entry at the end of the file with the current time and the skill version (body on stdin), and SKILL.md requires it for every entry. The session-mode eval showed entries inserted above earlier ones with made-up times
- `scripts/eval.sh --mode session`: loads the working copy as a plugin and runs one session in session mode (Stop hook included). Once the LOG has `--iterations` task entries it writes STOP and checks that the session then ended on its own and removed RUN. Until now only driver mode was measured, though session mode is the default

## 1.19.1 — 2026-10-20
- Driver stops after 3 runs in a row that change neither LOG.md nor the commits, writing the reason to STOP (`AUTOPILOT_STALL_LIMIT`, same as the Stop hook). Runs that exit normally but get nowhere, e.g. on permission denials, used to repeat forever. After each run it prints that run's LOG entry

## 1.19.0 — 2026-10-20
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
