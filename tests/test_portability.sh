#!/usr/bin/env bash
# macOS 기본 환경처럼 GNU 전용 도구(tac, timeout)가 없는 PATH에서 레포 스크립트가 동작하는지
. "$(dirname "$0")/lib.sh"

# PATH의 모든 실행 파일을 링크하되 tac·timeout·gtimeout은 뺀다
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
check "준비: tac 없음" bash -c "! PATH='$NOGNU' command -v tac"
check "준비: timeout 없음" bash -c "! PATH='$NOGNU' command -v timeout"

# release --catch-up --dry-run (tac 사용하던 곳)
d="$(sandbox)"
(
  cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t
  git add -A && git commit -qm init
  git checkout -q -b release/x && bash scripts/bump.sh patch "r1" >/dev/null && git commit -qam r1
  git checkout -q main && git merge -q --no-ff -m "merge r1" release/x
) >/dev/null 2>&1
out="$(cd "$d" && nognu bash scripts/release.sh --catch-up --dry-run 2>&1)"
check "tac 없이 catch-up 동작" grep -q "(dry-run) v.* ← " <<<"$out"
check_not "tac 오류 없음" grep -q "tac" <<<"$out"

# validate.sh의 테스트 시간 제한 (timeout 사용하던 곳)
d="$(sandbox)"; mkdir -p "$d/tests"
printf '#!/usr/bin/env bash\necho "  ok   x"\n' > "$d/tests/test_zz.sh"
out="$(cd "$d" && env -u AUTOPILOT_IN_TESTS PATH="$NOGNU" AUTOPILOT_TEST_TIMEOUT=20 bash scripts/validate.sh 2>&1)"
check "timeout 없이 validate의 테스트 실행" grep -q "tests/test_zz.sh (1 통과)" <<<"$out"
check_not "timeout 오류 없음" grep -q "timeout: command not found\|timeout: 명령" <<<"$out"

# perl 대체가 실제로 시간 제한을 거는지
start=$(date +%s)
PATH="$NOGNU" bash -c ". '$REPO/tests/lib.sh'; with_timeout 1 sleep 5" >/dev/null 2>&1
check "timeout 없을 때 perl 대체로 시간 제한" test $(( $(date +%s) - start )) -lt 4

finish
