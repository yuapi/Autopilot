# Integration policy: `branch` and `pr` modes

Read this when `.autopilot/CONFIG.md` sets `integration: branch` or `integration: pr`, before Phase 0 step 1, and follow it on every task. The rules in SKILL.md ("Integration policy": CONFIG is the person's, the repository's conventions come first, and "Always") apply on top of it.

| Step | `local` | `branch` | `pr` |
|---|---|---|---|
| Phase 0 | leave a default branch for `autopilot/<date>` (`workbranch.sh`), otherwise stay | fetch the base and start from its latest commit | same |
| Phase 3 start | - | create branch `<prefix><task ID>-<slug>` | same |
| Phase 4 failure | roll back | roll back, return to the base, delete the local task branch | same |
| Phase 5 success | commit (cloud session without `integration` in CONFIG: also push the work branch, `workbranch.sh --push`) | commit → `git push -u origin <branch>` | push → open a PR (`gh`; `glab mr create` for a GitLab origin; or MCP) → merge if `merge: auto` |

Handling the state files (`.autopilot/`):
- While running, the `.autopilot/` in the working directory is the only truth. When switching branches, copy `.autopilot/` somewhere temporary and copy it back after switching. That way attempts and done records survive even when PRs are not merged yet.
- Commit state changes together with the task branch commit. State only accumulates, so when PRs conflict on `.autopilot/`, take the version from the later task.
- Do not select task IDs that appear in the branch name of an open PR.

PR rules:
- The body gives the task ID, a summary of the change, the verification result (Phase 4 commands and numbers) and `Refs #N` for issue-sourced tasks. Follow the repository's PR template if it has one.
- `merge: auto` merges only when Phase 4 passed, the repository's CI (if any) passed and there are no conflicts. Use the repository's merge method, else a merge commit. If the conditions are not met, leave the PR open and move to the next task.
- While unmerged PRs exist, the next task starts fresh from the base. Do not select tasks touching the same files as an open PR until it is merged.
- Read review comments on your own PRs in 1-E like issues and turn them into fix tasks.
- **Revisit your own open PRs** (head branch starts with `branch_prefix`) at the start of every task, right after 1-E. Do not wait for checks that are still running; look again on the next task.
  - CI now passed, no conflicts, `merge: auto` → merge it now (this is how a PR left open for pending CI gets merged).
  - CI failed → a `fix` task on that PR's branch, source `PR #N CI`, with the failing check's name and log summary as evidence. Fix it on the same branch and push; do not open a second PR.
  - Conflicts with the base → a `fix` task: merge the base into that branch (never rebase or force push), re-run Phase 4, push.
  - Never create a second task for the same PR while one is open. If the same PR fails 3 tasks in a row, leave it open and record it in the LOG and the STOP summary for a person.

Release (`pr` + `release: auto`):
- Only if the repository documents a release procedure (how to bump the version, CHANGELOG, tags). Otherwise do not release; leave a proposal (1-F).
- When unreleased changes include at least one substantive task, choose the version kind and proceed exactly as documented. Never invent steps the documentation does not have. Record it as a `release` LOG entry (version, what was merged, and any step that was blocked, such as a tag push).
