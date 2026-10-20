#!/usr/bin/env bash
# Commands written in SKILL.md must do what they claim
. "$(dirname "$0")/lib.sh"
SKILL="$REPO/$SKILL_REL/SKILL.md"

# Phase 4 rollback command: the first `...` code on the "On failure:" line
rollback="$(grep -m1 'On failure:' "$SKILL" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')"
check "extracts the Phase 4 rollback command" test -n "$rollback"

d="$(mktemp -d "$TMPROOT/r.XXXX")"
(
  cd "$d" && git init -q && git config user.email t@t && git config user.name t
  mkdir -p .autopilot src && echo a > src/x && echo "attempts 0" > .autopilot/BACKLOG.md
  git add -A && git commit -qm init
  echo b > src/x; echo new > src/new; mkdir src/newdir && echo z > src/newdir/f
  echo "attempts 1" > .autopilot/BACKLOG.md; echo s > .autopilot/untracked-state
  eval "$rollback"
) >/dev/null 2>&1
check "rollback: modified file restored" grep -qx a "$d/src/x"
check "rollback: new file removed" test ! -e "$d/src/new"
check "rollback: new folder removed" test ! -e "$d/src/newdir"
check "rollback: .autopilot change (attempts) kept" grep -qx "attempts 1" "$d/.autopilot/BACKLOG.md"
check "rollback: new .autopilot file kept" test -f "$d/.autopilot/untracked-state"

# The Stop hook settings example is valid JSON and uses \$CLAUDE_PROJECT_DIR
json="$(grep -m1 '{"hooks":{"Stop"' "$SKILL")"
check "Stop hook settings example is valid JSON" python3 -c 'import json,sys; json.loads(sys.argv[1])' "$json"
check "Stop hook command uses \$CLAUDE_PROJECT_DIR" grep -q 'CLAUDE_PROJECT_DIR' <<<"$json"

# Phase 0 working tree command: stashes only outside .autopilot, keeps uncommitted .autopilot state
tidy="$(grep -m1 'Working tree check:' "$SKILL" | sed -n 's/^[^`]*`[^`]*`[^`]*`\([^`]*\)`.*/\1/p')"
check "extracts the Phase 0 tidy command" grep -q '^git stash' <<<"$tidy"
d="$(mktemp -d "$TMPROOT/r.XXXX")"
(
  cd "$d" && git init -q && git config user.email t@t && git config user.name t
  mkdir -p .autopilot src && echo a > src/x && echo "attempts 0" > .autopilot/BACKLOG.md
  git add -A && git commit -qm init
  echo b > src/x; echo new > src/new; echo "attempts 1" > .autopilot/BACKLOG.md; echo f > .autopilot/LOG.md
  eval "$tidy"
) >/dev/null 2>&1
check "tidy: work file changes stashed" grep -qx a "$d/src/x"
check "tidy: new work files stashed too" test ! -e "$d/src/new"
check "tidy: one stash created" test "$(git -C "$d" stash list | wc -l)" -eq 1
check "tidy: .autopilot change kept" grep -qx "attempts 1" "$d/.autopilot/BACKLOG.md"
check "tidy: new .autopilot file kept" test -f "$d/.autopilot/LOG.md"

# CONFIG template: defaults are the safest values and only known keys exist
cfg="$REPO/$SKILL_REL/assets/CONFIG.md"
val() { sed -n "s/^$1:[[:space:]]*\([^[:space:]#]*\).*/\1/p" "$cfg"; }
check "CONFIG default integration=local" test "$(val integration)" = local
check "CONFIG default merge=off" test "$(val merge)" = off
check "CONFIG default release=off" test "$(val release)" = off
keys="$(sed -n 's/^\([a-z_]*\):.*/\1/p' "$cfg" | sort | tr '\n' ' ')"
check "CONFIG key list" test "$keys" = "base_branch branch_prefix integration language local_branch merge release "
check "SKILL.md: Claude never changes CONFIG" grep -q "Claude never creates it or changes its values" "$REPO/$SKILL_REL/SKILL.md"

# plugin commands: frontmatter description, and every ${CLAUDE_PLUGIN_ROOT} path they run exists
PLUGIN="$REPO/plugins/autopilot"
for c in "$PLUGIN"/commands/*.md; do
  n="$(basename "$c" .md)"
  check "command /autopilot:$n has a description" grep -qE '^description: .{10,}' "$c"
  for rel in $(grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' "$c" | sed 's#^${CLAUDE_PLUGIN_ROOT}/##' | sort -u); do
    check "command /autopilot:$n runs an existing file ($rel)" test -f "$PLUGIN/$rel"
  done
done
check "status and stop commands exist" test -f "$PLUGIN/commands/status.md" -a -f "$PLUGIN/commands/stop.md"

finish
