#!/usr/bin/env bash
# Tests for scripts/eval.sh (the grader and the plumbing; a fake claude stands in for the model)
. "$(dirname "$0")/lib.sh"
EV="$REPO/scripts/eval.sh"
export AUTOPILOT_EVAL_POLL=0.1   # check the fake runs often so the tests stay fast
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
echo "$n" >> work.txt; git add -A >/dev/null 2>&1; git commit -qm "autopilot($id): run $n" >/dev/null 2>&1
SH
chmod +x "$FAKE3"
out="$(CLAUDE_BIN="$FAKE3" bash "$EV" --iterations 3 2>&1)"; rc=$?
check "--iterations 3 runs the driver three times" grep -qx "\[eval\] iteration 3" <<<"$out"
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

# --mode session: one session loaded as a plugin, STOP written once enough tasks are logged
FAKES="$TMPROOT/fake-claude-session"
cat > "$FAKES" <<'SH'
#!/usr/bin/env bash
# Session-mode stand-in: logs a task every half second until STOP appears (like the Stop hook keeps it going)
mkdir -p .autopilot; echo "args=$*" > .autopilot/args; echo "driver=${AUTOPILOT_DRIVER:-unset}" > .autopilot/env
touch .autopilot/RUN; sleep "${FAKE_FIRST_WAIT:-0.5}"   # no LOG yet: the watcher must cope
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"; echo "|---|---|---|---|---|---|---|---|"
  echo "| T-001 | fix | done | 1 | done <n> is off by one and marks the wrong item | t | baseline | |"; } > .autopilot/BACKLOG.md
budget="$(printf '%s' "$*" | sed -n 's/.* for \([0-9][0-9]*\) tasks.*/\1/p')"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  [ -f .autopilot/STOP ] && { [ -n "${FAKE_KEEP_RUN:-}" ] || rm -f .autopilot/RUN; exit 0; }
  if [ -z "${FAKE_IGNORE_BUDGET:-}" ] && [ -n "$budget" ] && [ "${logged:-0}" -ge "$budget" ]; then
    printf 'Stopped after %s task(s) as asked\n' "$budget" > .autopilot/STOP; continue
  fi
  if [ -z "${FAKE_HANG:-}" ]; then
    printf '\n## 2026-01-01T00:%02d | T-%03d | done | skill 0\n' "$i" "$i" >> .autopilot/LOG.md
    echo "$i" >> work.txt; git add -A >/dev/null 2>&1; git commit -qm "autopilot(T-$i): task" >/dev/null 2>&1
    logged=$(( ${logged:-0} + 1 ))
  fi
  sleep "${FAKE_STEP:-0.2}"
done
SH
chmod +x "$FAKES"
out="$(CLAUDE_BIN="$FAKES" bash "$EV" --mode session --iterations 2 --keep 2>&1)"
kept="$(sed -n 's/^\[eval\] kept the run in \([^ ]*\).*/\1/p' <<<"$out")"
check "session mode loads the working copy as a plugin" grep -q -- "--plugin-dir $REPO/plugins/autopilot" "$kept/.autopilot/args"
check "session mode allows the Skill tool (the Stop hook needs it)" grep -q "Skill" "$kept/.autopilot/args"
check "session mode does not set AUTOPILOT_DRIVER" grep -qx "driver=unset" "$kept/.autopilot/env"
check "no shell errors while the LOG does not exist yet" bash -c "! grep -q 'integer expression' <<<\"\$1\"" _ "$out"
check "the prompt asks for the task budget" grep -q "for 2 tasks" "$kept/.autopilot/args"
check "stopped on its own budget → ok" grep -q "ok      it ended on its task budget" <<<"$out"
check "the eval did not need to write STOP" bash -c "! grep -q 'wrote STOP' <<<\"\$1\"" _ "$out"
check "session ended on STOP → ok" grep -q "ok      the session ended after STOP, not on the timeout" <<<"$out"
check "RUN removed → ok" grep -q "ok      RUN removed when it ended" <<<"$out"
rm -rf "$kept"
out="$(FAKE_KEEP_RUN=1 CLAUDE_BIN="$FAKES" bash "$EV" --mode session --iterations 1 2>&1)"
check "RUN left behind → FAILED" grep -q "FAILED  RUN removed when it ended" <<<"$out"
out="$(FAKE_HANG=1 CLAUDE_BIN="$FAKES" bash "$EV" --mode session --iterations 1 --timeout 3 2>&1)"
check "no task before the timeout → FAILED" grep -q "FAILED  the session ended after STOP, not on the timeout" <<<"$out"
check_not "--mode bogus is refused" bash "$EV" --mode bogus

