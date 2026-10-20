# CLAUDE.md

This repository distributes the autonomous development loop skill `autopilot` as a Claude Code plugin marketplace.
**Claude develops and releases this repository on its own.** Without instructions from a person, find the next piece of work and carry it through to the end with the procedure below.

## At the start of a session

1. Read `docs/`. Always read `skill-design.md` before changing SKILL.md.
2. Read `.autopilot/ROADMAP.md`, `.autopilot/BACKLOG.md`, the latest entries of `.autopilot/LOG.md` and `.autopilot/PROPOSALS.md`. They are this repository's own development state. `.autopilot/CONFIG.md` (integration: pr, merge and release: auto) expresses the flow below as skill settings.
3. A concrete request from a person comes first. If there is none, or the request is "do it on your own", pick the next task from the BACKLOG and carry it out. The BACKLOG is run by the autopilot skill's procedure (discover, select, verify, record).

## Development flow (git flow, carried out by Claude end to end)

| Branch | Purpose |
|---|---|
| `main` | Released code only. Every release commit is tagged `v<ver>` |
| `develop` | Integration branch |
| `feature/<slug>` | One task. Branch from `develop`, merge into `develop` through a PR |
| `release/<ver>` | Release preparation. Branch from `develop`, merge into `main` through a PR |
| `hotfix/<ver>` | Urgent fix on `main`. Merge into `main`, then back-merge into `develop` |

One task:

1. `git checkout -b feature/<slug> origin/develop`
2. Implement. When the skill, scripts or docs change, add a line under `## Unreleased` in `CHANGELOG.md`.
3. `bash scripts/validate.sh` → check `Result: PASS` (tests included). If it fails, fix it or drop the change. When the change touches discovery rules in SKILL.md, also run `bash scripts/eval.sh` for every fixture (`--fixture list`) and put the scores before and after in the PR body.
4. Commit following the commit rules below → `git push -u origin feature/<slug>`
5. Open the PR (`feature/<slug>` → `develop`) with the change and verification result in the body, then **merge it yourself as a merge commit**.

## Releases (Claude decides and carries them out)

Release when substantive changes (skill behavior, bug fixes, script features) have piled up under `## Unreleased` on `develop`. Changes to docs or wording alone wait for the next substantive change.

1. Choose the kind: incompatible state file format → `major`, SKILL.md behavior rules or new features → `minor`, anything else → `patch` (`docs/versioning.md`).
2. `git checkout -b release/<ver> origin/develop` → `bash scripts/bump.sh <kind>` (the Unreleased items become the new version section) → validate → commit and push
3. Open and merge the PR `release/<ver>` → `main`, then open and merge the back-merge PR `main` → `develop`
4. Pull `main` and run `bash scripts/release.sh` (tag, `.skill` package, GitHub Release)
5. Claude Code cloud sessions block both tag pushes and Release creation by policy (git 403, API "not permitted for this session type"). When blocked, do not work around it: record "tag pending" in the LOG and continue with the next task. A person runs `bash scripts/release.sh --catch-up` locally once to create all missing tags and Releases. (Where only git tag pushes are blocked but the API is open, `release.sh` creates them with `gh` instead.)

## Commit rules (Conventional Commits)

```
<type>(<scope>): <summary in English, imperative, no trailing period>

<body: what and why, wrapped at 72 characters>
```

- type: `feat` `fix` `docs` `test` `refactor` `chore` `build` / release commits are `chore(release): <ver>`
- scope examples: `skill` `hook` `driver` `validate` `bump` `release` `repo` `autopilot` (this repository's `.autopilot/` state)
- One task = one PR. Split changes of different nature within a PR into separate commits.
- PR titles and bodies are in English too. Notes inside `.autopilot/` follow its `language` setting.

## Hard rules

- Never create GitHub Actions workflows. Validation runs locally with `scripts/validate.sh`.
- Change version strings only with `scripts/bump.sh`.
- Never push directly to `main` or `develop`, and never force push. Never rewrite the history of shared branches. Never delete or rewrite tags.
- Never work around actions blocked by permission checks or policy. Record where it was blocked in the LOG and continue with the rest of the work.
- When a change to the skill breaks a design intention in `docs/skill-design.md`, update that document in the same PR and explain why.
- Never create or commit secrets or tokens.

## Branch cleanup

The repository setting "Automatically delete head branches" deletes the head branch of merged PRs. That is why `develop` is never a PR head (the back-merge goes `main` → `develop`).
