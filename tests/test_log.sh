#!/usr/bin/env bash
# Tests for scripts/log.sh (appends LOG entries in time order)
. "$(dirname "$0")/lib.sh"
LG="$REPO/$SKILL_REL/scripts/log.sh"
subagents_off() { mkdir -p "$1/.autopilot"; printf 'subagents: off\n' > "$1/.autopilot/CONFIG.md"; }
ver="$(sed -n 's/^  version: //p' "$REPO/$SKILL_REL/SKILL.md")"
d="$(mktemp -d "$TMPROOT/l.XXXX")"; git -C "$d" init -q
subagents_off "$d"   # these tests are not about the Subagents line

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
subagents_off "$d"   # these tests are not about the Subagents line
printf -- '- one\n- two\n' | bash "$LG" T-001 done "$d" >/dev/null
check "CRLF LOG: every line ends in CRLF after appending" bash -c "! grep -qv \$'\\r\$' '$d/.autopilot/LOG.md'"
check "CRLF LOG: body lines kept" grep -q "^- two" "$d/.autopilot/LOG.md"

# the same moment gives the same time in any time zone
d="$(mktemp -d "$TMPROOT/z.XXXX")"; git -C "$d" init -q
subagents_off "$d"   # these tests are not about the Subagents line
a="$(echo '- x' | TZ=Asia/Seoul bash "$LG" - discover "$d" | cut -c4-20)"; b="$(echo '- y' | TZ=America/Los_Angeles bash "$LG" - discover "$d" | cut -c4-20)"
check "Seoul and Los Angeles write the same UTC time" test "$a" = "$b"

# the skill version is read whether it is quoted or not (the account plugin sync writes '1.2.3')
for q in "" '"' "'"; do
  k="$(mktemp -d "$TMPROOT/k.XXXX")"; mkdir -p "$k/scripts" "$k/assets"; cp "$LG" "$k/scripts/"; cp "$REPO/$SKILL_REL/assets/LOG.md" "$k/assets/"
  printf -- "---\nname: autopilot\nmetadata:\n  version: %s9.8.7%s\n---\n" "$q" "$q" > "$k/SKILL.md"
  r="$(mktemp -d "$TMPROOT/r.XXXX")"; git -C "$r" init -q
  check "version read with quote [${q:-none}]" bash -c "echo '- x' | bash '$k/scripts/log.sh' - discover '$r' | grep -q 'skill 9.8.7\$'"
done

# a task entry must agree with the BACKLOG row (task.sh first, then log.sh)
d="$(mktemp -d "$TMPROOT/b.XXXX")"; mkdir -p "$d/.autopilot"
subagents_off "$d"   # these tests are not about the Subagents line
printf '| ID | Type | Status | Attempts | Task | Done when | Source | Completed |\r\n| T-001 | fix | in_progress | 1 | a | t | s | |\r\n| T-002 | fix | done | 1 | b | t | s | 2026-01-01 |\r\n| T-003 | fix | open | 1 | c | t | s | |\r\n| T-004 | fix | blocked | 3 | d | t | s | |\r\n' > "$d/.autopilot/BACKLOG.md"
printf '| T-010 | fix | done | 1 | old | t | s | 2026-01-01 |\n' > "$d/.autopilot/BACKLOG.archive.md"
err="$(echo "- x" | bash "$LG" T-001 done "$d" 2>&1 >/dev/null)"; rc=$?
check "done while in progress → refused" test "$rc" -ne 0
check "refusal says to run task.sh done first" grep -q "T-001 is in_progress in the BACKLOG, not done. Run task.sh done T-001 first" <<<"$err"
check_not "refused → nothing written" grep -q "| T-001 | done |" "$d/.autopilot/LOG.md"
check "unknown task ID → refused" bash -c "echo '- x' | bash '$LG' T-999 done '$d' 2>&1 | grep -q 'T-999 has no BACKLOG row'"
check "done task → done entry written" bash -c "echo '- x' | bash '$LG' T-002 done '$d' >/dev/null"
check "row in BACKLOG.archive.md counts" bash -c "echo '- x' | bash '$LG' T-010 done '$d' >/dev/null"
check "failed entry for an open task (CRLF BACKLOG)" bash -c "echo '- x' | bash '$LG' T-003 failed '$d' >/dev/null"
check "failed entry for a task blocked at the 3rd attempt" bash -c "echo '- x' | bash '$LG' T-004 failed '$d' >/dev/null"
check "blocked entry for a blocked task" bash -c "echo '- x' | bash '$LG' T-004 blocked '$d' >/dev/null"
check_not "blocked entry for an open task → refused" bash -c "echo '- x' | bash '$LG' T-003 blocked '$d' >/dev/null 2>&1"
check "'-' entries are not checked" bash -c "echo '- x' | bash '$LG' - discover '$d' >/dev/null"

# subagents on (the default): a done entry needs a "- Subagents:" line
d="$(mktemp -d "$TMPROOT/s.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"
err="$(echo "- Changed: a" | bash "$LG" T-001 done "$d" 2>&1 >/dev/null)"; rc=$?
check "subagents on, no Subagents line → refused" test "$rc" -ne 0
check "the refusal says which line to add" grep -q "needs a line '- Subagents: <how many>, <for what>'" <<<"$err"
check "with the line → written" bash -c "printf -- '- Changed: a\n- Subagents: 2, exploratory runs and the diff review\n' | bash '$LG' T-001 done '$d' >/dev/null"
check "other statuses need no Subagents line" bash -c "echo '- x' | bash '$LG' - discover '$d' >/dev/null"
printf 'subagents: off\r\n' > "$d/.autopilot/CONFIG.md"
check "subagents: off (CRLF CONFIG) → no Subagents line needed" bash -c "echo '- x' | bash '$LG' T-002 done '$d' >/dev/null"