# rule checks, graded with --grade on hand-made runs
mkrun() {  # a kept-run look-alike: fixture commit plus the commits the test adds
  local d; d="$(mktemp -d "$TMPROOT/g.XXXX")"
  (cd "$d" && git init -q && git config user.email t@t && git config user.name t && echo f > f && git add -A && git commit -qm fixture
   mkdir .autopilot && printf '| T-001 | fix | done | 1 | done <n> is off by one | t | s | |\n' > .autopilot/BACKLOG.md) >/dev/null
  echo "$d"
}
task() {  # task <dir> <id> <time> [subject]: one code change, LOG entry appended, one commit
  (cd "$1" && echo "$2" >> code.txt && printf '\n## 2026-01-01T%s | %s | done | skill 0\n- x\n' "$3" "$2" >> .autopilot/LOG.md \
   && git add -A && git commit -qm "${4:-autopilot($2): task}") >/dev/null
}
grade() { bash "$EV" --grade "$1" 2>&1; }
d="$(mkrun)"; task "$d" T-001 10:00; task "$d" T-002 10:05
out="$(grade "$d")"
check "clean run → no broken rule" bash -c "! grep -q BROKEN <<<\"\$1\"" _ "$out"
check "--grade does not delete the graded run" test -d "$d/.git"
d="$(mkrun)"; (cd "$d" && echo a > code.txt && printf '\n## 2026-01-01T10:00 | T-001 | done | skill 0\n\n## 2026-01-01T10:01 | T-002 | done | skill 0\n' >> .autopilot/LOG.md && git add -A && git commit -qm "autopilot(T-001..T-002): both") >/dev/null
out="$(grade "$d")"; rc=$?
check "two tasks in one commit → BROKEN" grep -q "BROKEN  one commit per completed task" <<<"$out"
check "a broken rule fails the eval even with a full score" test "$rc" -eq 1
d="$(mkrun)"; task "$d" T-001 10:00; task "$d" T-002 10:05; (cd "$d" && sed -i.bak '/T-001/d' .autopilot/LOG.md && rm .autopilot/LOG.md.bak && git commit -qam "autopilot: tidy log") >/dev/null
check "LOG lines removed in a commit → BROKEN" grep -q "BROKEN  LOG entries only appended (lines removed in" <<<"$(grade "$d")"
d="$(mkrun)"; task "$d" T-001 10:05; task "$d" T-002 10:00
check "LOG entries out of time order → BROKEN" grep -q "BROKEN  LOG entries in time order (1 entries" <<<"$(grade "$d")"
d="$(mkrun)"; task "$d" T-001 10:00; echo "Final stop: no substantive work left" > "$d/.autopilot/STOP"
printf '## Deep discovery\n(placeholder)\n\n## Features in progress\n' > "$d/.autopilot/ROADMAP.md"
check "final stop without deep discovery → BROKEN" grep -q "BROKEN  final stop only after" <<<"$(grade "$d")"
printf '## Deep discovery\n- 1 static: 0. 2 running: 0. 3 quality: 0. 4 external: 0\n\n## Features in progress\n' > "$d/.autopilot/ROADMAP.md"
check "final stop with all four stages recorded → ok" grep -q "ok      final stop only after" <<<"$(grade "$d")"
echo "Final stop: no progress" > "$d/.autopilot/STOP"; printf '' > "$d/.autopilot/ROADMAP.md"
check "the Stop hook's no-progress stop is not a final stop" grep -q "ok      final stop only after.*(no final stop)" <<<"$(grade "$d")"
check_not "--grade on a non-run → exit 1" bash "$EV" --grade "$TMPROOT/nope"

# wordings real runs used for the seeded defects are graded as found (todo fixture)
match() { python3 -c 'import re,sys; rx=[l for l in open(sys.argv[1]) if l.startswith(sys.argv[2]+" |")][0].split("|",2)[2].strip(); sys.exit(0 if re.search(rx, sys.argv[3], re.I) else 1)' "$REPO/tests/eval/fixture-todo.expected" "$1" "$2"; }
check "off-by-one: 'done N should mark item N (1-based)'" match off-by-one "done N should mark item N (1-based) and report bad numbers cleanly"
check "missing-db: 'list crashes when DB missing'" match missing-db "list crashes when DB missing"
check "missing-db: 'list works without a DB'" match missing-db "list works without a DB"
check_not "off-by-one does not match the remove task" match off-by-one "implement remove per README, update usage"

