# CONFIG (autopilot integration policy and language)

People set this file. autopilot only reads it and never changes it. Without this file the defaults below apply.
Changing integration values sends results outside the repository (remote branches, PRs, releases), so change them deliberately.

```
integration: local      # local | branch | pr
base_branch: auto       # where task branches start and PRs target. auto = develop if it exists, else the remote default branch
branch_prefix: auto     # task branch prefix. auto = the repository convention (CONTRIBUTING etc.) if any, else autopilot/
merge: off              # in pr mode: off = only open PRs | auto = merge after verification passes
release: off            # off | auto = follow the repository's documented release procedure, if it has one
local_branch: auto      # local mode: auto = never commit on a default branch (main, master, develop, …); start autopilot/<date> instead | current = commit on whatever is checked out
language: auto          # language of notes people read (ROADMAP, LOG, proposals): auto | en | ko | ja | ... (BCP 47)
scope: .                # paths autopilot may work in, space-separated, relative to the repository root (. = all). For one package of a monorepo: scope: packages/api
```

- `local`: only commit locally, no push (default, safest). On a default branch it first switches to a new `autopilot/<date>` branch
- `branch`: create `<prefix><task ID>-<slug>` per task, commit and push it. No PR
- `pr`: like `branch`, plus open a PR to base_branch. With `merge: auto`, merge after verification
- `language: auto`: the language already used in `.autopilot/`, else the README's language, else the language you used, else English
- `scope`: discovery reads and runs only these paths and tasks change only files under them (plus `.autopilot/`); `task.sh done` refuses a commit that changes anything else
