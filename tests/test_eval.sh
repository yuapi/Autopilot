#!/usr/bin/env bash
# Tests for scripts/eval.sh (the grader and the plumbing; a fake claude stands in for the model)
. "$(dirname "$0")/lib.sh"
EV="$REPO/scripts/eval.sh"
FAKE="$TMPROOT/fake-claude"
cat > "$FAKE" <<'SH'
#!/usr/bin/env bash
# Writes a BACKLOG like a discovery pass would; FAKE_ROWS picks which seeded defects it "finds"
mkdir -p .autopilot
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"
  echo "|---|---|---|---|---|---|---|---|"
  case "${FAKE_ROWS:-all}" in *all*|*a*) echo "| T-001 | fix | done | 1 | done <n> is off by one and marks the wrong item | test_done passes | baseline | |";; esac
  case "${FAKE_ROWS:-all}" in *all*|*b*) echo "| T-002 | fix | open | 0 | list crashes when todos.json does not exist | no traceback | using it | |";; esac
  case "${FAKE_ROWS:-all}" in *all*|*c*) echo "| T-003 | security | open | 0 | add passes text to os.system (shell injection) | uses subprocess list | security | |";; esac
  case "${FAKE_ROWS:-all}" in *all*|*d*) echo "| T-004 | feature | open | 0 | implement the remove command the README documents | test for remove | missing | |";; esac
  case "${FAKE_ROWS:-all}" in *all*|*e*) echo "| T-005 | todo | open | 0 | support due dates | test | marker | |";; esac
  echo "| T-006 | docs | open | 0 | unrelated row | x | x | |"
} > .autopilot/BACKLOG.md
echo "AUTOPILOT_DRIVER=$AUTOPILOT_DRIVER" > .autopilot/env
git add -A >/dev/null 2>&1 && git commit -qm "autopilot(T-001): fix" >/dev/null 2>&1
SH
chmod +x "$FAKE"

out="$(CLAUDE_BIN="$FAKE" bash "$EV" 2>&1)"; rc=$?
check "all five seeded defects found → exit 0" test "$rc" -eq 0
check "score 5/5" grep -q "Score: 5/5" <<<"$out"
check "counts the commit made by the run" grep -q "Commits after the fixture: 1" <<<"$out"

out="$(FAKE_ROWS=ab CLAUDE_BIN="$FAKE" bash "$EV" 2>&1)"; rc=$?
check "two of five → below the default threshold → exit 1" test "$rc" -eq 1
check "names what was missed" grep -q "MISSED  shell" <<<"$out"
check "AUTOPILOT_EVAL_THRESHOLD lowers the bar" bash -c "FAKE_ROWS=ab AUTOPILOT_EVAL_THRESHOLD=0.4 CLAUDE_BIN='$FAKE' bash '$EV' >/dev/null 2>&1"
check_not "the status column alone does not count as a find" bash -c "FAKE_ROWS=x CLAUDE_BIN='$FAKE' bash '$EV' 2>&1 | grep -q 'found   off-by-one'"

out="$(CLAUDE_BIN="$FAKE" bash "$EV" --keep 2>&1)"
kept="$(sed -n 's/^\[eval\] kept the run in \([^ ]*\).*/\1/p' <<<"$out")"
check "--keep leaves the run for inspection" test -f "$kept/.autopilot/BACKLOG.md"
check "the run gets AUTOPILOT_DRIVER=1" grep -qx "AUTOPILOT_DRIVER=1" "$kept/.autopilot/env"
check "the fixture's failing test is the starting point" bash -c "cd '$kept' && git show HEAD~1:test_todo.py | grep -q test_done_marks_the_numbered_item"
rm -rf "$kept"

check "no claude CLI → skipped with exit 3" bash -c "CLAUDE_BIN=no-such-claude bash '$EV' >/dev/null 2>&1; test \$? -eq 3"
check_not "rejects an unknown option" bash "$EV" --bogus

