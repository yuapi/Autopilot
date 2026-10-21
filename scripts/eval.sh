#!/usr/bin/env bash
# Discovery quality eval: run the working-copy skill on a fixture repository with seeded defects,
# then score how many of them landed in its BACKLOG.
#   bash scripts/eval.sh [--fixture <name>] [--iterations <n>] [--mode driver|session] [--keep] [--timeout <seconds>]
# --iterations runs the driver n times (default 1) and also checks the later runs: each completes one
# task, no task is completed twice, nothing failed. --timeout applies to each run (each task in session mode).
# --mode session loads the working copy as a plugin (--plugin-dir) and runs one session in session mode,
# Stop hook included, asking for <n> tasks: the run should stop itself on that task budget. If the LOG
# reaches n+1 task entries the eval writes STOP itself (and that check fails); it also checks that the
# session then ended on its own (the hook let go) rather than on the timeout.
# Fixtures live in tests/eval/fixture-<name>/ with expectations in tests/eval/fixture-<name>.expected
# (default: todo). `--fixture list` prints the available ones; `--fixture all` runs every fixture with the
# same options and prints one summary (exit 1 if any fails). An expectation regex starting with type=
# grades the first completed task's type; one starting with commit= must match every commit subject;
# one starting with nofile= must match no file any commit changed (for CONFIG scope); one starting with
# roadmap= is matched against the ROADMAP the run wrote (e.g. the recorded baseline commands).
# Needs the claude CLI and spends real model usage (one driver run). Not part of validate.sh.
# Rule checks (one commit per task, LOG only appended, deep discovery before a final stop) are reported
# separately; any broken rule fails the eval whatever the score.
# Exit codes: 0 score >= AUTOPILOT_EVAL_THRESHOLD (default 0.6) and no broken rule · 1 otherwise · 3 skipped (no claude CLI)
# --model <name> runs the eval with that model (claude --model) to compare models; every run prints the
# cost and turns claude reported (--output-format json).
# --grade <dir> grades a run kept with --keep again without running anything (pass the same --fixture,
# --iterations and --mode).
# CLAUDE_BIN overrides the claude command (the tests use a fake).
set -u
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
cd "$(dirname "$0")/.."
REPO="$(pwd)"
keep=0; timeout_s=1200; fixture=todo; iterations=1; mode=driver; grade=""; model=""
all_args=("$@")
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) keep=1;;
    --timeout) shift; timeout_s="${1:?--timeout needs seconds}";;
    --fixture) shift; fixture="${1:?--fixture needs a name}";;
    --iterations) shift; iterations="${1:?--iterations needs a number}";;
    --mode) shift; mode="${1:?--mode needs driver or session}";;
    --grade) shift; grade="${1:?--grade needs a directory kept with --keep}";;
    --model) shift; model="${1:?--model needs a model name}";;
    *) echo "usage: eval.sh [--fixture <name>] [--iterations <n>] [--mode driver|session] [--model <name>] [--grade <dir>] [--keep] [--timeout <seconds>]" >&2; exit 1;;
  esac
  shift
done
case "$iterations" in ''|*[!0-9]*|0) echo "[eval] --iterations must be a positive integer" >&2; exit 1;; esac
case "$mode" in driver|session) ;; *) echo "[eval] --mode must be driver or session" >&2; exit 1;; esac
if [ "$fixture" = list ]; then
  for f in tests/eval/fixture-*/; do f="${f%/}"; echo "${f#tests/eval/fixture-}"; done; exit 0
fi
if [ "$fixture" = all ]; then   # every fixture with the same options, then one summary
  [ -z "$grade" ] || { echo "[eval] --grade takes one fixture, not all" >&2; exit 1; }
  rest=(); skip=0
  for a in ${all_args[@]+"${all_args[@]}"}; do
    if [ "$skip" = 1 ]; then skip=0; continue; fi
    if [ "$a" = --fixture ]; then skip=1; continue; fi
    rest+=("$a")
  done
  summary=(); rc_all=0
  for f in tests/eval/fixture-*/; do
    f="${f%/}"; f="${f#tests/eval/fixture-}"
    echo "=== fixture $f"
    out="$(bash "$0" --fixture "$f" ${rest[@]+"${rest[@]}"} 2>&1)"; rc=$?
    printf '%s\n' "$out"
    [ "$rc" -eq 3 ] && exit 3
    [ "$rc" -eq 0 ] || rc_all=1
    summary+=("$(printf '%-10s %s' "$f" "$(printf '%s\n' "$out" | grep '^Score:' | tail -1)")")
  done
  echo; echo "=== all fixtures"; printf '  %s\n' "${summary[@]}"
  exit "$rc_all"
