#!/usr/bin/env bash
# Tests for scripts/hook.sh install (installs and refreshes the Stop hook copy)
. "$(dirname "$0")/lib.sh"
HI="$REPO/$SKILL_REL/scripts/hook.sh"
ASSET="$REPO/$SKILL_REL/assets/autopilot-stop.sh"
ST="$REPO/$SKILL_REL/scripts/status.sh"
newrepo() { local d; d="$(mktemp -d "$TMPROOT/h.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"; echo "$d"; }
cmd_of() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print([h["command"] for g in d["hooks"]["Stop"] for h in g["hooks"]])' "$1"; }

d="$(newrepo)"
out="$(bash "$HI" install "$d")"
check "fresh repo → hook installed" grep -q "hook script: installed; settings.json: added" <<<"$out"
check "hook copy equals the asset" cmp -s "$ASSET" "$d/.claude/hooks/autopilot-stop.sh"
check "hook copy is executable" test -x "$d/.claude/hooks/autopilot-stop.sh"
check "settings.json uses \$CLAUDE_PROJECT_DIR" grep -q 'CLAUDE_PROJECT_DIR/.claude/hooks/autopilot-stop.sh' "$d/.claude/settings.json"
out="$(bash "$HI" install "$d")"
check "second run → nothing to do" grep -q "hook script: up to date; settings.json: ok" <<<"$out"
check "second run does not duplicate the entry" test "$(grep -c autopilot-stop.sh "$d/.claude/settings.json")" -eq 1

# a copy from 1.6.0 (has the RUN check, no owner check) gets replaced and stops trapping other sessions
d="$(newrepo)"; mkdir -p "$d/.claude/hooks"
git -C "$REPO" show 74a78ea:plugins/autopilot/skills/autopilot/assets/autopilot-stop.sh > "$d/.claude/hooks/autopilot-stop.sh" 2>/dev/null \
  || printf '#!/usr/bin/env bash\n[ -f .autopilot/RUN ] || exit 0\necho "{\\"decision\\":\\"block\\"}"\n' > "$d/.claude/hooks/autopilot-stop.sh"
printf 'session: owner\n' > "$d/.autopilot/RUN"
check "setup: the old copy traps another session" bash -c "cd '$TMPROOT' && echo '{\"session_id\":\"other\"}' | CLAUDE_PROJECT_DIR='$d' bash '$d/.claude/hooks/autopilot-stop.sh' | grep -q block"
check "status.sh notes the outdated copy" bash -c "bash '$ST' '$d' | grep -q 'copy from another skill version'"
out="$(bash "$HI" install "$d")"
check "old copy → updated" grep -q "hook script: updated" <<<"$out"
check_not "after the update another session is not trapped" bash -c "cd '$TMPROOT' && echo '{\"session_id\":\"other\"}' | CLAUDE_PROJECT_DIR='$d' bash '$d/.claude/hooks/autopilot-stop.sh' | grep -q block"
check_not "status.sh is quiet once the copy matches" bash -c "bash '$ST' '$d' | grep -q 'copy from another skill version'"

# existing settings are merged, not replaced; an old relative command is rewritten
d="$(newrepo)"; mkdir -p "$d/.claude"
cat > "$d/.claude/settings.json" <<'JSON'
{"permissions":{"allow":["Bash(ls:*)"]},"hooks":{"Stop":[{"hooks":[{"type":"command","command":"bash .claude/hooks/other.sh"}]},{"hooks":[{"type":"command","command":"bash .claude/hooks/autopilot-stop.sh"}]}],"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo pre"}]}]}}
JSON
out="$(bash "$HI" install "$d")"
check "old relative command → settings updated" grep -q "settings.json: updated" <<<"$out"
check "other Stop hooks kept" grep -q "other.sh" "$d/.claude/settings.json"
check "other hook events kept" grep -q "PreToolUse" "$d/.claude/settings.json"
check "other settings kept" grep -q 'Bash(ls:\*)' "$d/.claude/settings.json"
check "the autopilot entry now uses \$CLAUDE_PROJECT_DIR" bash -c "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print([h[\"command\"] for g in d[\"hooks\"][\"Stop\"] for h in g[\"hooks\"]])' '$d/.claude/settings.json' | grep -q 'CLAUDE_PROJECT_DIR'"
check "still exactly one autopilot entry" test "$(grep -c autopilot-stop.sh "$d/.claude/settings.json")" -eq 1

d="$(newrepo)"; mkdir -p "$d/.claude"; printf '{ not json' > "$d/.claude/settings.json"
check_not "invalid settings.json → exit 1" bash "$HI" install "$d"
check "invalid settings.json is left alone" grep -qx '{ not json' "$d/.claude/settings.json"

check_not "rejects an unknown command" bash "$HI" remove "$d"
check_not "fails outside a git repository" bash "$HI" install "$(mktemp -d "$TMPROOT/n.XXXX")"
d="$(newrepo)"; mkdir -p "$d/sub"
bash "$HI" install "$d/sub" >/dev/null
check "works from a subfolder (installs at the root)" test -f "$d/.claude/hooks/autopilot-stop.sh"

finish