# second fixture: a repository with no tests, graded on what the run completed first
FAKE2="$TMPROOT/fake-claude-2"
cat > "$FAKE2" <<'SH'
#!/usr/bin/env bash
mkdir -p .autopilot
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"
  echo "|---|---|---|---|---|---|---|---|"
  echo "| T-001 | ${FIRST_TYPE:-test} | done | 1 | set up node --test with a smoke test | npm test passes | no tests | |"
  echo "| T-002 | fix | open | 0 | empty input prints 1 instead of 0 | test for empty input | using it | |"
} > .autopilot/BACKLOG.md
SH
chmod +x "$FAKE2"
check "--fixture list shows both fixtures" bash -c "bash '$EV' --fixture list | grep -qx wordcount && bash '$EV' --fixture list | grep -qx todo"
out="$(CLAUDE_BIN="$FAKE2" bash "$EV" --fixture wordcount 2>&1)"; rc=$?
check "wordcount: harness first → 3/3" grep -q "Score: 3/3" <<<"$out"
check "wordcount: copies the right fixture" grep -q "fixture wordcount" <<<"$out"
out="$(FIRST_TYPE=fix CLAUDE_BIN="$FAKE2" bash "$EV" --fixture wordcount 2>&1)"
check "wordcount: fixing first instead of the harness is graded as a miss" grep -q "MISSED  harness-first" <<<"$out"
check_not "an unknown fixture is refused" bash "$EV" --fixture nope

# --iterations: later runs are graded too
FAKE3="$TMPROOT/fake-claude-3"
cat > "$FAKE3" <<'SH'
#!/usr/bin/env bash
mkdir -p .autopilot
n=$(( $(cat .autopilot/n 2>/dev/null || echo 0) + 1 )); echo "$n" > .autopilot/n
id="T-00$n"; [ -n "${SAME_ID:-}" ] && id=T-001
status=done; [ "$n" = "${FAIL_AT:-0}" ] && status=failed
[ -f .autopilot/LOG.md ] || echo "# LOG" > .autopilot/LOG.md
printf '\n## 2026-01-01T00:0%s | %s | %s | skill 1.0.0\n- x\n' "$n" "$id" "$status" >> .autopilot/LOG.md
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"
  echo "|---|---|---|---|---|---|---|---|"
  echo "| T-001 | fix | done | 1 | done <n> is off by one | test_done passes | baseline | |"
  echo "| T-002 | fix | open | 0 | list crashes when todos.json does not exist | x | x | |"
  echo "| T-003 | security | open | 0 | os.system shell injection | x | x | |"
  echo "| T-004 | feature | open | 0 | implement remove | x | x | |"
  echo "| T-005 | todo | open | 0 | due dates | x | x | |"
} > .autopilot/BACKLOG.md
SH
chmod +x "$FAKE3"
out="$(CLAUDE_BIN="$FAKE3" bash "$EV" --iterations 3 2>&1)"; rc=$?
check "--iterations 3 runs the driver three times" grep -q "iteration 3 finished" <<<"$out"
check "three clean runs → 8/8 with the multi-run checks" grep -q "Score: 8/8" <<<"$out"
out="$(SAME_ID=1 CLAUDE_BIN="$FAKE3" bash "$EV" --iterations 2 2>&1)"
check "the same task completed twice is caught" grep -q "FAILED  no task completed twice" <<<"$out"
out="$(FAIL_AT=2 CLAUDE_BIN="$FAKE3" bash "$EV" --iterations 2 2>&1)"
check "a failed run is caught" grep -q "FAILED  no failed or blocked runs (1)" <<<"$out"
check "a failed run also misses 'every iteration completed a task'" grep -q "FAILED  every iteration completed a task (1/2)" <<<"$out"
out="$(CLAUDE_BIN="$FAKE3" bash "$EV" 2>&1)"
check_not "one iteration (default) adds no multi-run checks" grep -q "Multi-run checks" <<<"$out"
check_not "--iterations 0 is refused" bash "$EV" --iterations 0
check_not "--iterations abc is refused" bash "$EV" --iterations abc

finish
