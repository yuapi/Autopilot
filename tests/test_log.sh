#!/usr/bin/env bash
# Tests for scripts/log.sh (appends LOG entries in time order)
. "$(dirname "$0")/lib.sh"
LG="$REPO/$SKILL_REL/scripts/log.sh"
ver="$(sed -n 's/^  version: //p' "$REPO/$SKILL_REL/SKILL.md")"
d="$(mktemp -d "$TMPROOT/l.XXXX")"; git -C "$d" init -q

out="$(printf -- '- Changed: a\nVerified: b\n\n' | bash "$LG" T-042 done "$d")"
check "prints the header it wrote" grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2} \| T-042 \| done \| skill $ver\$" <<<"$out"
check "creates LOG.md from the template" grep -q "append only" "$d/.autopilot/LOG.md"
check "body lines kept" grep -qx -- "- Changed: a" "$d/.autopilot/LOG.md"
check "a line without '- ' gets one" grep -qx -- "- Verified: b" "$d/.autopilot/LOG.md"
check "the time is the current time" grep -q "$(date +%Y-%m-%dT%H)" "$d/.autopilot/LOG.md"
printf '## 2099-01-01T00:00 | T-001 | done | skill 0\n- no newline at the end' >> "$d/.autopilot/LOG.md"
echo "- second" | bash "$LG" - discover "$d" >/dev/null
check "appends at the end, after every earlier entry" test "$(grep '^## ' "$d/.autopilot/LOG.md" | tail -1 | cut -d'|' -f2-3)" = " - | discover "
check "a file without a final newline is not glued to the new entry" grep -qx -- "- no newline at the end" "$d/.autopilot/LOG.md"
check "earlier entries untouched" grep -qx "## 2099-01-01T00:00 | T-001 | done | skill 0" "$d/.autopilot/LOG.md"
n="$(grep -c '^## ' "$d/.autopilot/LOG.md")"
check_not "empty body → exit 1" bash -c "bash '$LG' T-3 done '$d' </dev/null"
check_not "unknown status → exit 1" bash -c "echo x | bash '$LG' T-3 bogus '$d'"
check_not "bad task ID → exit 1" bash -c "echo x | bash '$LG' foo done '$d'"
check_not "task ID with letters → exit 1" bash -c "echo x | bash '$LG' T-3a done '$d'"
check "rejected calls write nothing" test "$(grep -c '^## ' "$d/.autopilot/LOG.md")" -eq "$n"
(cd "$d" && mkdir -p sub && cd sub && echo "- from a subfolder" | bash "$LG" T-7 failed >/dev/null)
check "works from a subfolder of the repository" grep -q "| T-7 | failed |" "$d/.autopilot/LOG.md"
check "status.sh reads what it writes" bash -c "bash '$REPO/$SKILL_REL/scripts/status.sh' '$d' | grep -q 'T-7  failed'"
finish
