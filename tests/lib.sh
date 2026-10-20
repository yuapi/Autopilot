# Shared test helpers. Every test file sources this.
set -u
export AUTOPILOT_IN_TESTS=1
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_REL=plugins/autopilot/skills/autopilot
PASS=0; FAIL=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

ok()   { PASS=$((PASS + 1)); echo "  ok   $*"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL $*"; }
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$name"; else bad "$name"; fi; }
check_not() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then bad "$name"; else ok "$name"; fi; }

# Copy the repository working tree to a temp folder (without .git and dist)
sandbox() {
  local d; d="$(mktemp -d "$TMPROOT/sb.XXXX")"
  (cd "$REPO" && tar --exclude=.git --exclude=dist --exclude=.autopilot -cf - .) | (cd "$d" && tar -xf -)
  echo "$d"
}

# In-place sed that works with GNU and BSD: sedi [-E] '<expr>' <file>
sedi() {
  local f="${!#}" n=$(($# - 1))
  sed "${@:1:$n}" "$f" > "$f.sedi.tmp" && mv "$f.sedi.tmp" "$f"
}

# For environments without timeout (macOS default)
with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm shift; exec @ARGV or exit 127' "$secs" "$@"
  else "$@"
  fi
}

finish() {
  echo "  -- $PASS passed, $FAIL failed"
  [ "$FAIL" -eq 0 ]
}
