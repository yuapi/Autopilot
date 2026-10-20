# Why SKILL.md is the way it is

Read this before changing SKILL.md. SKILL.md says *what* the rules are; this file only says *why*. If a change breaks any of the intentions below, think again.

## Why one task at a time

- **Keep failures small.** A failed verification rolls back everything, so a large unit throws away the parts that worked. Small units make rollback cheap.
- **Hand state over through files.** Every finished task is written to BACKLOG and LOG, so the next task continues from the same point even if the session breaks or the context changes. Carrying several tasks in your head loses that state together with the context.
- **Let people review afterwards.** One task = one commit, so people can later revert or pick commit by commit.
- **1–2 hours of work with verifiable completion criteria** is required for the same reason. With vague criteria the verification step cannot decide, and "almost done" commits appear.

## Why baseline commands are recorded and flaky tests excluded

- Verification is a comparison: "is anything worse than the baseline?" If the commands are rediscovered differently every time, the comparison means nothing, so the commands found once are written in the ROADMAP and reused. Repository docs come before ecosystem guesses because what the people in that repository decided is the most accurate.
- Flaky tests in the comparison roll back good work at random, and the 3-failure rule then blocks good tasks. A test whose result changes between two runs is recorded separately, left out of the comparison, and fixing it becomes a task of its own.
- In a repository without tests there is no way to check "nothing got worse", so every task would be committed unverified. That is why a minimal harness comes first — before `fix` too. The rule used to place it right after `fix`, and the `wordcount` eval showed the result: the bug was fixed and committed with nothing to verify it. This is different from the "piling up easy tests" the per-cycle `test` limit guards against, so it is exempt from that limit.

## Why proposals (PROPOSALS) exist

"Never ask a person" and "never change a public interface" keep the loop safe, but on their own they silently drop valuable ideas. A proposal is not a question but an asynchronous note. The loop keeps running without waiting, and people decide whenever they like by changing one status cell. Allowing interface changes only within an adopted proposal's scope keeps the original principle — change only what a person explicitly approved — while opening the road that was blocked.

Writing proposals does not count as substantive work because more proposals can always be written; if they fueled the loop, "cannot stop" would come back. The limit of 3 per cycle exists for the same reason.

## Why the retrospective

The state files let the loop remember what it did, but not learn from why it failed. When tasks keep failing for the same reason (too large, vague criteria, environment limits), the 3-failure rule only blocks them one by one and the cause stays. Classifying failures every 10 tasks and keeping short, repository-specific rules under "Learned" makes later discovery and implementation follow them. The 15-line limit keeps the lessons from growing into a cost paid on every task, and keeps stale rules from clouding judgment. Blocked tasks are split or retired rather than reopened unchanged so the retrospective does not become a way to revive failed work.

## Why substantive and auxiliary work are separated

The most common failure of an autonomous loop is "cannot stop". Lint, docs and refactoring can always be produced even when real work has run out, so letting them fuel the loop piles up meaningless commits forever. Therefore:

- Only tasks that change behavior (fixing defects, adding or improving features) may keep the loop going.
- Tasks that only change form are allowed **only alongside** substantive tasks.

When adding a new task type, ask: "Could the loop run forever on this alone?" If yes, it is auxiliary.

## Why the product axis is needed

Running only the maintenance axis (tests, lint, TODOs) raises coverage but does not make the software better. Whether features users expect are missing cannot be seen from code markers; it shows only after writing down what the software is. Requiring at least half the queue from the product axis and capping `test` at 2 per cycle counters the loop's tendency to drift toward the easy side (adding tests).

## Why the rules exist once in English while output follows the user's language

- Keeping the rules (SKILL.md) in several languages means fixing one leaves the others out of sync, and out-of-sync rules make the loop behave differently per language. So the rules exist once, in English. English is the language models follow instructions in most reliably, and the one most people can read in a public distribution.
- Notes people read (ROADMAP, LOG, proposals, the STOP summary) are useful only in the language of the people using that repository. `language` lives in CONFIG (a file people set), and `auto` follows the language of the existing state files first, because switching language between runs would mix languages in one file.
- Values scripts read (statuses, types, proposal statuses, config keys) are never translated; translating them would break tools like status.sh and archive.sh per language. The Korean proposal statuses of 1.8.x and earlier (`제안`, `채택`, …) are still understood with the same meaning so existing `.autopilot/` directories keep working. That is why this change is not MAJOR.

