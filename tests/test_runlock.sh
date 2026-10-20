#!/usr/bin/env bash
# Tests for scripts/runlock.sh (session-mode run marker with an owner)
. "$(dirname "$0")/lib.sh"
RL="$REPO/$SKILL_REL/scripts/runlock.sh"

newrepo() { local d; d="$(mktemp -d "$TMPROOT/l.XXXX")"; git -C "$d" init -q; mkdir "$d/.autopilot"; echo "$d"; }
as() { local sid="$1"; shift; CLAUDE_CODE_SESSION_ID="$sid" bash "$RL" "$@"; }
age() { python3 -c 'import os,sys,time; t=time.time()-int(sys.argv[2])*60; os.utime(sys.argv[1],(t,t))' "$1" "$2"; }

d="$(newrepo)"
check "start creates RUN" as A start "$d"
check "RUN records the owning session" grep -qx "session: A" "$d/.autopilot/RUN"
check "RUN records when it started" grep -qE '^started: [0-9]{4}-' "$d/.autopilot/RUN"
check "owner prints the session" test "$(as A owner "$d")" = A

as B start "$d" >/dev/null 2>&1; rc=$?
check "another session is refused with exit 2" test "$rc" -eq 2
check "refusal names the running session" bash -c "CLAUDE_CODE_SESSION_ID=B bash '$RL' start '$d' 2>&1 | grep -q 'session A'"
check "refusal leaves RUN with the owner" grep -qx "session: A" "$d/.autopilot/RUN"
check "the owner may start again (resume)" as A start "$d"

age "$d/.autopilot/RUN" 30; as B touch "$d"
check "touch by another session does not refresh RUN" test "$(python3 -c 'import os,sys,time; print(int((time.time()-os.path.getmtime(sys.argv[1]))//60))' "$d/.autopilot/RUN")" -ge 29
as A touch "$d"
check "touch by the owner refreshes RUN" test "$(python3 -c 'import os,sys,time; print(int((time.time()-os.path.getmtime(sys.argv[1]))//60))' "$d/.autopilot/RUN")" -lt 1

age "$d/.autopilot/RUN" 180
check "a marker idle for over 2 h is taken over" as B start "$d"
check "takeover writes the new owner" grep -qx "session: B" "$d/.autopilot/RUN"
age "$d/.autopilot/RUN" 30
check "AUTOPILOT_RUN_STALE_MIN shortens the takeover window" bash -c "AUTOPILOT_RUN_STALE_MIN=10 CLAUDE_CODE_SESSION_ID=C bash '$RL' start '$d'"

d="$(newrepo)"; printf 'legacy\n' > "$d/.autopilot/RUN"
check "a legacy RUN without an owner is taken over" as A start "$d"
check "takeover of a legacy RUN records the owner" grep -qx "session: A" "$d/.autopilot/RUN"

d="$(newrepo)"
check "without a session ID it still starts" bash -c "env -u CLAUDE_CODE_SESSION_ID bash '$RL' start '$d'"
check "an unknown owner never blocks a known session" as A start "$d"

d="$(newrepo)"; mkdir -p "$d/sub"
check "works from a subfolder" as A start "$d/sub"
check "RUN is written at the repository root" test -f "$d/.autopilot/RUN"
check_not "rejects an unknown command" as A bogus "$d"
check_not "fails outside a git repository" as A start "$(mktemp -d "$TMPROOT/n.XXXX")"

# stop: a person ends the loop
d="$(newrepo)"; as A start "$d"
out="$(as B stop "$d")"
check "stop writes STOP" grep -q "^Stopped by a person" "$d/.autopilot/STOP"
check "stop names the running session" grep -q "session A" <<<"$out"
out="$(as B stop "$d")"
check "stop twice says it is already stopped" grep -q "already stopped" <<<"$out"
d="$(newrepo)"
out="$(as A stop "$d")"
check "stop with no loop running says so" grep -q "No loop was running" <<<"$out"
d="$(mktemp -d "$TMPROOT/x.XXXX")"; git -C "$d" init -q
check "stop without .autopilot does nothing" bash -c "CLAUDE_CODE_SESSION_ID=A bash '$RL' stop '$d' | grep -q 'has not run' && test ! -e '$d/.autopilot'"

finish
