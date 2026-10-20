#!/usr/bin/env bash
# Tests for scripts/task.sh (BACKLOG transitions: one task at a time, one task per commit)
. "$(dirname "$0")/lib.sh"
TS="$REPO/$SKILL_REL/scripts/task.sh"
newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/t.XXXX")"
  (cd "$d" && git init -q && git config user.email t@t && git config user.name t && mkdir .autopilot
   { echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"; echo "|---|---|---|---|---|---|---|---|"
     echo "| T-001 | fix | open | 0 | first | t | s | |"; echo "| T-002 | fix | open | 2 | second | t | s | |"
     echo "| T-003 | fix | done | 1 | old | t | s | 2026-01-01 |"; } > .autopilot/BACKLOG.md
   echo base > code.txt && git add -A && git commit -qm init) >/dev/null
  echo "$d"
}
row() { grep "^| $2 " "$1/.autopilot/BACKLOG.md"; }
t() { (cd "$1" && shift && bash "$TS" "$@" 2>&1); }

d="$(newrepo)"
out="$(t "$d" start T-001)"; rc=$?
check "start → exit 0" test "$rc" -eq 0
check "start → in_progress, attempts 1" grep -q "| T-001 | fix | in_progress | 1 |" <<<"$(row "$d" T-001)"
check "start records the start commit" grep -q "^T-001 " "$d/.autopilot/.task"
check "start adds .autopilot/.task to .gitignore" grep -qx ".autopilot/.task" "$d/.gitignore"
check "other rows untouched" grep -q "| T-003 | fix | done | 1 | old | t | s | 2026-01-01 |" "$d/.autopilot/BACKLOG.md"
check "start of a second task while one is in progress → refused" grep -q "T-001 is still in progress" <<<"$(t "$d" start T-002)"
check "the refused task stays open" grep -q "| T-002 | fix | open | 2 |" <<<"$(row "$d" T-002)"
check "done without a commit → refused" grep -q "no commit since T-001 started" <<<"$(t "$d" done T-001)"
(cd "$d" && echo change >> code.txt)
check "done with uncommitted code → refused" grep -q "uncommitted changes outside .autopilot/" <<<"$(t "$d" done T-001)"
(cd "$d" && git commit -qam "autopilot(T-001): fix it")
out="$(t "$d" done T-001)"; rc=$?
check "done after its own commit → exit 0" test "$rc" -eq 0
check "done → status done with today's date" grep -q "| T-001 | fix | done | 1 | first | t | s | $(date +%Y-%m-%d) |" <<<"$(row "$d" T-001)"
check "done clears .autopilot/.task" test ! -e "$d/.autopilot/.task"

# one commit covering two tasks is refused at done
t "$d" start T-002 >/dev/null
(cd "$d" && echo more >> code.txt && git commit -qam "autopilot(T-002,T-004): two at once")
check "a commit naming another task → refused" grep -q "also name T-004" <<<"$(t "$d" done T-002)"
check "state-only commits do not count" bash -c "d=\$(mktemp -d '$TMPROOT/s.XXXX'); cd \$d && git init -q && git config user.email t@t && git config user.name t && mkdir .autopilot && printf '| T-009 | fix | open | 0 | x | t | s | |\n' > .autopilot/BACKLOG.md && git add -A && git commit -qm i && bash '$TS' start T-009 >/dev/null && git add -A && git commit -qm 'autopilot(T-009): state' && ! bash '$TS' done T-009 >/dev/null 2>&1"

# fail: back to open, blocked from the 3rd attempt
d="$(newrepo)"; t "$d" start T-002 >/dev/null
out="$(t "$d" fail T-002)"
check "3rd attempt failed → blocked" grep -q "| T-002 | fix | blocked | 3 |" <<<"$(row "$d" T-002)"
t "$d" start T-001 >/dev/null; t "$d" fail T-001 >/dev/null
check "1st attempt failed → open, attempts kept" grep -q "| T-001 | fix | open | 1 |" <<<"$(row "$d" T-001)"
check "fail clears .autopilot/.task" test ! -e "$d/.autopilot/.task"

d="$(newrepo)"; (cd "$d" && echo dirty >> code.txt)
check "start with uncommitted code → refused" grep -q "Commit or roll back the previous task first" <<<"$(t "$d" start T-001)"
check "refused start leaves the row open" grep -q "| T-001 | fix | open | 0 |" <<<"$(row "$d" T-001)"
check "start of a done task → refused" bash -c "cd '$(newrepo)' && ! bash '$TS' start T-003 >/dev/null 2>&1"
check "unknown task → refused" bash -c "cd '$(newrepo)' && bash '$TS' start T-099 2>&1 | grep -q 'no BACKLOG row T-099'"
check_not "bad arguments → exit 1" bash "$TS" begin T-001
check "done without start → refused" bash -c "cd '$(newrepo)' && bash '$TS' done T-001 2>&1 | grep -q 'was not started'"
# a refusal changes nothing, .gitignore included
d="$(newrepo)"; (cd "$d" && echo dirty >> code.txt)
before="$(cd "$d" && git status --porcelain; cat .gitignore 2>/dev/null)"
t "$d" start T-001 >/dev/null
check "refused start leaves .gitignore and the tree as they were" test "$(cd "$d" && git status --porcelain; cat .gitignore 2>/dev/null)" = "$before"
check "refused start writes no .autopilot/.task" test ! -e "$d/.autopilot/.task"

# drop: an unnecessary task is closed without a commit
d="$(newrepo)"; t "$d" start T-001 >/dev/null
out="$(t "$d" drop T-001)"; rc=$?
check "drop → exit 0" test "$rc" -eq 0
check "drop → blocked, attempts kept" grep -q "| T-001 | fix | blocked | 1 |" <<<"$(row "$d" T-001)"
check "drop clears .autopilot/.task" test ! -e "$d/.autopilot/.task"
check "drop of an open (not started) task works" bash -c "cd '$d' && bash '$TS' drop T-002 >/dev/null && grep -q '| T-002 | fix | blocked | 2 |' .autopilot/BACKLOG.md"
d="$(newrepo)"; t "$d" start T-001 >/dev/null; (cd "$d" && echo half >> code.txt)
check "drop with uncommitted code → refused" grep -q "A dropped task changes no code" <<<"$(t "$d" drop T-001)"
check "drop of a done task → refused" grep -q "T-003 is done" <<<"$(t "$(newrepo)" drop T-003)"

finish