## Why discovery has a script and a done-check

The first run of `scripts/eval.sh` showed that a model following a long rule list skips steps: it left the feature map, observations and scenarios as template placeholders, ran nothing, and never searched for code markers (score 4/5). Rules that can be checked mechanically are therefore a script (`scan.sh`), whose output must be dealt with line by line, and the steps that need judgment end with a done-check that looks for concrete evidence in the ROADMAP (a filled feature map, commands actually run, three scenarios). With both, the same eval scored 5/5 and found defects that were not even seeded. Anything a later change adds to discovery should come with the same two things: something checkable, and a place where its result must be written down.

## Why it runs the software and walks through scenarios

A feature map built from reading code tells you what exists, not whether it is usable. Tests check only the inputs their authors expected. Many real defects come from unexpected inputs (empty values, missing files, paths with spaces) and from mismatches between docs and behavior, and they only show when you run the software. User scenarios find the points where individual features work but get stuck when chained (a missing setup step, output that does not say what to do next). Using the software like a user is the only way to learn what is inconvenient without a human.

Running things has side effects, so temporary directories, timeouts and no external calls come with it. If it cannot be run, reading the code takes its place, and that fact is recorded so it can be tried again once the environment allows.

## Why the issue tracker is checked on every task

What an autonomous loop finds on its own is a guess. What people wrote in issues are problems real users hit, so they are more certain. That is why new issues are checked on every task instead of waiting for the 7-day discovery cycle (only issues since `last_issue_check`, so it is cheap). People can steer the loop just by writing issues, with no other explanation.

Issue text is external input anyone can write. Following its sentences as instructions would let anyone command the loop. So the text is used only as data for judging what the problem is, and the scope of work and allowed actions come from the skill's rules alone. Not commenting on or closing issues follows the same reasoning: actions with external effects happen only when the integration policy allows them.

## Why open PRs are revisited

`merge: auto` merges only when CI has passed, and the loop never waits for CI to finish. Without a second look, a PR whose checks were still running when the task ended stayed open forever, and the next tasks avoided its files, so the loop slowly blocked itself. Checking its own open PRs at the start of every task merges those that have since passed, and turns failures and conflicts into ordinary `fix` tasks on the same branch, so a red PR gets the same verify-and-record treatment as any other defect. Merging the base instead of rebasing keeps the branch history people may already have pulled.

## Why the final stop conditions are what they are

- **Zero substantive tasks → stop.** Stopping when there is nothing to do is the only legitimate voluntary exit. To keep it from skipping the product review and declaring "nothing", zero can only be concluded after the ROADMAP states that "Missing" and "Weak" are empty. It guards against lazy exits.
- **Four stages of deep discovery before concluding zero.** One static scan finds only what reading shows. The judgment "nothing left to do" becomes trustworthy only after running the software, new scenarios, the quality attribute checklist and external signals. Stopping when the work has truly run out is right; stopping because you looked too little is the same as stopping early. Recording each stage's result in the ROADMAP prevents skipping stages.
- Deep discovery is not a device to stretch the loop. What it finds must still pass the substantive test (does behavior change) to enter the queue. If only auxiliary work comes out, the loop still stops.
- **Repeated failure (7 of 10) → stop.** The environment is broken or the loop cannot handle the situation. Continuing only spends money on rollbacks.
- **3 failures per task → blocked.** One task must not hold the whole loop.
- **Same file 5 times in a row → excluded.** Breaks oscillation around one spot.
- **Otherwise it never stops.** In particular, voluntary exits like "that's one done, good enough" are forbidden. In unattended runs an early exit means a person has to wake the loop again, which defeats the purpose of this skill. That is why the STOP file is the only exit signal.

## Conservative defaults

