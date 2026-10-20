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

# the same stop seen by two hook copies (skill frontmatter + old repository copy) counts once
d="$(newrepo)"; printf 'session: s1\n' > "$d/.autopilot/RUN"; tr="$TMPROOT/transcript.jsonl"; echo '{}' > "$tr"
stop_as() { (cd "$TMPROOT" && printf '{"session_id":"s1","transcript_path":"%s"}' "$tr" | CLAUDE_PROJECT_DIR="$d" bash "$HOOK"); }
stop_as >/dev/null; stop_as >/dev/null
check "two copies on the same stop → counter not advanced twice" grep -q ' 0 ' "$d/.autopilot/.hook-state"
echo '{"next":1}' >> "$tr"; stop_as >/dev/null; stop_as >/dev/null
check "next stop (transcript grew) → counted once" grep -q ' 1 ' "$d/.autopilot/.hook-state"
echo '{"next":2}' >> "$tr"; stop_as >/dev/null
echo '{"next":3}' >> "$tr"
check_not "stall limit still applies with a transcript" bash -c "$(declare -f stop_as); TMPROOT='$TMPROOT' HOOK='$HOOK' d='$d' tr='$tr'; stop_as | grep -q block"

# the frontmatter hook command finds the asset for a plugin install and for a plain skill install
cmd="$(sed -n "s/^ *command: bash -c '\(.*\)'$/\1/p" "$REPO/$SKILL_REL/SKILL.md" | head -1)"
check "SKILL.md frontmatter declares a Stop hook command" test -n "$cmd"
for root in "$REPO/plugins/autopilot" "$REPO/$SKILL_REL"; do
  d="$(newrepo)"; touch "$d/.autopilot/RUN"
  check "frontmatter hook blocks with CLAUDE_PLUGIN_ROOT=${root#$REPO/}" bash -c "cd '$TMPROOT' && CLAUDE_PLUGIN_ROOT='$root' CLAUDE_PROJECT_DIR='$d' bash -c '$cmd' </dev/null | grep -q block"
done
d="$(newrepo)"
check_not "frontmatter hook without RUN → does not block" bash -c "cd '$TMPROOT' && CLAUDE_PLUGIN_ROOT='$REPO/plugins/autopilot' CLAUDE_PROJECT_DIR='$d' bash -c '$cmd' </dev/null | grep -q block"

# the block reason is valid JSON and points to finalstop.sh
d="$(newrepo)"; touch "$d/.autopilot/RUN"
check "block output is valid JSON" bash -c "cd '$TMPROOT' && CLAUDE_PROJECT_DIR='$d' bash '$HOOK' </dev/null | python3 -c 'import json,sys; json.load(sys.stdin)'"
check "block reason points to finalstop.sh" bash -c "cd '$TMPROOT' && CLAUDE_PROJECT_DIR='$d' bash '$HOOK' </dev/null | grep -q finalstop.sh"

finish
