# Contributing

Thanks for your interest in improving autopilot. Please read `CLAUDE.md` and the files in `docs/` before you start.

## Branching (git flow)

| Branch | Purpose |
|---|---|
| `main` | Released code only. Every commit on `main` is a tagged release (`v<version>`) |
| `develop` | Integration branch. All feature work merges here |
| `feature/<topic>` | One change. Branch from `develop`, open the PR against `develop` |
| `release/<version>` | Release preparation. Branch from `develop`, merge into `main` **and** back into `develop` |
| `hotfix/<version>` | Urgent fix. Branch from `main`, merge into `main` **and** `develop` |

## Development flow

1. Branch from `develop`: `git checkout -b feature/<topic> develop`
2. Make your change.
3. Bump the version: `bash scripts/bump.sh <major|minor|patch> "<summary>"`
4. Validate locally: `bash scripts/validate.sh` (must print `PASS`)
5. Commit and open a pull request against `develop`.

## Rules

- **There is no CI.** Nothing checks your PR automatically, so running `scripts/validate.sh` locally before every commit is mandatory. Paste its final line into the PR description.
- **Every PR needs a `CHANGELOG.md` entry.** `bump.sh` creates it; edit the text if needed.
- **Versions change only through `scripts/bump.sh`.** Never edit version strings by hand; the three version locations must always match (see `docs/versioning.md`).
- **Changing the rules in `SKILL.md` (loop, discovery, stop conditions) is at least a MINOR bump.** Changes that make existing `.autopilot/` state files incompatible are MAJOR. Script fixes and wording are PATCH.
- Do not add GitHub Actions workflows.
- Do not run `scripts/release.sh`; maintainers release from `main`.
- Read `docs/skill-design.md` before changing `SKILL.md`, and keep its design intent intact.