# stats fixture: commit= expectations grade the repository's commit convention
FAKE4="$TMPROOT/fake-claude-4"
cat > "$FAKE4" <<'SH'
#!/usr/bin/env bash
mkdir -p .autopilot
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"; echo "|---|---|---|---|---|---|---|---|"
  echo "| T-001 | fix | done | 1 | median of an even-length list is wrong | test_median_even passes | baseline | |"
  echo "| T-002 | fix | open | 0 | no numbers: README says exit 1, code exits 2 | test | README | |"; } > .autopilot/BACKLOG.md
echo x >> stats.py; git add -A >/dev/null 2>&1; git commit -qm "${FAKE_SUBJECT:-fix: average the middle pair in median}" >/dev/null 2>&1
SH
chmod +x "$FAKE4"
out="$(CLAUDE_BIN="$FAKE4" bash "$EV" --fixture stats 2>&1)"
check "stats: conventional commit → found" grep -q "found   conventional" <<<"$out"
check "stats: 3/3" grep -q "Score: 3/3" <<<"$out"
out="$(FAKE_SUBJECT="autopilot(T-001): fix median" CLAUDE_BIN="$FAKE4" bash "$EV" --fixture stats 2>&1)"
check "stats: a commit ignoring CONTRIBUTING → missed, with the subject" grep -q "MISSED  conventional .*autopilot(T-001): fix median" <<<"$out"
check "stats fixture listed" grep -qx stats <<<"$(bash "$EV" --fixture list)"
check "stats fixture starts with a failing test" bash -c "cd '$REPO/tests/eval/fixture-stats' && ! python3 -B -m unittest >/dev/null 2>&1"

d="$(mkrun)"; task "$d" T-001 10:00; (cd "$d" && echo "| T-002 | fix | open | 0 | x | t | s | |" >> .autopilot/BACKLOG.md && git add -A && git commit -qm "chore: record T-001 and queue T-002") >/dev/null
check "a state-only commit naming two tasks is not a broken rule" grep -q "ok      one commit per completed task" <<<"$(grade "$d")"

# --model is passed to claude
out="$(CLAUDE_BIN="$FAKES" bash "$EV" --mode session --iterations 1 --model some-model --keep 2>&1)"
kept="$(sed -n 's/^\[eval\] kept the run in \([^ ]*\).*/\1/p' <<<"$out")"
check "--model reaches claude" grep -q -- "--model some-model" "$kept/.autopilot/args"
rm -rf "$kept"

# kv fixture (Go): the seeded state is what the expectations describe
if command -v go >/dev/null 2>&1; then
  k="$(mktemp -d "$TMPROOT/kv.XXXX")"; cp -R "$REPO/tests/eval/fixture-kv/." "$k/"
  check "kv: go test fails at the start" bash -c "cd '$k' && ! go test ./... >/dev/null 2>&1"
  check "kv: go vet reports unreachable code" bash -c "cd '$k' && go vet ./... 2>&1 | grep -q unreachable"
else
  echo "  skip kv fixture checks (no go)"
fi
check "kv fixture listed" grep -qx kv <<<"$(bash "$EV" --fixture list)"

out="$(FAKE_IGNORE_BUDGET=1 CLAUDE_BIN="$FAKES" bash "$EV" --mode session --iterations 2 2>&1)"
check "budget ignored → the eval writes STOP after n+1 tasks" grep -q "3 task(s) in the LOG → wrote STOP" <<<"$out"
check "budget ignored → FAILED" grep -q "FAILED  it ended on its task budget" <<<"$out"

# --fixture all: every fixture with the same options, one summary
out="$(CLAUDE_BIN="$FAKE" bash "$EV" --fixture all 2>&1)"; rc=$?
for f in $(bash "$EV" --fixture list); do
  check "--fixture all runs $f" grep -q "^=== fixture $f\$" <<<"$out"
  check "--fixture all summarizes $f" grep -qE "^  $f +Score:" <<<"$out"
done
check "--fixture all fails when one fixture fails" test "$rc" -eq 1
check "no claude → --fixture all is skipped (exit 3)" bash -c "CLAUDE_BIN=no-such-claude bash '$EV' --fixture all >/dev/null 2>&1; test \$? -eq 3"
check_not "--fixture all with --grade is refused" bash "$EV" --fixture all --grade /tmp

# mono fixture: nofile= fails when a commit touches a path outside CONFIG scope
FAKE5="$TMPROOT/fake-claude-5"
cat > "$FAKE5" <<'SH'
#!/usr/bin/env bash
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"; echo "|---|---|---|---|---|---|---|---|"
  echo "| T-001 | fix | done | 1 | slug keeps punctuation | test_punctuation passes | baseline | |"; } > .autopilot/BACKLOG.md
