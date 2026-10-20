#!/usr/bin/env bash
# Tests for scripts/log.sh (appends LOG entries in time order)
. "$(dirname "$0")/lib.sh"
LG="$REPO/$SKILL_REL/scripts/log.sh"
ver="$(sed -n 's/^  version: //p' "$REPO/$SKILL_REL/SKILL.md")"
d="$(mktemp -d "$TMPROOT/l.XXXX")"; git -C "$d" init -q

out="$(printf -- '- Changed: a\nVerified: b\n\n' | bash "$LG" T-042 done "$d")"
check "prints the header it wrote" grep -qE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}Z \| T-042 \| done \| skill $ver\$" <<<"$out"
check "creates LOG.md from the template" grep -q "append only" "$d/.autopilot/LOG.md"
check "body lines kept" grep -qx -- "- Changed: a" "$d/.autopilot/LOG.md"
check "a line without '- ' gets one" grep -qx -- "- Verified: b" "$d/.autopilot/LOG.md"
check "the time is the current UTC time" grep -q "$(date -u +%Y-%m-%dT%H)" "$d/.autopilot/LOG.md"
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
# done after a commit that covers several tasks → warning, entry still written
(cd "$d" && git config user.email t@t && git config user.name t && echo a > a && git add a && git commit -qm "autopilot(T-003,T-004): two" )
err="$(echo "- x" | bash "$LG" T-004 done "$d" 2>&1 >/dev/null)"
check "several task IDs in the last commit → warning" grep -q "covers several tasks" <<<"$err"
check "the entry is written anyway" grep -q "| T-004 | done |" "$d/.autopilot/LOG.md"
(cd "$d" && echo b > a && git commit -qam "autopilot(T-005): one")
check "one task ID → no warning" test -z "$(echo "- x" | bash "$LG" T-005 done "$d" 2>&1 >/dev/null)"
(cd "$d" && echo c > a && git commit -qam "autopilot(T-001..T-005): range")
check "a task ID range → warning" bash -c "echo '- x' | bash '$LG' T-005 done '$d' 2>&1 >/dev/null | grep -q 'covers several'"

# every status SKILL.md lists is accepted
for st in $(sed -n 's/^The third column (status) is one of \(.*\)\. "The last.*/\1/p' "$REPO/$SKILL_REL/SKILL.md" | tr -d '`/'); do
  check "status '$st' from SKILL.md is accepted" bash -c "echo '- x' | bash '$LG' - '$st' '$d' >/dev/null"
done
check "SKILL.md status list was found" test -n "$(sed -n 's/^The third column (status) is one of \(.*\)\. "The last.*/\1/p' "$REPO/$SKILL_REL/SKILL.md")"

# a CRLF LOG (Windows checkout) gets CRLF lines
d="$(mktemp -d "$TMPROOT/c.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"; printf '# LOG\r\n' > "$d/.autopilot/LOG.md"
printf -- '- one\n- two\n' | bash "$LG" T-001 done "$d" >/dev/null
check "CRLF LOG: every line ends in CRLF after appending" bash -c "! grep -qv \$'\\r\$' '$d/.autopilot/LOG.md'"
check "CRLF LOG: body lines kept" grep -q "^- two" "$d/.autopilot/LOG.md"

# the same moment gives the same time in any time zone
d="$(mktemp -d "$TMPROOT/z.XXXX")"; git -C "$d" init -q
a="$(echo '- x' | TZ=Asia/Seoul bash "$LG" - discover "$d" | cut -c4-20)"; b="$(echo '- y' | TZ=America/Los_Angeles bash "$LG" - discover "$d" | cut -c4-20)"
check "Seoul and Los Angeles write the same UTC time" test "$a" = "$b"

# the skill version is read whether it is quoted or not (the account plugin sync writes '1.2.3')
for q in "" '"' "'"; do
  k="$(mktemp -d "$TMPROOT/k.XXXX")"; mkdir -p "$k/scripts" "$k/assets"; cp "$LG" "$k/scripts/"; cp "$REPO/$SKILL_REL/assets/LOG.md" "$k/assets/"
  printf -- "---\nname: autopilot\nmetadata:\n  version: %s9.8.7%s\n---\n" "$q" "$q" > "$k/SKILL.md"
  r="$(mktemp -d "$TMPROOT/r.XXXX")"; git -C "$r" init -q
  check "version read with quote [${q:-none}]" bash -c "echo '- x' | bash '$k/scripts/log.sh' - discover '$r' | grep -q 'skill 9.8.7\$'"
done

finish
