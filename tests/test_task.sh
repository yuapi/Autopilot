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

# a state-only commit naming other tasks (queueing follow-ups) does not block done
d="$(newrepo)"; t "$d" start T-001 >/dev/null
(cd "$d" && echo fix >> code.txt && git commit -qam "autopilot(T-001): fix" && echo "| T-004 | fix | open | 0 | follow-up | t | s | |" >> .autopilot/BACKLOG.md && git add -A && git commit -qm "chore: record T-001 and queue T-004")
check "state-only commit naming T-004 → done still accepted" bash -c "cd '$d' && bash '$TS' done T-001 >/dev/null"

# task budget: runlock.sh start --tasks 2 → STOP after the second done
RL="$REPO/$SKILL_REL/scripts/runlock.sh"
d="$(newrepo)"
out="$(cd "$d" && CLAUDE_CODE_SESSION_ID=s1 bash "$RL" start --tasks 2)"
check "runlock --tasks announces the budget" grep -q "stops after 2 completed task" <<<"$out"
check "RUN records the budget" bash -c "grep -qx 'tasks: 2' '$d/.autopilot/RUN' && grep -qx 'done: 0' '$d/.autopilot/RUN'"
check "RUN keeps its owner" grep -qx "session: s1" "$d/.autopilot/RUN"
for id in T-001 T-002; do
  t "$d" start $id >/dev/null; (cd "$d" && echo $id >> code.txt && git commit -qam "autopilot($id): x")
  out="$(t "$d" done $id)"
done
check "second done → budget used, STOP written" grep -q "task budget used (2/2)" <<<"$out"
check "STOP says why" grep -q "Stopped after 2 task(s) as asked" "$d/.autopilot/STOP"
check "RUN counts done tasks" grep -qx "done: 2" "$d/.autopilot/RUN"
d="$(newrepo)"; (cd "$d" && CLAUDE_CODE_SESSION_ID=s1 bash "$RL" start --tasks 3 >/dev/null)
t "$d" start T-001 >/dev/null; (cd "$d" && echo a >> code.txt && git commit -qam "autopilot(T-001): x")
check "1 of 3 → progress shown, no STOP" bash -c "cd '$d' && bash '$TS' done T-001 | grep -q 'task budget: 1/3 done' && test ! -e .autopilot/STOP"
check "status.sh shows the budget" bash -c "bash '$REPO/$SKILL_REL/scripts/status.sh' '$d' | grep -q '1/3 tasks of its budget done'"
d="$(newrepo)"; (cd "$d" && CLAUDE_CODE_SESSION_ID=s1 bash "$RL" start >/dev/null)
t "$d" start T-001 >/dev/null; (cd "$d" && echo a >> code.txt && git commit -qam "autopilot(T-001): x"); t "$d" done T-001 >/dev/null
check "no budget → done never writes STOP" test ! -e "$d/.autopilot/STOP"
check_not "runlock --tasks 0 → refused" bash -c "cd '$d' && bash '$RL' start --tasks 0"
check_not "runlock --tasks abc → refused" bash -c "cd '$d' && bash '$RL' start --tasks abc"
d="$(newrepo)"; (cd "$d" && CLAUDE_CODE_SESSION_ID=s1 bash "$RL" start --tasks 5 >/dev/null && CLAUDE_CODE_SESSION_ID=s1 bash "$RL" start >/dev/null)
check "re-entry without --tasks keeps the budget" grep -qx "tasks: 5" "$d/.autopilot/RUN"

# a malformed row (7 columns) is refused with the expected layout
d="$(newrepo)"; echo "| T-010 | fix | open | 0 | added by hand | t | s |" >> "$d/.autopilot/BACKLOG.md"
out="$(t "$d" start T-010)"
check "7-column row → refused with the column count" grep -q "T-010 has 7 columns, expected 8" <<<"$out"
check "the refusal shows the expected layout" grep -q "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |" <<<"$out"
check "the malformed row is left as it was" grep -qx "| T-010 | fix | open | 0 | added by hand | t | s |" "$d/.autopilot/BACKLOG.md"

