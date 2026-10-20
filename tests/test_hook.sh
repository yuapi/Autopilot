#!/usr/bin/env bash
# Tests for assets/autopilot-stop.sh (the Stop hook)
. "$(dirname "$0")/lib.sh"
HOOK="$REPO/$SKILL_REL/assets/autopilot-stop.sh"

newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/r.XXXX")"
  (cd "$d" && git init -q && git config user.email t@t && git config user.name t \
    && mkdir .autopilot && echo "# LOG" > .autopilot/LOG.md && git add -A && git commit -qm init)
  echo "$d"
}
run_hook() { (cd "$TMPROOT" && CLAUDE_PROJECT_DIR="$1" bash "$HOOK" </dev/null); }
# hook as Claude Code calls it: JSON with the ending session's ID on stdin
hook_as() { (cd "$TMPROOT" && printf '{"session_id":"%s","hook_event_name":"Stop"}' "$2" | CLAUDE_PROJECT_DIR="$1" bash "$HOOK"); }
blocks() { run_hook "$1" | grep -q '"decision":"block"'; }

d="$(newrepo)"
check_not "no RUN → does not block" blocks "$d"
check "no RUN → no output" test -z "$(run_hook "$d")"

touch "$d/.autopilot/RUN"
check "RUN and no STOP → block" blocks "$d"
check "state file written under CLAUDE_PROJECT_DIR" test -f "$d/.autopilot/.hook-state"

echo "- progress" >> "$d/.autopilot/LOG.md"
check "blocks again after LOG progress" blocks "$d"
check "counter 0 after progress" grep -q ' 0$' "$d/.autopilot/.hook-state"

check "no progress, 1st time → block" blocks "$d"
check "no progress, 2nd time → block" blocks "$d"
check_not "no progress, 3rd time → allows ending" blocks "$d"
check "stall → STOP created" grep -q "no progress" "$d/.autopilot/STOP"
check "stall → RUN removed" test ! -e "$d/.autopilot/RUN"

d="$(newrepo)"; touch "$d/.autopilot/RUN"
blocks "$d"; blocks "$d"
(cd "$d" && git commit -q --allow-empty -m next)
check "a new commit counts as progress" blocks "$d"
check "counter 0 after a commit" grep -q ' 0$' "$d/.autopilot/.hook-state"

d="$(newrepo)"; touch "$d/.autopilot/RUN" "$d/.autopilot/STOP"
check_not "STOP → allows ending" blocks "$d"
check "STOP → RUN removed" test ! -e "$d/.autopilot/RUN"

d="$(newrepo)"; touch "$d/.autopilot/RUN"; echo "garbage" > "$d/.autopilot/.hook-state"
check "blocks even with a corrupt state file" blocks "$d"
check "AUTOPILOT_STALL_LIMIT=1 releases right away" bash -c "cd '$TMPROOT' && ! AUTOPILOT_STALL_LIMIT=1 CLAUDE_PROJECT_DIR='$d' bash '$HOOK' | grep -q block"

# only the session that owns RUN is blocked
d="$(newrepo)"; printf 'session: owner-1\nstarted: 2026-01-01T00:00:00Z\n' > "$d/.autopilot/RUN"
check "owning session → block" bash -c "$(declare -f hook_as); TMPROOT='$TMPROOT' HOOK='$HOOK'; hook_as '$d' owner-1 | grep -q block"
check_not "another session in the same repository → not blocked" bash -c "$(declare -f hook_as); TMPROOT='$TMPROOT' HOOK='$HOOK'; hook_as '$d' other-2 | grep -q block"
check "another session leaves RUN in place" test -f "$d/.autopilot/RUN"
d="$(newrepo)"; touch "$d/.autopilot/RUN"
check "legacy RUN without an owner → blocks any session (old behavior)" bash -c "$(declare -f hook_as); TMPROOT='$TMPROOT' HOOK='$HOOK'; hook_as '$d' anyone | grep -q block"
d="$(newrepo)"; printf 'session: owner-1\n' > "$d/.autopilot/RUN"
check "no session ID on stdin → blocks (cannot tell sessions apart)" bash -c "cd '$TMPROOT' && CLAUDE_PROJECT_DIR='$d' bash '$HOOK' </dev/null | grep -q block"

finish
