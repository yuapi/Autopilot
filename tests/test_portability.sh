#!/usr/bin/env bash
# Repository scripts must work on a PATH without GNU-only tools (tac, timeout), like a default macOS
. "$(dirname "$0")/lib.sh"

# Link every executable on PATH except tac, timeout and gtimeout
NOGNU="$TMPROOT/nognu"; mkdir -p "$NOGNU"
IFS=: read -r -a dirs <<<"$PATH"
for dir in "${dirs[@]}"; do
  [ -d "$dir" ] || continue
  for f in "$dir"/*; do
    b="${f##*/}"
    case "$b" in tac|timeout|gtimeout) continue;; esac
    [ -x "$f" ] && [ ! -e "$NOGNU/$b" ] && ln -s "$f" "$NOGNU/$b"
  done
done
nognu() { PATH="$NOGNU" "$@"; }
check "setup: no tac" bash -c "! PATH='$NOGNU' command -v tac"
check "setup: no timeout" bash -c "! PATH='$NOGNU' command -v timeout"

# release --catch-up --dry-run (used tac before)
d="$(sandbox)"
(
  cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t
  git add -A && git commit -qm init
  git checkout -q -b release/x && bash scripts/bump.sh patch "r1" >/dev/null && git commit -qam r1
  git checkout -q main && git merge -q --no-ff -m "merge r1" release/x
) >/dev/null 2>&1
out="$(cd "$d" && nognu bash scripts/release.sh --catch-up --dry-run 2>&1)"
check "catch-up works without tac" grep -q "(dry-run) v.* ← " <<<"$out"
check_not "no tac error" grep -q "tac" <<<"$out"

# validate.sh's test time limit (used timeout before)
d="$(sandbox)"; mkdir -p "$d/tests"
printf '#!/usr/bin/env bash\necho "  ok   x"\n' > "$d/tests/test_zz.sh"
out="$(cd "$d" && env -u AUTOPILOT_IN_TESTS PATH="$NOGNU" AUTOPILOT_TEST_TIMEOUT=20 bash scripts/validate.sh 2>&1)"
check "validate runs tests without timeout" grep -q "tests/test_zz.sh (1 passed)" <<<"$out"
check_not "no timeout error" grep -q "timeout: command not found" <<<"$out"

# The perl fallback really enforces the time limit
start=$(date +%s)
PATH="$NOGNU" bash -c ". '$REPO/tests/lib.sh'; with_timeout 1 sleep 5" >/dev/null 2>&1
check "without timeout, perl fallback enforces the limit" test $(( $(date +%s) - start )) -lt 4

finish