# CONFIG scope: commits outside the scope are refused at done
d="$(newrepo)"; mkdir -p "$d/pkg/a" "$d/pkg/b"; printf 'scope: pkg/a   # one package\n' > "$d/.autopilot/CONFIG.md"
(cd "$d" && git add -A && git commit -qm "config" >/dev/null 2>&1 || true)
t "$d" start T-001 >/dev/null; (cd "$d" && echo x > pkg/a/f.txt && git add -A && git commit -qm "autopilot(T-001): in scope")
check "change inside the scope → done accepted" bash -c "cd '$d' && bash '$TS' done T-001 >/dev/null"
t "$d" start T-002 >/dev/null; (cd "$d" && echo y > pkg/b/g.txt && echo z >> code.txt && git add -A && git commit -qm "autopilot(T-002): outside")
out="$(t "$d" done T-002)"
check "change outside the scope → refused, files named" grep -q "changes outside scope (pkg/a) from .autopilot/CONFIG.md: code.txt pkg/b/g.txt" <<<"$out"
check "refused → still in progress" grep -q "| T-002 | fix | in_progress |" <<<"$(row "$d" T-002)"
d="$(newrepo)"; printf 'scope: .\n' > "$d/.autopilot/CONFIG.md"; (cd "$d" && git add -A && git commit -qm c >/dev/null)
t "$d" start T-001 >/dev/null; (cd "$d" && echo q >> code.txt && git commit -qam "autopilot(T-001): any")
check "scope . → whole repository allowed" bash -c "cd '$d' && bash '$TS' done T-001 >/dev/null"
d="$(newrepo)"; mkdir -p "$d/a" "$d/b"; printf 'scope: a b/\n' > "$d/.autopilot/CONFIG.md"; (cd "$d" && git add -A && git commit -qm c >/dev/null 2>&1 || true)
t "$d" start T-001 >/dev/null; (cd "$d" && echo 1 > a/x && echo 2 > b/y && git add -A && git commit -qm "autopilot(T-001): two paths")
check "several scope paths (trailing slash allowed)" bash -c "cd '$d' && bash '$TS' done T-001 >/dev/null"
check "status.sh shows the scope" bash -c "bash '$REPO/$SKILL_REL/scripts/status.sh' '$d' | grep -q 'scope=a'"

# a rename counts both paths: moving a file into the scope deletes it outside
d="$(newrepo)"; mkdir -p "$d/pkg" "$d/other"; printf 'scope: pkg\n' > "$d/.autopilot/CONFIG.md"
seq 1 40 > "$d/other/a.txt"; seq 1 40 > "$d/pkg/c.txt"; (cd "$d" && git add -A && git commit -qm c >/dev/null)
t "$d" start T-001 >/dev/null; (cd "$d" && git mv other/a.txt pkg/a.txt && git commit -qm "autopilot(T-001): move in")
out="$(t "$d" done T-001)"
check "rename from outside into the scope → refused, old path named" grep -q "changes outside scope (pkg) from .autopilot/CONFIG.md: other/a.txt" <<<"$out"
(cd "$d" && git reset -q --hard HEAD~1); t "$d" fail T-001 >/dev/null; t "$d" start T-001 >/dev/null
(cd "$d" && git mv pkg/c.txt pkg/d.txt && git commit -qm "autopilot(T-001): rename inside")
check "rename inside the scope → accepted" bash -c "cd '$d' && bash '$TS' done T-001 >/dev/null"

# a CRLF BACKLOG (Windows checkout) stays CRLF
d="$(newrepo)"; sedi 's/$/\r/' "$d/.autopilot/BACKLOG.md"; (cd "$d" && git commit -qam crlf)
t "$d" start T-001 >/dev/null
check "CRLF BACKLOG: every line still ends in CRLF after start" bash -c "! grep -qv \$'\\r\$' '$d/.autopilot/BACKLOG.md'"
check "CRLF BACKLOG: the row was updated" grep -q "| T-001 | fix | in_progress | 1 |" "$d/.autopilot/BACKLOG.md"

# a CONFIG saved with CRLF (Windows editor) still gives the right scope
d="$(newrepo)"; mkdir -p "$d/pkg/a"; printf 'scope: pkg/a\r\nintegration: local\r\n' > "$d/.autopilot/CONFIG.md"; (cd "$d" && git add -A && git commit -qm c >/dev/null)
t "$d" start T-001 >/dev/null; (cd "$d" && echo x > pkg/a/f && git add -A && git commit -qm "autopilot(T-001): in scope")
check "CRLF CONFIG: change inside the scope → accepted" bash -c "cd '$d' && bash '$TS' done T-001 >/dev/null"
t "$d" start T-002 >/dev/null; (cd "$d" && echo y >> code.txt && git commit -qam "autopilot(T-002): outside")
check "CRLF CONFIG: change outside → still refused" grep -q "changes outside scope (pkg/a)" <<<"$(t "$d" done T-002)"

# driver mode: no run marker, no task budget (the driver limits runs itself)
d="$(newrepo)"
out="$(cd "$d" && AUTOPILOT_DRIVER=1 CLAUDE_CODE_SESSION_ID=s bash "$RL" start --tasks 1)"
check "driver mode: runlock start writes no RUN" test ! -e "$d/.autopilot/RUN"
check "driver mode: runlock says why" grep -q "driver mode (AUTOPILOT_DRIVER=1): no run marker" <<<"$out"
printf 'session: s\ntasks: 1\ndone: 0\n' > "$d/.autopilot/RUN"
t "$d" start T-001 >/dev/null; (cd "$d" && echo a >> code.txt && git commit -qam "autopilot(T-001): x")
(cd "$d" && AUTOPILOT_DRIVER=1 bash "$TS" done T-001 >/dev/null)
check "driver mode: task.sh done never writes a budget STOP" test ! -e "$d/.autopilot/STOP"

# no CONFIG.md: done prints no shell error
d="$(newrepo)"; t "$d" start T-001 >/dev/null; (cd "$d" && echo a >> code.txt && git commit -qam "autopilot(T-001): x")
err="$(cd "$d" && bash "$TS" done T-001 2>&1 >/dev/null)"
check "no CONFIG.md → done prints nothing on stderr" test -z "$err"

finish
