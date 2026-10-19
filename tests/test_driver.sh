#!/usr/bin/env bash
# scripts/autopilot.sh (드라이버) 동작 테스트. 가짜 claude를 PATH에 둔다.
. "$(dirname "$0")/lib.sh"
DRIVER="$REPO/$SKILL_REL/scripts/autopilot.sh"
export AUTOPILOT_SLEEP=0

# 가짜 claude: 호출마다 calls 파일에 AUTOPILOT_DRIVER 값을 적고, FAKE_MODE에 따라 동작
FAKEBIN="$TMPROOT/fakebin"; mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/claude" <<'SH'
#!/usr/bin/env bash
echo "driver=${AUTOPILOT_DRIVER:-}" >> .autopilot/calls
n=$(wc -l < .autopilot/calls)
case "${FAKE_MODE:-ok}" in
  fail) exit 1;;
  stop2) [ "$n" -ge 2 ] && echo "최종 중단" > .autopilot/STOP; exit 0;;
  *) exit 0;;
esac
SH
chmod +x "$FAKEBIN/claude"

newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/r.XXXX")"
  (cd "$d" && git init -q && mkdir .autopilot && printf 'node_modules/' > .gitignore)
  echo "$d"
}
drive() { local dir="$1"; shift; (cd "$dir" && PATH="$FAKEBIN:$PATH" timeout 30 bash "$DRIVER" "$@"); }
calls() { wc -l < "$1/.autopilot/calls" | tr -d ' '; }

d="$(newrepo)"
FAKE_MODE=stop2 drive "$d" >/dev/null 2>&1; rc=$?
check "STOP 생성 시 종료 코드 0" test "$rc" -eq 0
check "STOP 생기면 더 호출하지 않음 (2회)" test "$(calls "$d")" -eq 2
check "AUTOPILOT_DRIVER=1 로 호출" grep -qx "driver=1" "$d/.autopilot/calls"
check "반복마다 로그 파일이 따로 남음" test "$(ls "$d/.autopilot/driver-logs" | wc -l)" -eq 2
check ".gitignore 마지막 줄 뒤에 줄바꿈 후 추가" grep -qx "node_modules/" "$d/.gitignore"
for ig in .autopilot/driver-logs/ .autopilot/STOP .autopilot/RUN .autopilot/.hook-state; do
  check ".gitignore에 $ig" grep -qxF "$ig" "$d/.gitignore"
done
rm -f "$d/.autopilot/STOP"; FAKE_MODE=ok drive "$d" 1 >/dev/null 2>&1
check ".gitignore 항목 중복 없음" test "$(grep -cxF .autopilot/STOP "$d/.gitignore")" -eq 1

d="$(newrepo)"
FAKE_MODE=ok drive "$d" 3 >/dev/null 2>&1; rc=$?
check "최대 반복 3 → 3회 호출" test "$(calls "$d")" -eq 3
check "최대 반복 도달 종료 코드 0" test "$rc" -eq 0

d="$(newrepo)"
FAKE_MODE=fail drive "$d" >/dev/null 2>&1; rc=$?
check "연속 크래시 3회 → 종료 코드 1" test "$rc" -eq 1
check "연속 크래시 3회에서 멈춤" test "$(calls "$d")" -eq 3

d="$(newrepo)"
out="$(drive "$d" abc 2>&1)"; rc=$?
check "숫자 아닌 반복 인자 → 종료 코드 1" test "$rc" -eq 1
check "숫자 아닌 반복 인자 → claude 호출 안 함" test ! -e "$d/.autopilot/calls"
check "음수 반복 인자 거부" bash -c "cd '$d' && ! PATH='$FAKEBIN:$PATH' bash '$DRIVER' -1 >/dev/null 2>&1"

d="$(newrepo)"
out="$(cd "$d" && PATH="/usr/bin:/bin" bash "$DRIVER" 1 2>&1)"; rc=$?
check "claude 없음 → 종료 코드 1" test "$rc" -eq 1
check "claude 없음 → 안내 메시지" grep -q "claude CLI" <<<"$out"

d="$(newrepo)"; mkdir -p "$d/sub/dir"
FAKE_MODE=ok drive "$d/sub/dir" 1 >/dev/null 2>&1; rc=$?
check "하위 폴더에서 실행 → 레포 루트 기준 동작" test -f "$d/.autopilot/calls"
check "하위 폴더에 산출물 안 생김" test ! -e "$d/sub/dir/.autopilot"

d="$(mktemp -d "$TMPROOT/nogit.XXXX")"
check_not "git 레포 밖 → 실패" drive "$d" 1

finish