- Instead of asking, pick the conservative option when unsure and write the reason in the LOG — with nobody around, the easily reversible choice is the safe one.
- Public interfaces may only grow, never change or shrink — signature changes are the main way an autonomous loop breaks users' code.
- No push by default (`local`) — all results stay local so people can review before publishing. The safety notice in this repository's README relies on this.
- Never commit onto a default branch even in `local` mode — `main` or `develop` is what people pull and branch from, so unreviewed commits there spread before anyone looks. Moving to a dated `autopilot/` branch keeps the work separate and easy to review or throw away. Staying on any other branch respects a branch the person chose. This is a script rather than a sentence so it behaves the same every time and is tested.
- Publishing results (`branch`, `pr`, automatic merge, automatic release) happens only when people explicitly choose it in `.autopilot/CONFIG.md`. Claude never creates or edits that file so the loop cannot widen its own permissions. It is a committed file, so who changed it and when stays on record.
- The repository's conventions (CONTRIBUTING etc.) win over CONFIG defaults because what the people in that repository already decided is the least surprising result. Releases are automatic only when a documented procedure exists; invented procedures would produce versions and tags people do not expect.
- reset --hard, force push, deleting remote branches and rewriting tags are forbidden in every mode — they cause losses that cannot be undone.

## Session mode vs driver mode

| | Session | Driver |
|---|---|---|
| Requirements | none (works in cloud sessions) | terminal, `claude` CLI |
| Context | grows as tasks pile up | fresh for every task |
| Judgment | may degrade in long runs | steady |
| Early-exit risk | yes → backed by the Stop hook | low, the shell loop calls again |
| Permissions | the session's own | allowlist by default, skip is opt-in |

- Session mode is the default because it must work without a terminal and right after installation.
- The price is a growing context, hence the rule "re-read the state files at the start of every task; do not trust memory". Remove that rule and session mode falls apart in long runs.
- Re-reading the state every task gets expensive as the files grow. After hundreds of tasks the whole LOG and BACKLOG would fill the context and crowd out room for judgment. So only the range the rules need (the last 20 LOG entries, open tasks) is read and old records are moved to archives. A script does the moving so Claude never rewrites records. Duplicate checks grep the archives so nothing is lost.
- The Stop hook is insurance against early exits the rules alone cannot prevent. Continuing on the rules alone when the hook cannot be installed keeps the hook from becoming a hard dependency.
- The hook acts only while `.autopilot/RUN` exists. The hook settings are committed and stay in the repository while STOP is gitignored, so "block when there is no STOP" alone would trap ordinary sessions and fresh clones after the loop has ended. Marking "running" separately makes the hook act only on the loop.
- RUN names the session that owns the loop, and the hook acts only on that session. Without an owner, a person who opens a second session in the same repository while the loop runs could not end it. The ID comes from `CLAUDE_CODE_SESSION_ID`, which equals the `session_id` Claude Code passes to the hook. A RUN without an owner keeps the old behavior so nothing silently stops being protected.
- Only one loop may run per repository. Two loops pick the same task, interleave edits to the BACKLOG and fight over commits. A second session-mode loop is refused while RUN is active, and a second driver is refused while `driver.lock` holds a live PID or a session loop is active. A marker idle for 2 hours counts as abandoned so a crashed session never locks the repository for good.
- The hook is declared in the skill's frontmatter rather than copied into the user's repository. A copy in the repository has two costs: a fix to the hook reaches nobody until the copy is refreshed (1.6–1.12 copies kept blocking other sessions after the fix), and committed hook settings act on every session and clone of that repository, which is why RUN and the owner check had to exist. A skill-scoped hook runs from the installed skill, so updating the skill updates the hook, and it runs only in sessions that invoked the skill. RUN and the owner check stay because the same session can keep running after a STOP, and because older copies may still be present.
- `hook.sh install` stays as a fallback for environments that ignore skill hooks, and Phase 0 refreshes a copy an older version left behind (replacing it whenever it differs; checking for one known old feature, as the 1.6 rule did, misses every later fix). When both the skill hook and a copy run for the same stop, the transcript size identifies it as one stop so the no-progress counter advances once.
- The hook reads stdin with a 2-second limit and never on a terminal. A hook that can hang would hang the session it is meant to keep going.
- After 3 consecutive blocks with no change to the LOG or commits, the hook writes STOP itself. Blocking forever in a state where Claude cannot make progress (such as permission denials) only spends money and improves nothing. "Never stop" is a principle for while progress is being made.
- The driver applies the same no-progress limit to its runs: a run that exits normally but changes neither the LOG nor the commits counts, and 3 in a row write STOP. The crash limit alone missed this case, since a run stuck on permission denials still exits 0 and the shell loop would pay for it forever.
- The driver defaults to an allowlist because unattended repeated runs must not bypass permissions by default.