fi
FIXTURE_DIR="tests/eval/fixture-$fixture"; EXPECTED="tests/eval/fixture-$fixture.expected"
[ -d "$FIXTURE_DIR" ] && [ -f "$EXPECTED" ] || { echo "[eval] unknown fixture: $fixture (see --fixture list)" >&2; exit 1; }
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
if [ -n "$grade" ]; then
  [ -d "$grade/.git" ] || { echo "[eval] --grade: not a kept run: $grade" >&2; exit 1; }
elif ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
  echo "[eval] skipped: no claude CLI on PATH" >&2
  exit 3
fi

SKILL="$REPO/plugins/autopilot/skills/autopilot"
timed_out=0
model_args=(); [ -z "$model" ] || model_args=(--model "$model")
if [ -n "$grade" ]; then
  work="$(cd "$grade" && pwd)"; keep=0
else
  work="$(mktemp -d)"; log="$(mktemp)"   # the log stays outside the repository under test
  [ "$keep" -eq 1 ] || trap 'rm -rf "$work" "$log"' EXIT
  cp -R "$FIXTURE_DIR/." "$work/"
  rm -rf "$work/__pycache__" "$work/node_modules"   # left behind when someone ran the fixture in place
  (cd "$work" && git init -q -b main && git config user.email eval@example.invalid && git config user.name eval \
    && git add -A && git commit -qm "fixture")

  tasks_logged() {  # prints a number even before the LOG exists
    [ -f "$work/.autopilot/LOG.md" ] || { echo 0; return; }
    grep -cE '^## [^|]+\| T-[0-9]+ \| (done|failed|blocked) \|' "$work/.autopilot/LOG.md" || true
  }
  # run_claude <timeout> <stop after n task entries, 0 = never> <command…>
  run_claude() {
    local limit="$1" stop_after="$2" start pid; shift 2
    start=$(date +%s)
    ( cd "$work" && "$@" ) >> "$log" 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      if [ $(( $(date +%s) - start )) -ge "$limit" ]; then kill "$pid" 2>/dev/null; timed_out=1; echo "[eval] timed out after ${limit}s" >&2; break; fi
      if [ "$stop_after" -gt 0 ] && [ ! -f "$work/.autopilot/STOP" ] && [ "$(tasks_logged)" -ge "$stop_after" ]; then
        echo "Eval: $stop_after task(s) logged" > "$work/.autopilot/STOP"
        echo "[eval] $stop_after task(s) in the LOG → wrote STOP, waiting for the session to end"
      fi
      sleep "${AUTOPILOT_EVAL_POLL:-2}"   # how often the run is checked (the tests use a short one)
    done
    wait "$pid" 2>/dev/null
    echo "[eval] finished in $(( $(date +%s) - start ))s"
  }

  start_all=$(date +%s)
  if [ "$mode" = session ]; then
    prompt="Run the autopilot skill (autopilot:autopilot) in this repository for $iterations tasks, with the Skill tool, in session mode. Do not ask questions."
    echo "[eval] fixture $fixture: one session-mode run asked for $iterations task(s), in $work (timeout $((timeout_s * iterations))s)…"
    # the run should stop itself on its task budget; the watcher only steps in one task later
    run_claude $((timeout_s * iterations)) "$((iterations + 1))" env -u AUTOPILOT_DRIVER "$CLAUDE_BIN" -p "$prompt" ${model_args[@]+"${model_args[@]}"} \
      --plugin-dir "$REPO/plugins/autopilot" --allowedTools "Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,TodoWrite,Skill" --output-format json
  else
    # the real driver's prompt and allowlist, with the working copy loaded as a plugin, so the eval
    # measures what autopilot.sh does (its own prompt once hid a driver-only bug)
    DRIVER_SH="$SKILL/scripts/autopilot.sh"
    prompt="$(sed -n "s/^PROMPT='\(.*\)'\$/\1/p" "$DRIVER_SH" | head -1)"
    tools="$(sed -n 's/.*PERM_ARGS=(--allowedTools "\([^"]*\)").*/\1/p' "$DRIVER_SH" | head -1)"
    [ -n "$prompt" ] && [ -n "$tools" ] || { echo "[eval] cannot read PROMPT and the allowlist from $DRIVER_SH" >&2; exit 1; }
    echo "[eval] fixture $fixture: running $iterations driver iteration(s) in $work (timeout ${timeout_s}s each)…"
    for it in $(seq 1 "$iterations"); do
      [ -f "$work/.autopilot/STOP" ] && { echo "[eval] STOP appeared, no more iterations"; break; }
      echo "[eval] iteration $it"
      run_claude "$timeout_s" 0 env AUTOPILOT_DRIVER=1 "$CLAUDE_BIN" -p "$prompt" ${model_args[@]+"${model_args[@]}"} \
        --plugin-dir "$REPO/plugins/autopilot" --allowedTools "$tools" --output-format json
    done
  fi
  echo "[eval] all runs finished in $(( $(date +%s) - start_all ))s"

fi

python3 - "$work" "$REPO/$EXPECTED" "${AUTOPILOT_EVAL_THRESHOLD:-0.6}" "$iterations" "$mode" "$timed_out" "${log:-}" <<'PY'
import os, re, subprocess, sys
work, expected, threshold, iterations = sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4])
mode, timed_out = sys.argv[5], sys.argv[6] == "1"
runlog_path = sys.argv[7] if len(sys.argv) > 7 else ""
def read_stop():
    try: return open(os.path.join(work, ".autopilot", "STOP"), encoding="utf-8").read()
    except FileNotFoundError: return ""
