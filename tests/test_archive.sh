#!/usr/bin/env bash
# scripts/archive.sh (상태 파일 정리) 테스트
. "$(dirname "$0")/lib.sh"
ARCH="$REPO/$SKILL_REL/scripts/archive.sh"

mk() {
  local d; d="$(mktemp -d "$TMPROOT/a.XXXX")"; mkdir "$d/.autopilot"
  python3 - "$d" "$1" "$2" <<'PY'
import sys
d, nb, nl = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
rows = []
for i in range(1, nb + 1):
    st = "blocked" if i % 7 == 0 else "done"
    rows.append(f"| T-{i:03d} | fix | {st} | 1 | 작업 {i} | 기준 | 출처 | 2026-01-01 |\n")
rows.append(f"| T-{nb+1:03d} | fix | open | 0 | 열린 작업 | 기준 | 출처 | |\n")
open(f"{d}/.autopilot/BACKLOG.md", "w").write("# BACKLOG\n\nnext_id: 1\n\n| ID | 유형 | 상태 | 시도 | 작업 | 완료 기준 | 출처 | 완료일 |\n|---|---|---|---|---|---|---|---|\n" + "".join(rows))
log = "# LOG\n" + "".join(f"\n## 2026-01-01T00:00 | T-{i:03d} | done | skill 1.0.0\n- 변경: a{i}\n" for i in range(1, nl + 1))
open(f"{d}/.autopilot/LOG.md", "w").write(log)
PY
  echo "$d"
}
rows() { grep -cE '^\| T-[0-9]+ \|' "$1" 2>/dev/null || echo 0; }
entries() { grep -c '^## ' "$1" 2>/dev/null || echo 0; }

d="$(mk 40 200)"; before="$(cat "$d/.autopilot/BACKLOG.md" "$d/.autopilot/LOG.md" | cksum)"
bash "$ARCH" "$d" >/dev/null
check "기준 이하면 아무것도 안 바뀜" test "$(cat "$d/.autopilot/BACKLOG.md" "$d/.autopilot/LOG.md" | cksum)" = "$before"
check "기준 이하면 아카이브 없음" test ! -e "$d/.autopilot/BACKLOG.archive.md"

d="$(mk 60 350)"
all_rows="$(grep -E '^\| T-' "$d/.autopilot/BACKLOG.md" | sort | cksum)"
all_log="$(sed -n '/^## /,$p' "$d/.autopilot/LOG.md" | cksum)"
bash "$ARCH" "$d" >/dev/null
check "BACKLOG 완료 행 30개 남김 + open 1개" test "$(rows "$d/.autopilot/BACKLOG.md")" -eq 31
check "BACKLOG 아카이브 30행" test "$(rows "$d/.autopilot/BACKLOG.archive.md")" -eq 30
check "오래된 것부터 이동 (T-001은 아카이브)" grep -q '^| T-001 ' "$d/.autopilot/BACKLOG.archive.md"
check "최근 것은 남음 (T-060)" grep -q '^| T-060 ' "$d/.autopilot/BACKLOG.md"
check "open 행은 남음" grep -q '| open |' "$d/.autopilot/BACKLOG.md"
check "BACKLOG 행 손실·변형 없음" test "$(cat "$d/.autopilot/BACKLOG.md" "$d/.autopilot/BACKLOG.archive.md" | grep -E '^\| T-' | sort | cksum)" = "$all_rows"
check "LOG 100개 남김" test "$(entries "$d/.autopilot/LOG.md")" -eq 100
check "LOG 아카이브 250개" test "$(entries "$d/.autopilot/LOG.archive.md")" -eq 250
check "LOG 머리말 유지" test "$(head -1 "$d/.autopilot/LOG.md")" = "# LOG"
check "LOG 항목 손실·변형 없음" test "$( { sed -n '/^## /,$p' "$d/.autopilot/LOG.archive.md"; sed -n '/^## /,$p' "$d/.autopilot/LOG.md"; } | cksum)" = "$all_log"

# 두 번째 실행: 아카이브에 이어 붙이고 머리말은 한 번만
python3 - "$d" <<'PY'
import sys
d=sys.argv[1]
with open(f"{d}/.autopilot/LOG.md","a") as f:
    f.write("".join(f"\n## 2026-02-01T00:00 | X-{i} | done | skill 1.0.0\n- x\n" for i in range(250)))
PY
bash "$ARCH" "$d" >/dev/null
check "재실행: LOG 100개 남김" test "$(entries "$d/.autopilot/LOG.md")" -eq 100
check "재실행: 아카이브에 이어 붙임 (500개)" test "$(entries "$d/.autopilot/LOG.archive.md")" -eq 500
check "재실행: 아카이브 머리말 1번" test "$(grep -c '^# LOG 아카이브' "$d/.autopilot/LOG.archive.md")" -eq 1

check_not ".autopilot 없으면 실패" bash "$ARCH" "$TMPROOT"

finish
