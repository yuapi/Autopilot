#!/usr/bin/env bash
# Tests for scripts/archive.sh (state file housekeeping)
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
    rows.append(f"| T-{i:03d} | fix | {st} | 1 | task {i} | criteria | source | 2026-01-01 |\n")
rows.append(f"| T-{nb+1:03d} | fix | open | 0 | open task | criteria | source | |\n")
open(f"{d}/.autopilot/BACKLOG.md", "w").write("# BACKLOG\n\nnext_id: 1\n\n| ID | Type | Status | Attempts | Task | Done when | Source | Completed |\n|---|---|---|---|---|---|---|---|\n" + "".join(rows))
log = "# LOG\n" + "".join(f"\n## 2026-01-01T00:00 | T-{i:03d} | done | skill 1.0.0\n- Changed: a{i}\n" for i in range(1, nl + 1))
open(f"{d}/.autopilot/LOG.md", "w").write(log)
PY
  echo "$d"
}
rows() { grep -cE '^\| T-[0-9]+ \|' "$1" 2>/dev/null || echo 0; }
entries() { grep -c '^## ' "$1" 2>/dev/null || echo 0; }

d="$(mk 40 200)"; before="$(cat "$d/.autopilot/BACKLOG.md" "$d/.autopilot/LOG.md" | cksum)"
bash "$ARCH" "$d" >/dev/null
check "below the limits nothing changes" test "$(cat "$d/.autopilot/BACKLOG.md" "$d/.autopilot/LOG.md" | cksum)" = "$before"
check "below the limits no archive is created" test ! -e "$d/.autopilot/BACKLOG.archive.md"

d="$(mk 60 350)"
all_rows="$(grep -E '^\| T-' "$d/.autopilot/BACKLOG.md" | sort | cksum)"
all_log="$(sed -n '/^## /,$p' "$d/.autopilot/LOG.md" | cksum)"
bash "$ARCH" "$d" >/dev/null
check "BACKLOG keeps 30 completed rows + 1 open" test "$(rows "$d/.autopilot/BACKLOG.md")" -eq 31
check "BACKLOG archive has 30 rows" test "$(rows "$d/.autopilot/BACKLOG.archive.md")" -eq 30
check "oldest moved first (T-001 is archived)" grep -q '^| T-001 ' "$d/.autopilot/BACKLOG.archive.md"
check "recent rows stay (T-060)" grep -q '^| T-060 ' "$d/.autopilot/BACKLOG.md"
check "open rows stay" grep -q '| open |' "$d/.autopilot/BACKLOG.md"
check "no BACKLOG row lost or altered" test "$(cat "$d/.autopilot/BACKLOG.md" "$d/.autopilot/BACKLOG.archive.md" | grep -E '^\| T-' | sort | cksum)" = "$all_rows"
check "LOG keeps 100 entries" test "$(entries "$d/.autopilot/LOG.md")" -eq 100
check "LOG archive has 250 entries" test "$(entries "$d/.autopilot/LOG.archive.md")" -eq 250
check "LOG header kept" test "$(head -1 "$d/.autopilot/LOG.md")" = "# LOG"
check "no LOG entry lost or altered" test "$( { sed -n '/^## /,$p' "$d/.autopilot/LOG.archive.md"; sed -n '/^## /,$p' "$d/.autopilot/LOG.md"; } | cksum)" = "$all_log"

# Second run: appends to the archive, header written only once
python3 - "$d" <<'PY'
import sys
d=sys.argv[1]
with open(f"{d}/.autopilot/LOG.md","a") as f:
    f.write("".join(f"\n## 2026-02-01T00:00 | X-{i} | done | skill 1.0.0\n- x\n" for i in range(250)))
PY
bash "$ARCH" "$d" >/dev/null
check "rerun: LOG keeps 100 entries" test "$(entries "$d/.autopilot/LOG.md")" -eq 100
check "rerun: appends to the archive (500 entries)" test "$(entries "$d/.autopilot/LOG.archive.md")" -eq 500
check "rerun: archive header appears once" test "$(grep -c '^# LOG archive' "$d/.autopilot/LOG.archive.md")" -eq 1

check_not "fails without .autopilot" bash "$ARCH" "$TMPROOT"

# a CRLF checkout (Windows) stays CRLF
d="$(mk 60 320)"; for f in BACKLOG LOG; do sedi 's/$/\r/' "$d/.autopilot/$f.md"; done
bash "$ARCH" "$d" >/dev/null
check "CRLF BACKLOG keeps CRLF after archiving" bash -c "! grep -qv \$'\\r\$' '$d/.autopilot/BACKLOG.md'"
check "CRLF LOG keeps CRLF after archiving" bash -c "! grep -qv \$'\\r\$' '$d/.autopilot/LOG.md'"
check "archived rows keep CRLF" bash -c "grep '^| T-001 ' '$d/.autopilot/BACKLOG.archive.md' | grep -q \$'\\r\$'"

finish
