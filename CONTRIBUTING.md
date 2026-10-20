# Contributing

Thanks for your interest in improving autopilot. Please read `CLAUDE.md` and the files in `docs/` before you start.

This repository is developed largely by Claude itself, following `CLAUDE.md`. Humans and agents follow the same flow.

## Branching (git flow)

| Branch | Purpose |
|---|---|
| `main` | Released code only. Every release is tagged `v<version>` |
| `develop` | Integration branch. All feature work merges here |
| `feature/<topic>` | One change. Branch from `develop`, open the PR against `develop` |
| `release/<version>` | Release preparation. Branch from `develop`, merge into `main`, then back-merge `main` into `develop` |
| `hotfix/<version>` | Urgent fix. Branch from `main`, merge into `main` and back into `develop` |

Merged head branches are deleted automatically (repository setting). Never open a PR with `develop` as its head.

## Development flow

1. Branch from `develop`: `git checkout -b feature/<topic> develop`
2. Make your change and add a line under `## Unreleased` in `CHANGELOG.md`.
3. Validate locally: `bash scripts/validate.sh` (must print `Result: PASS`; it also runs `tests/`).
4. Commit using Conventional Commits (`feat(skill): ...`, `fix(hook): ...`) and open a PR against `develop`.

Version numbers are **not** bumped in feature PRs. They are bumped on the release branch.

## Releasing

1. `git checkout -b release/<version> develop`
2. `bash scripts/bump.sh <major|minor|patch>` turns `## Unreleased` into `## <version> — <date>`.
3. Validate, commit as `chore(release): <version>`, PR into `main`, merge, then PR `main` into `develop`.
4. On `main`: `bash scripts/release.sh` creates the tag, the `.skill` package and the GitHub Release.
   If tags could not be pushed at release time, `bash scripts/release.sh --catch-up` tags every released version that is missing a tag.

## Rules

- **There is no CI.** Running `scripts/validate.sh` locally before every commit is mandatory. Paste its final line into the PR description.
- **Every PR that changes behavior needs a `CHANGELOG.md` line under `## Unreleased`.**
- **Versions change only through `scripts/bump.sh`.** Never edit version strings by hand (see `docs/versioning.md`).
- **Changing the rules in `SKILL.md` (loop, discovery, stop conditions) is at least a MINOR release.** Changes that make existing `.autopilot/` state files incompatible are MAJOR. Script fixes and wording are PATCH.
- Do not add GitHub Actions workflows.
- Read `docs/skill-design.md` before changing `SKILL.md`, and keep its design intent intact.
