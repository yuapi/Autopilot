# CONFIG (autopilot integration policy and language)

People set this file. autopilot only reads it and never changes it. Without this file the defaults below apply.
Changing integration values sends results outside the repository (remote branches, PRs, releases), so change them deliberately.

```
integration: local      # local | branch | pr
base_branch: auto       # where task branches start and PRs target. auto = develop if it exists, else the remote default branch
branch_prefix: auto     # task branch prefix. auto = the repository convention (CONTRIBUTING etc.) if any, else autopilot/
merge: off              # in pr mode: off = only open PRs | auto = merge after verification passes
release: off            # off | auto = follow the repository's documented release procedure, if it has one
language: auto          # language of notes people read (ROADMAP, LOG, proposals): auto | en | ko | ja | ... (BCP 47)
```

- `local`: only commit on the current branch. No push (default, safest)
- `branch`: create `<prefix><task ID>-<slug>` per task, commit and push it. No PR
- `pr`: like `branch`, plus open a PR to base_branch. With `merge: auto`, merge after verification
- `language: auto`: the language already used in `.autopilot/`, else the README's language, else the language you used, else English
