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

finish
