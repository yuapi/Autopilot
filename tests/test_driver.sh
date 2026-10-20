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
  idle) exit 0;;
  *) printf '\n## 2026-01-01T00:00 | T-%03d | done | skill 0\n' "$n" >> .autopilot/LOG.md; exit 0;;
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
for ig in .autopilot/driver-logs/ .autopilot/STOP .autopilot/RUN .autopilot/.hook-state .autopilot/.task; do
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

# one loop per repository
d="$(newrepo)"; sleep 300 & live=$!; echo "$live" > "$d/.autopilot/driver.lock"
out="$(FAKE_MODE=ok drive "$d" 1 2>&1)"; rc=$?
kill "$live" 2>/dev/null; wait "$live" 2>/dev/null
check "another live driver → exit 1" test "$rc" -eq 1
check "another live driver → claude not called" test ! -e "$d/.autopilot/calls"
check "another live driver → says so" grep -q "another driver" <<<"$out"
d="$(newrepo)"; echo 999999 > "$d/.autopilot/driver.lock"
FAKE_MODE=ok drive "$d" 1 >/dev/null 2>&1
check "a stale driver.lock (dead pid) is ignored" test -f "$d/.autopilot/calls"
check "driver.lock removed on exit" test ! -e "$d/.autopilot/driver.lock"
check ".gitignore has .autopilot/driver.lock" grep -qxF .autopilot/driver.lock "$d/.gitignore"
d="$(newrepo)"; printf 'session: s1\n' > "$d/.autopilot/RUN"
out="$(FAKE_MODE=ok drive "$d" 1 2>&1)"; rc=$?
check "a live session-mode loop → exit 1" test "$rc" -eq 1
check "a live session-mode loop → says so" grep -q "session-mode autopilot loop" <<<"$out"
python3 -c 'import os,time; t=time.time()-3*3600; os.utime("'"$d"'/.autopilot/RUN",(t,t))'
FAKE_MODE=ok drive "$d" 1 >/dev/null 2>&1
check "an abandoned RUN (3 h idle) does not stop the driver" test -f "$d/.autopilot/calls"

# integration preflight
GHBIN="$TMPROOT/ghbin"; mkdir -p "$GHBIN"
printf '#!/usr/bin/env bash\n[ "$1" = api ] && echo "${FAKE_GH_PUSH:-true}"\n' > "$GHBIN/gh"; chmod +x "$GHBIN/gh"
cfg() { printf '```\nintegration: %s\n```\n' "$2" > "$1/.autopilot/CONFIG.md"; }
drive_gh() { local dir="$1"; shift; (cd "$dir" && PATH="$GHBIN:$FAKEBIN:$PATH" with_timeout 30 bash "$DRIVER" "$@"); }

d="$(newrepo)"; cfg "$d" pr; git -C "$d" remote add origin https://example.invalid/x.git
out="$(FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check "pr + gh with push access → confirms" grep -q "gh can open and merge PRs" <<<"$out"
out="$(FAKE_GH_PUSH=false FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check "pr + gh without push access → warns" grep -q "needs gh with push access" <<<"$out"
check "the warning does not stop the driver" test "$(calls "$d")" -eq 2

NOGH="$TMPROOT/nogh"; mkdir -p "$NOGH"
for tool in bash env git python3 sed head tail cat date mkdir rm printf sleep grep wc; do
  p="$(command -v "$tool")" && ln -sf "$p" "$NOGH/$tool"
done
ln -sf "$FAKEBIN/claude" "$NOGH/claude"
out="$(cd "$d" && PATH="$NOGH" FAKE_MODE=ok bash "$DRIVER" 1 2>&1)"
check "pr without gh installed → warns" grep -q "needs the gh CLI" <<<"$out"

# GitLab origin: preflight checks glab instead of gh
printf '#!/usr/bin/env bash\n[ "$1 $2" = "auth status" ] && exit "${FAKE_GLAB_AUTH:-0}"\n' > "$GHBIN/glab"; chmod +x "$GHBIN/glab"
d="$(newrepo)"; cfg "$d" pr; git -C "$d" remote add origin https://gitlab.com/x/y.git
out="$(FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check "pr + GitLab origin + glab logged in → confirms" grep -q "glab can open and merge merge requests" <<<"$out"
check_not "pr + GitLab origin → no gh message" grep -q "gh can open\|needs gh" <<<"$out"
out="$(FAKE_GLAB_AUTH=1 FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check "pr + GitLab origin + glab not logged in → warns" grep -q "needs glab logged in" <<<"$out"
out="$(cd "$d" && PATH="$NOGH" FAKE_MODE=ok bash "$DRIVER" 1 2>&1)"
check "pr + GitLab origin without glab → warns" grep -q "needs the glab CLI" <<<"$out"

d="$(newrepo)"; cfg "$d" branch
out="$(FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check "branch mode without origin → warns" grep -q "needs a remote named origin" <<<"$out"
d="$(newrepo)"; cfg "$d" prr
out="$(FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check "unknown integration value → warns" grep -q "unknown integration value" <<<"$out"
d="$(newrepo)"
out="$(FAKE_MODE=ok drive_gh "$d" 1 2>&1)"
check_not "local mode (no CONFIG) → no integration message" grep -q "integration" <<<"$out"

# no progress: runs that change neither LOG.md nor commits stop the driver
d="$(newrepo)"
out="$(FAKE_MODE=idle drive "$d" 2>&1)"; rc=$?
check "3 runs without progress → exit code 1" test "$rc" -eq 1
check "stops after 3 runs without progress" test "$(calls "$d")" -eq 3
check "no progress → STOP written with the reason" grep -q "no progress (driver)" "$d/.autopilot/STOP"
check "no progress is reported per run" grep -q "made no progress" <<<"$out"
d="$(newrepo)"
out="$(FAKE_MODE=idle AUTOPILOT_STALL_LIMIT=1 drive "$d" 2>&1)"
check "AUTOPILOT_STALL_LIMIT=1 stops after one idle run" test "$(calls "$d")" -eq 1
d="$(newrepo)"
out="$(FAKE_MODE=ok drive "$d" 2 2>&1)"
check "progress → the run's LOG entry is printed" grep -q "#2 → 2026-01-01T00:00 | T-002 | done" <<<"$out"
check "progress → no STOP" test ! -e "$d/.autopilot/STOP"

finish
