#!/usr/bin/env bash
# Tests for scripts/autopilot.sh (the driver). Puts a fake claude on PATH.
. "$(dirname "$0")/lib.sh"
DRIVER="$REPO/$SKILL_REL/scripts/autopilot.sh"
export AUTOPILOT_SLEEP=0

# Fake claude: records AUTOPILOT_DRIVER in the calls file on every call and acts on FAKE_MODE
FAKEBIN="$TMPROOT/fakebin"; mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/claude" <<'SH'
#!/usr/bin/env bash
echo "driver=${AUTOPILOT_DRIVER:-}" >> .autopilot/calls
n=$(wc -l < .autopilot/calls)
case "${FAKE_MODE:-ok}" in
  fail) exit 1;;
  stop2) [ "$n" -ge 2 ] && echo "final stop" > .autopilot/STOP; exit 0;;
  *) exit 0;;
esac
SH
chmod +x "$FAKEBIN/claude"

newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/r.XXXX")"
  (cd "$d" && git init -q && mkdir .autopilot && printf 'node_modules/' > .gitignore)
  echo "$d"
}
drive() { local dir="$1"; shift; (cd "$dir" && PATH="$FAKEBIN:$PATH" with_timeout 30 bash "$DRIVER" "$@"); }
calls() { wc -l < "$1/.autopilot/calls" | tr -d ' '; }

d="$(newrepo)"
FAKE_MODE=stop2 drive "$d" >/dev/null 2>&1; rc=$?
check "exit code 0 when STOP appears" test "$rc" -eq 0
check "no more calls after STOP (2 calls)" test "$(calls "$d")" -eq 2
check "calls with AUTOPILOT_DRIVER=1" grep -qx "driver=1" "$d/.autopilot/calls"
check "one log file per run" test "$(ls "$d/.autopilot/driver-logs" | wc -l)" -eq 2
check ".gitignore: newline added before appending" grep -qx "node_modules/" "$d/.gitignore"
for ig in .autopilot/driver-logs/ .autopilot/STOP .autopilot/RUN .autopilot/.hook-state; do
  check ".gitignore has $ig" grep -qxF "$ig" "$d/.gitignore"
done
rm -f "$d/.autopilot/STOP"; FAKE_MODE=ok drive "$d" 1 >/dev/null 2>&1
check ".gitignore entries not duplicated" test "$(grep -cxF .autopilot/STOP "$d/.gitignore")" -eq 1

d="$(newrepo)"
FAKE_MODE=ok drive "$d" 3 >/dev/null 2>&1; rc=$?
check "max runs 3 → 3 calls" test "$(calls "$d")" -eq 3
check "exit code 0 at max runs" test "$rc" -eq 0

d="$(newrepo)"
FAKE_MODE=fail drive "$d" >/dev/null 2>&1; rc=$?
check "3 consecutive crashes → exit code 1" test "$rc" -eq 1
check "stops after 3 consecutive crashes" test "$(calls "$d")" -eq 3

d="$(newrepo)"
out="$(drive "$d" abc 2>&1)"; rc=$?
check "non-numeric max runs → exit code 1" test "$rc" -eq 1
check "non-numeric max runs → claude not called" test ! -e "$d/.autopilot/calls"
check "negative max runs rejected" bash -c "cd '$d' && ! PATH='$FAKEBIN:$PATH' bash '$DRIVER' -1 >/dev/null 2>&1"

d="$(newrepo)"
out="$(cd "$d" && PATH="/usr/bin:/bin" bash "$DRIVER" 1 2>&1)"; rc=$?
check "no claude → exit code 1" test "$rc" -eq 1
check "no claude → helpful message" grep -q "claude CLI" <<<"$out"

d="$(newrepo)"; mkdir -p "$d/sub/dir"
FAKE_MODE=ok drive "$d/sub/dir" 1 >/dev/null 2>&1; rc=$?
check "run from a subfolder → works from the repository root" test -f "$d/.autopilot/calls"
check "no artifacts in the subfolder" test ! -e "$d/sub/dir/.autopilot"

d="$(mktemp -d "$TMPROOT/nogit.XXXX")"
check_not "outside a git repository → fails" drive "$d" 1

finish