# "none" in a repository over 20 files is refused, unless the session has no Agent tool
d="$(mktemp -d "$TMPROOT/sb.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"
for i in $(seq 1 21); do echo "$i" > "$d/f$i"; done; git -C "$d" add -A >/dev/null
err="$(printf -- '- x\n- Subagents: none, small repo\n' | bash "$LG" T-001 done "$d" 2>&1 >/dev/null)"; rc=$?
check "none with 21 tracked files → refused, count named" bash -c "test $rc -ne 0 && grep -q 'has 21 tracked files (over 20)' <<<\"\$1\"" _ "$err"
check "none, no Agent tool → written" bash -c "printf -- '- x\n- Subagents: none, no Agent tool in this session\n' | bash '$LG' T-001 done '$d' >/dev/null"
check "a count with 21 files → written" bash -c "printf -- '- x\n- Subagents: 2, exploratory runs and scenarios\n' | bash '$LG' T-002 done '$d' >/dev/null"
check "none, no discovery this task (21 files) → written" bash -c "printf -- '- x\n- Subagents: none, no discovery this task, diff 8 lines\n' | bash '$LG' T-003 done '$d' >/dev/null"
check "none, no \`Agent\` tool (backticks) → written" bash -c "printf -- '- x\n- Subagents: none, no \`Agent\` tool\n' | bash '$LG' T-004 done '$d' >/dev/null"
check "a lowercase subagents line counts" bash -c "printf -- '- x\n- subagents: 1, review\n' | bash '$LG' T-005 done '$d' >/dev/null"
printf 'scope: f1 f2\n' > "$d/.autopilot/CONFIG.md"
check "CONFIG scope limits the count (2 files) → none accepted" bash -c "printf -- '- x\n- Subagents: none, small (2 files)\n' | bash '$LG' T-006 done '$d' >/dev/null"

# scan.sh's "required" is remembered: "no discovery" is refused until a done entry records the subagents
SC="$REPO/$SKILL_REL/scripts/scan.sh"
d="$(mktemp -d "$TMPROOT/sm.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"
for i in $(seq 1 21); do echo "$i" > "$d/f$i"; done; git -C "$d" add -A >/dev/null
bash "$SC" "$d" >/dev/null
check "scan.sh over 20 files leaves .autopilot/.scan-required" test -f "$d/.autopilot/.scan-required"
err="$(printf -- '- x\n- Subagents: none, no discovery this task, diff 1 lines\n' | bash "$LG" T-001 done "$d" 2>&1 >/dev/null)"; rc=$?
check "no discovery while scan.sh asked for subagents → refused" bash -c "test $rc -ne 0 && grep -q 'scan.sh said this discovery cycle needs subagents' <<<\"\$1\"" _ "$err"
check "a recorded count → written, marker removed" bash -c "printf -- '- x\n- Subagents: 2, exploratory runs\n' | bash '$LG' T-001 done '$d' >/dev/null && test ! -e '$d/.autopilot/.scan-required'"
check "next task without discovery → no discovery accepted" bash -c "printf -- '- x\n- Subagents: none, no discovery this task, diff 3 lines\n' | bash '$LG' T-002 done '$d' >/dev/null"

# gaps closed: "- done" leaves the demand, outside git the demand still counts, "0" is "none"
d="$(mktemp -d "$TMPROOT/g.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"
for i in $(seq 1 21); do echo "$i" > "$d/f$i"; done; git -C "$d" add -A >/dev/null
printf '| ID | Type | Status | Attempts | Task | Done when | Source | Completed |\n| T-001 | fix | done | 1 | a | t | s | 2026-01-01 |\n' > "$d/.autopilot/BACKLOG.md"
bash "$SC" "$d" >/dev/null
echo "- x" | bash "$LG" - done "$d" >/dev/null 2>&1
check "a '- done' entry leaves scan.sh's demand in place" test -f "$d/.autopilot/.scan-required"
check_not "'- Subagents: 0' counts as none → refused" bash -c "printf -- '- x\n- Subagents: 0\n' | bash '$LG' T-001 done '$d' >/dev/null 2>&1"
check "'- Subagents: 10, …' is a count, not none" bash -c "printf -- '- x\n- Subagents: 10, scenarios\n' | bash '$LG' T-001 done '$d' >/dev/null"
n="$(mktemp -d "$TMPROOT/ng.XXXX")"; mkdir -p "$n/.autopilot"; for i in $(seq 1 25); do echo "$i" > "$n/f$i.txt"; done
bash "$SC" "$n" >/dev/null
check_not "outside git with scan.sh's demand open → none refused" bash -c "printf -- '- Subagents: none\n' | bash '$LG' T-001 done '$n' >/dev/null 2>&1"
printf "scope: it's\n" > "$d/.autopilot/CONFIG.md"
check "a quote in scope does not break the count" bash -c "! bash '$SC' '$d' 2>&1 >/dev/null | grep -q 'unmatched'"

finish
