# Operations: the Stop hook, the driver, status

Read this when a person asks how to run, check or stop autopilot, when the Stop hook needs installing or refreshing, or with a terminal and the driver. SKILL.md keeps what the loop needs on every task ("The Stop hook": when it blocks and how to release it).

## The Stop hook: how it is installed

The hook is declared in this skill's frontmatter, so Claude Code runs it **only in sessions that invoked this skill**, from the skill's own folder (`assets/autopilot-stop.sh`). Nothing is copied into the repository and `.claude/settings.json` is not touched. Claude Code asks once for permission to run a skill that declares hooks; the driver's allowlist already includes `Skill`.

**Fallback for environments that ignore skill hooks**: `bash <skill folder>/scripts/hook.sh install` copies the hook to `.claude/hooks/autopilot-stop.sh` and merges this into `.claude/settings.json` (keeping other hooks), then commit both files:

```json
{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/autopilot-stop.sh\""}]}]}}
```

It also refreshes such a copy whenever it differs from this skill's version. `hook.sh uninstall` removes the copy and only its settings entry. If a permission check blocks it, record that in the LOG and rely on the rules alone.

## Driver (only with a terminal, optional)

With a terminal you can use the driver instead of session mode. Every task starts with a fresh context, which keeps judgment steady over long loops. The driver sets `AUTOPILOT_DRIVER=1`, so the skill runs in driver mode automatically.

```
cd <repository root>
bash <skill folder>/scripts/autopilot.sh          # unlimited
bash <skill folder>/scripts/autopilot.sh 20       # 20 runs at most
```

The default is an `--allowedTools` allowlist (with `Agent` for subagents unless CONFIG sets `subagents: off`). In a dedicated container, `AUTOPILOT_PERMISSION=skip`. `AUTOPILOT_MODEL` picks the model for every run, and `AUTOPILOT_MAX_COST` stops the driver once the runs together cost that many USD.

The driver only gives Claude Bash and file tools, not MCP servers, so in `pr` mode PRs are opened with the `gh` CLI (merge requests with `glab` when `origin` is on GitLab). Before the loop starts, the driver checks the integration mode and warns if `origin` is missing (`branch`/`pr`) or if `gh` (`glab`) is missing or cannot push to the repository (`pr`).

## Checking status (for people)

```
bash <skill folder>/scripts/status.sh [repository path]
```

Shows on one screen whether the loop is running or stopped and why (and which session owns the run and when it was last active), the integration settings, task counts (open, in progress, done, blocked), the task in progress and how long ago it started, the success rate of the last 10 runs, open tasks, blocked tasks that need a person, proposals awaiting a decision and the latest LOG entries, plus the installed skill version with a warning when the LOG was written by a newer one. It only reads the state files. When someone asks "what is autopilot doing" or "autopilot status", run it and show the output. With the plugin installed, people can also type `/autopilot:run [N]` to start the loop (for N tasks), `/autopilot:status`, and `/autopilot:stop` to stop the loop after its current task (`runlock.sh stop` writes `.autopilot/STOP`).

## When the repository has its own Stop hook

If the repository has a Stop hook that demands committing untracked files, this skill's Phase 4 rollback (`git clean`) and Phase 5 commit satisfy it naturally. The `.autopilot/` run artifacts (STOP, STOP.refused, .scan-required, RUN, .hook-state, .task, driver-logs, driver.lock) are added to `.gitignore` by `runlock.sh start` (session mode) and by the driver.