try:
    backlog = open(os.path.join(work, ".autopilot", "BACKLOG.md"), encoding="utf-8").read()
except FileNotFoundError:
    backlog = ""
rows = [l for l in backlog.splitlines() if re.match(r"^\|\s*T-\d+\s*\|", l)]
cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
text = "\n".join(" | ".join(c[4:6]) for c in cells)
completed = [c[1] for c in cells if len(c) > 2 and c[2] in ("done", "in_progress")]
items = [l.split("|", 2) for l in open(expected, encoding="utf-8") if l.strip() and not l.startswith("#")]
found = 0
print(f"\nBACKLOG rows: {len(rows)}")
git = lambda *a: subprocess.run(["git", "-C", work, *a], capture_output=True, text=True).stdout
commits = git("rev-list", "--reverse", "HEAD").split()[1:]   # everything after the fixture commit
subjects = [git("show", "-s", "--format=%s", c).strip() for c in commits]
for ident, what, rx in items:
    rx = rx.strip()
    if rx.startswith("roadmap="):
        try: roadmap = open(os.path.join(work, ".autopilot", "ROADMAP.md"), encoding="utf-8").read()
        except FileNotFoundError: roadmap = ""
        hit = re.search(rx[8:], roadmap, re.I)
    elif rx.startswith("nofile="):
        touched = sorted({f for c in commits for f in git("show", "--name-only", "--format=", c).split()})
        bad = [f for f in touched if re.search(rx[7:], f)]
        hit = not bad
        if bad:
            what = what.strip() + f" (changed: {', '.join(bad[:3])})"
    elif rx.startswith("commit="):
        bad = [x for x in subjects if not re.search(rx[7:], x)]
        hit = bool(subjects) and not bad
        if bad:
            what = what.strip() + f" (e.g. {bad[0]!r})"
    elif rx.startswith("type="):
        hit = bool(completed) and completed[0] == rx[5:]
    else:
        hit = re.search(rx, text, re.I)
    found += bool(hit)
    print(f"  {'found  ' if hit else 'MISSED '} {ident.strip():12} {what.strip()}")
total = len(items)
if iterations > 1 or mode == "session":
    try:
        runlog = open(os.path.join(work, ".autopilot", "LOG.md"), encoding="utf-8").read()
    except FileNotFoundError:
        runlog = ""
    heads = re.findall(r"^## \S+ \| ([^|]*?) \| (\w+) \|", runlog, re.M)
    done_ids = [h[0] for h in heads if h[1] == "done"]
    failed = [h[0] for h in heads if h[1] in ("failed", "blocked")]
    checks = [
        (f"every iteration completed a task ({len(done_ids)}/{iterations})", len(done_ids) >= iterations),
        ("no task completed twice", len(done_ids) == len(set(done_ids))),
        (f"no failed or blocked runs ({len(failed)})", not failed),
    ]
    if mode == "session":
        checks += [
            ("the session ended after STOP, not on the timeout", not timed_out),
            ("it ended on its task budget or a final stop (not on the eval's STOP)", bool(re.match(r"(Stopped after|Final stop|최종 정지)", read_stop()))),
            ("RUN removed when it ended", not os.path.exists(os.path.join(work, ".autopilot", "RUN"))),
        ]
    print(f"Multi-run checks ({iterations} {'task(s) in one session' if mode == 'session' else 'iterations'}):")
    for what, ok in checks:
        found += ok; total += 1
        print(f"  {'ok     ' if ok else 'FAILED '} {what}")
print(f"Commits after the fixture: {len(commits)}")
# cost and turns from claude -p --output-format json (one result object per run)
import json
results = []
if runlog_path and os.path.exists(runlog_path):
    for line in open(runlog_path, encoding="utf-8", errors="replace"):
        line = line.strip()
        if line.startswith("{") and '"total_cost_usd"' in line:
            try: results.append(json.loads(line))
            except ValueError: pass
