# Release process

Claude releases on its own, following the criteria in `CLAUDE.md`. The procedure is the same when a person does it.

## Branch flow (git flow)

```
feature/<topic> ──PR──▶ develop ──▶ release/<ver> ──PR──▶ main (+ tag v<ver>)
                                                        └──PR──▶ develop (back-merge of main)
```

## Steps

1. Feature PRs merge into `develop`, and items pile up under `## Unreleased` in `CHANGELOG.md`.
2. `git checkout -b release/<ver> origin/develop`
3. `bash scripts/bump.sh <major|minor|patch>`: `## Unreleased` becomes `## <ver> — <date>` and the SKILL.md and plugin.json versions are updated.
4. `bash scripts/validate.sh` → PASS → commit `chore(release): <ver>` → push
5. Open and merge the PR `release/<ver>` → `main` (merge commit)
6. Open and merge the PR `main` → `develop` (the back-merge; `develop` is never a PR head because merged heads are deleted automatically)
7. Pull `main`, then `bash scripts/release.sh`

What `release.sh` does:
1. Checks that it is on `main`
2. Runs `validate.sh`
3. Checks that the working tree is clean
4. Checks that tag `v<ver>` does not exist yet
5. Builds `dist/autopilot-<ver>.skill` from committed content (`git archive`)
6. `git tag -a v<ver>` → `git push origin v<ver>`. If that fails it deletes the local tag; if `gh` can write to this repository it creates the tag and the Release on GitHub together with `gh release create --target <commit>`. Otherwise it exits
7. With `gh`, creates the Release with the CHANGELOG section as notes and attaches the `.skill` file

## Creating missing tags in one go

Releasing where neither tag pushes nor `gh` work leaves `main` with the version but no tag. Claude Code cloud sessions are like that: git tag pushes get a 403 and the Release API answers "not permitted for this session type" by policy. Wherever you can push tags or have a `gh` that can write:

```bash
git checkout main && git pull
bash scripts/release.sh --catch-up
```

For every version in the CHANGELOG without a tag, it finds the first commit on `main`'s first-parent history where plugin.json became that version, tags it, pushes and creates the Release. The package is built from that commit's content. Log in with `gh auth login` first: once a tag exists, later runs skip that version and its Release would have to be created by hand.

## Without gh

`release.sh` pushes the tag and prints instructions. By hand:

1. GitHub repository → **Releases** → **Draft a new release**
2. Tag: `v<ver>` (already pushed)
3. Title: `autopilot <ver>`
4. Body: the `## <ver>` section of `CHANGELOG.md`
5. Attach `dist/autopilot-<ver>.skill` → **Publish release**

## The .skill file

A zip file with a single top-level `autopilot/` folder.

```
autopilot-<ver>.skill
└── autopilot/
    ├── SKILL.md
    ├── assets/
    └── scripts/
```

`unzip -l dist/autopilot-<ver>.skill` shows whether the top level is `autopilot/`.

## When a release is wrong

Never delete or rewrite tags. Bump the PATCH version and release again.
