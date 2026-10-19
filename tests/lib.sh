# 테스트 공용 함수. 각 테스트 파일이 source 한다.
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

# 레포 작업 트리를 임시 폴더로 복사 (.git, dist 제외)
sandbox() {
  local d; d="$(mktemp -d "$TMPROOT/sb.XXXX")"
  (cd "$REPO" && tar --exclude=.git --exclude=dist --exclude=.autopilot -cf - .) | (cd "$d" && tar -xf -)
  echo "$d"
}

# GNU/BSD 공통 sed 제자리 편집: sedi [-E] '<식>' <파일>
sedi() {
  local f="${!#}" n=$(($# - 1))
  sed "${@:1:$n}" "$f" > "$f.sedi.tmp" && mv "$f.sedi.tmp" "$f"
}

# timeout이 없는 환경(macOS 기본)용
with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm shift; exec @ARGV or exit 127' "$secs" "$@"
  else "$@"
  fi
}

finish() {
  echo "  -- $PASS 통과, $FAIL 실패"
  [ "$FAIL" -eq 0 ]
}