if results:
    cost = sum(float(r.get("total_cost_usd") or 0) for r in results)
    turns = sum(int(r.get("num_turns") or 0) for r in results)
    print(f"Cost: ${cost:.2f} over {len(results)} run(s), {turns} turns")
elif runlog_path:
    print("Cost: unknown (no JSON result in the claude output)")

# Rule checks: the procedure's hard rules, graded on what the run left behind (not part of the score)
def read(p):
    try: return open(os.path.join(work, ".autopilot", p), encoding="utf-8").read()
    except FileNotFoundError: return ""
log_text = read("LOG.md")
done_tasks = sorted({i for i, st in re.findall(r"^## \S+ \| (T-\d+) \| (\w+) \|", log_text, re.M) if st == "done"})
code_commits, multi = 0, []
for c in commits:
    files = git("show", "--name-only", "--format=", c).split()
    if not any(not f.startswith(".autopilot/") and f != ".gitignore" for f in files):
        continue   # bookkeeping commits (state only) may name several tasks
    code_commits += 1
    subject = git("show", "-s", "--format=%s", c).strip()
    if len(set(re.findall(r"T-\d+", subject))) > 1 or re.search(r"T-\d+\s*(\.\.|–|-|~)\s*T?-?\d+", subject):
        multi.append(subject)
rewrites = []
for c in commits + ["WORKTREE"]:
    args = ["diff", "--numstat", "HEAD", "--"] if c == "WORKTREE" else ["diff", "--numstat", c + "^", c, "--"]
    stat = git(*args, ".autopilot/LOG.md", ".autopilot/LOG.archive.md")
    rows = dict((l.split("\t")[2], l.split("\t")[:2]) for l in stat.splitlines() if l.count("\t") == 2)
    log_del = rows.get(".autopilot/LOG.md", ["0", "0"])[1]
    if log_del not in ("0", "-") and ".autopilot/LOG.archive.md" not in rows:   # archive.sh moves entries out
        rewrites.append(f"{c[:7]} (-{log_del})")
dirty_end = [l[3:] for l in git("status", "--porcelain", "--untracked-files=all").splitlines()
             if l[3:] and not re.search(r"(^|/)(STOP|RUN|\.hook-state|\.task|driver-logs/|driver\.lock)", l[3:])]
times = re.findall(r"^## (\d{4}-\d\d-\d\dT\d\d:\d\d)", log_text, re.M)
out_of_order = [b for a, b in zip(times, times[1:]) if b < a]
stop = read("STOP")
final = bool(re.search(r"final stop|최종 정지", stop, re.I)) and not re.search(r"no progress|Eval:", stop)
deep_ok = True
if final:
    m = re.search(r"^##[^\n]*(Deep discovery|심화 발굴)[^\n]*\n(.*?)(?=^## |\Z)", read("ROADMAP.md"), re.M | re.S)
    body = "\n".join(l for l in (m.group(2) if m else "").splitlines() if not l.strip().startswith("("))
    deep_ok = all(re.search(k, body, re.I) for k in (r"static|정적", r"running|실행", r"quality|품질", r"external|외부"))
rules = [
    (f"one commit per completed task (commits with code changes {code_commits} >= done tasks {len(done_tasks)}" + (f"; several tasks in one commit: {multi[0]}" if multi else "") + ")",
     code_commits >= len(done_tasks) and not multi),
    ("LOG entries only appended" + (f" (lines removed in {', '.join(rewrites)})" if rewrites else ""), not rewrites),
    ("LOG entries in time order" + (f" ({len(out_of_order)} entries earlier than the one above)" if out_of_order else ""), not out_of_order),
    ("clean working tree at the end (state committed)" + (f" ({len(dirty_end)} uncommitted: {', '.join(dirty_end[:3])})" if dirty_end else ""), not dirty_end),
    ("final stop only after all four deep discovery stages are recorded" + ("" if final else " (no final stop)"), deep_ok),
]
print("Rule checks:")
for what, ok in rules:
    print(f"  {'ok     ' if ok else 'BROKEN '} {what}")
rules_ok = all(ok for _, ok in rules)
score = found / total if total else 0
print(f"Score: {found}/{total} = {score:.2f} (threshold {threshold:.2f})" + ("" if rules_ok else " — rule checks failed"))
sys.exit(0 if score >= threshold and rules_ok else 1)
PY
rc=$?
[ "$keep" -eq 1 ] && [ -z "$grade" ] && echo "[eval] kept the run in $work (claude output: $log)"
exit $rc
