#!/usr/bin/env bash
# Discovery quality eval: run the working-copy skill once in driver mode on a fixture repository with
# seeded defects, then score how many of them landed in its BACKLOG.
#   bash scripts/eval.sh [--fixture <name>] [--iterations <n>] [--keep] [--timeout <seconds>]
# --iterations runs the driver n times (default 1) and also checks the later runs: each completes one
# task, no task is completed twice, nothing failed. --timeout applies to each run.
# Fixtures live in tests/eval/fixture-<name>/ with expectations in tests/eval/fixture-<name>.expected
# (default: todo). `--fixture list` prints the available ones.
# Needs the claude CLI and spends real model usage (one driver run). Not part of validate.sh.
# Exit codes: 0 score >= AUTOPILOT_EVAL_THRESHOLD (default 0.6) · 1 below it · 3 skipped (no claude CLI)
# CLAUDE_BIN overrides the claude command (the tests use a fake).
set -u
cd "$(dirname "$0")/.."
REPO="$(pwd)"
keep=0; timeout_s=1200; fixture=todo; iterations=1
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) keep=1;;
    --timeout) shift; timeout_s="${1:?--timeout needs seconds}";;
    --fixture) shift; fixture="${1:?--fixture needs a name}";;
    --iterations) shift; iterations="${1:?--iterations needs a number}";;
    *) echo "usage: eval.sh [--fixture <name>] [--iterations <n>] [--keep] [--timeout <seconds>]" >&2; exit 1;;
  esac
  shift
done
case "$iterations" in ''|*[!0-9]*|0) echo "[eval] --iterations must be a positive integer" >&2; exit 1;; esac
if [ "$fixture" = list ]; then
  for f in tests/eval/fixture-*/; do f="${f%/}"; echo "${f#tests/eval/fixture-}"; done; exit 0
fi
FIXTURE_DIR="tests/eval/fixture-$fixture"; EXPECTED="tests/eval/fixture-$fixture.expected"
[ -d "$FIXTURE_DIR" ] && [ -f "$EXPECTED" ] || { echo "[eval] unknown fixture: $fixture (see --fixture list)" >&2; exit 1; }
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
  echo "[eval] skipped: no claude CLI on PATH" >&2
  exit 3
fi

SKILL="$REPO/plugins/autopilot/skills/autopilot"
work="$(mktemp -d)"; log="$(mktemp)"   # the log stays outside the repository under test
[ "$keep" -eq 1 ] || trap 'rm -rf "$work" "$log"' EXIT
cp -R "$FIXTURE_DIR/." "$work/"
rm -rf "$work/__pycache__" "$work/node_modules"   # left behind when someone ran the fixture in place
(cd "$work" && git init -q -b main && git config user.email eval@example.invalid && git config user.name eval \
  && git add -A && git commit -qm "fixture")

prompt="Read $SKILL/SKILL.md and follow its procedure exactly, in driver mode (AUTOPILOT_DRIVER=1 is set): do exactly one task in this repository, then exit. <skill folder> in the rules means $SKILL. Do not ask questions."
echo "[eval] fixture $fixture: running $iterations driver iteration(s) in $work (timeout ${timeout_s}s each)…"
start_all=$(date +%s)
for it in $(seq 1 "$iterations"); do
  [ -f "$work/.autopilot/STOP" ] && { echo "[eval] STOP appeared, no more iterations"; break; }
  start=$(date +%s)
  ( cd "$work" && AUTOPILOT_DRIVER=1 "$CLAUDE_BIN" -p "$prompt" \
      --allowedTools "Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,TodoWrite" --add-dir "$SKILL" ) \
    >> "$log" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ $(( $(date +%s) - start )) -ge "$timeout_s" ]; then kill "$pid" 2>/dev/null; echo "[eval] iteration $it timed out" >&2; break; fi
    sleep 2
  done
  wait "$pid" 2>/dev/null
  echo "[eval] iteration $it finished in $(( $(date +%s) - start ))s"
done
echo "[eval] all iterations finished in $(( $(date +%s) - start_all ))s"

python3 - "$work" "$REPO/$EXPECTED" "${AUTOPILOT_EVAL_THRESHOLD:-0.6}" "$iterations" <<'PY'
import os, re, subprocess, sys
work, expected, threshold, iterations = sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4])
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
for ident, what, rx in items:
    rx = rx.strip()
    if rx.startswith("type="):
        hit = bool(completed) and completed[0] == rx[5:]
    else:
        hit = re.search(rx, text, re.I)
    found += bool(hit)
    print(f"  {'found  ' if hit else 'MISSED '} {ident.strip():12} {what.strip()}")
total = len(items)
if iterations > 1:
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
    print(f"Multi-run checks ({iterations} iterations):")
    for what, ok in checks:
        found += ok; total += 1
        print(f"  {'ok     ' if ok else 'FAILED '} {what}")
log = subprocess.run(["git", "-C", work, "log", "--oneline"], capture_output=True, text=True).stdout.splitlines()
print(f"Commits after the fixture: {len(log) - 1}")
score = found / total if total else 0
print(f"Score: {found}/{total} = {score:.2f} (threshold {threshold:.2f})")
sys.exit(0 if score >= threshold else 1)
PY
rc=$?
[ "$keep" -eq 1 ] && echo "[eval] kept the run in $work (claude output: $log)"
exit $rc
