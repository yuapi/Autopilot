#!/usr/bin/env bash
# Discovery quality eval: run the working-copy skill once in driver mode on a fixture repository with
# seeded defects, then score how many of them landed in its BACKLOG.
#   bash scripts/eval.sh [--keep] [--timeout <seconds>]
# Needs the claude CLI and spends real model usage (one driver run). Not part of validate.sh.
# Exit codes: 0 score >= AUTOPILOT_EVAL_THRESHOLD (default 0.6) · 1 below it · 3 skipped (no claude CLI)
# CLAUDE_BIN overrides the claude command (the tests use a fake).
set -u
cd "$(dirname "$0")/.."
REPO="$(pwd)"
keep=0; timeout_s=1200
while [ $# -gt 0 ]; do
  case "$1" in
    --keep) keep=1;;
    --timeout) shift; timeout_s="${1:?--timeout needs seconds}";;
    *) echo "usage: eval.sh [--keep] [--timeout <seconds>]" >&2; exit 1;;
  esac
  shift
done
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
  echo "[eval] skipped: no claude CLI on PATH" >&2
  exit 3
fi

SKILL="$REPO/plugins/autopilot/skills/autopilot"
work="$(mktemp -d)"
[ "$keep" -eq 1 ] || trap 'rm -rf "$work"' EXIT
cp -R tests/eval/fixture-todo/. "$work/"
rm -rf "$work/__pycache__"   # left behind when someone ran the fixture tests in place
(cd "$work" && git init -q -b main && git config user.email eval@example.invalid && git config user.name eval \
  && git add -A && git commit -qm "fixture")

prompt="Read $SKILL/SKILL.md and follow its procedure exactly, in driver mode (AUTOPILOT_DRIVER=1 is set): do exactly one task in this repository, then exit. <skill folder> in the rules means $SKILL. Do not ask questions."
echo "[eval] running one driver iteration in $work (timeout ${timeout_s}s)…"
start=$(date +%s)
( cd "$work" && AUTOPILOT_DRIVER=1 "$CLAUDE_BIN" -p "$prompt" \
    --allowedTools "Bash,Read,Write,Edit,MultiEdit,Glob,Grep,LS,TodoWrite" --add-dir "$SKILL" ) \
  > "$work/.eval-claude.log" 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
  if [ $(( $(date +%s) - start )) -ge "$timeout_s" ]; then kill "$pid" 2>/dev/null; echo "[eval] timed out" >&2; break; fi
  sleep 2
done
wait "$pid" 2>/dev/null
echo "[eval] finished in $(( $(date +%s) - start ))s"

python3 - "$work" "$REPO/tests/eval/expected.txt" "${AUTOPILOT_EVAL_THRESHOLD:-0.6}" <<'PY'
import os, re, subprocess, sys
work, expected, threshold = sys.argv[1], sys.argv[2], float(sys.argv[3])
try:
    backlog = open(os.path.join(work, ".autopilot", "BACKLOG.md"), encoding="utf-8").read()
except FileNotFoundError:
    backlog = ""
rows = [l for l in backlog.splitlines() if re.match(r"^\|\s*T-\d+\s*\|", l)]
text = "\n".join(" | ".join(c.strip() for c in r.strip("|").split("|")[4:6]) for r in rows)
items = [l.split("|", 2) for l in open(expected, encoding="utf-8") if l.strip() and not l.startswith("#")]
found = 0
print(f"\nBACKLOG rows: {len(rows)}")
for ident, what, rx in items:
    hit = re.search(rx.strip(), text, re.I)
    found += bool(hit)
    print(f"  {'found  ' if hit else 'MISSED '} {ident.strip():12} {what.strip()}")
log = subprocess.run(["git", "-C", work, "log", "--oneline"], capture_output=True, text=True).stdout.splitlines()
print(f"Commits after the fixture: {len(log) - 1}")
score = found / len(items) if items else 0
print(f"Score: {found}/{len(items)} = {score:.2f} (threshold {threshold:.2f})")
sys.exit(0 if score >= threshold else 1)
PY
rc=$?
[ "$keep" -eq 1 ] && echo "[eval] kept the run in $work (claude output: $work/.eval-claude.log)"
exit $rc