echo "# fixed" >> pkg/a/slug.py; [ -z "${FAKE_TOUCH_B:-}" ] || echo "# also" >> pkg/b/clamp.py
git add -A >/dev/null 2>&1; git commit -qm "autopilot(T-001): fix slug" >/dev/null 2>&1
SH
chmod +x "$FAKE5"
out="$(CLAUDE_BIN="$FAKE5" bash "$EV" --fixture mono 2>&1)"
check "mono: staying inside the scope → found" grep -q "found   scope" <<<"$out"
check "mono: 2/2" grep -q "Score: 2/2" <<<"$out"
out="$(FAKE_TOUCH_B=1 CLAUDE_BIN="$FAKE5" bash "$EV" --fixture mono 2>&1)"
check "mono: a commit touching pkg/b → missed, file named" grep -q "MISSED  scope .*changed: pkg/b/clamp.py" <<<"$out"
check "mono fixture ships its CONFIG scope" grep -q "^scope: pkg/a" "$REPO/tests/eval/fixture-mono/.autopilot/CONFIG.md"

# cost and turns from the JSON result claude prints
FAKE6="$TMPROOT/fake-claude-6"
printf '#!/usr/bin/env bash\n"%s" "$@" >/dev/null\necho %s\n' "$FAKE3" "'{\"type\":\"result\",\"total_cost_usd\":0.25,\"num_turns\":7}'" > "$FAKE6"; chmod +x "$FAKE6"
out="$(CLAUDE_BIN="$FAKE6" bash "$EV" --iterations 2 2>&1)"
check "cost summed over runs" grep -q 'Cost: \$0.50 over 2 run(s), 14 turns' <<<"$out"
check "runs ask claude for JSON output" bash -c "CLAUDE_BIN='$FAKES' bash '$EV' --mode session --iterations 1 --keep 2>&1 | sed -n 's/^\[eval\] kept the run in \([^ ]*\).*/\1/p' | head -1 | xargs -I{} grep -q -- '--output-format json' {}/.autopilot/args"
out="$(CLAUDE_BIN="$FAKE3" bash "$EV" 2>&1)"
check "no JSON result → cost unknown" grep -q "Cost: unknown" <<<"$out"

# driver mode uses the real driver's prompt and allowlist, with the working copy as a plugin
out="$(CLAUDE_BIN="$FAKES" bash "$EV" --iterations 1 --keep 2>&1)"
kept="$(sed -n 's/^\[eval\] kept the run in \([^ ]*\).*/\1/p' <<<"$out" | head -1)"
real_prompt="$(sed -n "s/^PROMPT='\(.*\)'\$/\1/p" "$REPO/$SKILL_REL/scripts/autopilot.sh")"
check "driver eval sends autopilot.sh's PROMPT" grep -qF -- "$real_prompt" "$kept/.autopilot/args"
check "driver eval loads the working copy as a plugin" grep -q -- "--plugin-dir $REPO/plugins/autopilot" "$kept/.autopilot/args"
check "driver eval uses the driver's allowlist (with Skill)" grep -q -- "--allowedTools Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,Skill,TodoWrite" "$kept/.autopilot/args"
rm -rf "$kept"

# watch fixture: roadmap= grades what the run recorded (a one-shot test command)
FAKE7="$TMPROOT/fake-claude-7"
cat > "$FAKE7" <<'SH'
#!/usr/bin/env bash
mkdir -p .autopilot
{ echo "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |"; echo "|---|---|---|---|---|---|---|---|"
  echo "| T-001 | fix | done | 1 | repeated spaces give several dashes | test passes | baseline | |"; } > .autopilot/BACKLOG.md
printf '## Maintenance status\n%s\n' "${FAKE_BASELINE:-Tests: node --test (npm test runs --watch and never exits)}" > .autopilot/ROADMAP.md
echo x >> slugify.js; git add -A >/dev/null 2>&1; git commit -qm "autopilot(T-001): x" >/dev/null 2>&1
SH
chmod +x "$FAKE7"
out="$(CLAUDE_BIN="$FAKE7" bash "$EV" --fixture watch 2>&1)"
check "watch: one-shot command recorded → found" grep -q "found   one-shot" <<<"$out"
out="$(FAKE_BASELINE='Tests: npm test' CLAUDE_BIN="$FAKE7" bash "$EV" --fixture watch 2>&1)"
check "watch: only npm test recorded → missed" grep -q "MISSED  one-shot" <<<"$out"
check "watch fixture's npm test is watch mode" grep -q '"test": "node --test --watch"' "$REPO/tests/eval/fixture-watch/package.json"

finish
