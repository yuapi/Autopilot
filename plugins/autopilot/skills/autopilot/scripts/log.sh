#!/usr/bin/env bash
# Append one entry to the end of .autopilot/LOG.md with the current UTC time and this skill's version.
#   bash log.sh <task ID or -> <status> [repository path] <<'EOF'
#   - Changed: …
#   - Verified: …
#   EOF
# status: done failed blocked retro discover release stop. Body lines come from stdin; a line that does not
# start with "- " gets one. Earlier entries are never touched, so the LOG stays in time order.
# A task entry (done, failed, blocked) is refused unless the BACKLOG row agrees: done → done, failed →
# open or blocked, blocked → blocked (run task.sh first). Without a BACKLOG.md it is not checked.
# Prints the header it wrote; for `done` it warns when the last commit names several task IDs.
# Exit 1 on a bad argument or an empty body.
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
id="${1:-}"; status="${2:-}"
usage() { echo "usage: log.sh <task ID or -> <done|failed|blocked|retro|discover|release|stop> [repository path] < body" >&2; exit 1; }
case "$id" in -|T-[0-9]*) ;; *) usage;; esac
case "$id" in -) ;; *[!T0-9-]*|T-) usage;; esac
case "$status" in done|failed|blocked|retro|discover|release|stop) ;; *) usage;; esac
here="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "${3:-.}" ] || { echo "[log] no such directory: ${3:-.}" >&2; exit 1; }
root="$(git -C "${3:-.}" rev-parse --show-toplevel 2>/dev/null || (cd "${3:-.}" && pwd))"
cd "$root"

body=""
if [ ! -t 0 ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '') continue;; '- '*) ;; *) line="- $line";; esac
    body="$body$line"$'\n'
  done
fi
[ -n "$body" ] || { echo "[log] empty body: pass the entry's bullet lines on stdin" >&2; exit 1; }

# A task entry must match the BACKLOG, so the two never disagree: done after task.sh done, failed after
# task.sh fail (open again, or blocked from the 3rd attempt), blocked after task.sh drop or a 3rd fail
if [ "$id" != - ] && [ -f .autopilot/BACKLOG.md ] && [ "$status" != retro ] && [ "$status" != discover ] && [ "$status" != release ] && [ "$status" != stop ]; then
  st="$(cat .autopilot/BACKLOG.md .autopilot/BACKLOG.archive.md 2>/dev/null | tr -d '\r' | awk -F'|' -v id="$id" '{ g = $2; gsub(/ /, "", g) } g == id { s = $4; gsub(/ /, "", s); print s; exit }')"
  case "$status:$st" in
    done:done|failed:open|failed:blocked|blocked:blocked) ;;
    *:) echo "[log] refused: $id has no BACKLOG row. Add the task to the BACKLOG first" >&2; exit 1;;
    done:*) echo "[log] refused: $id is $st in the BACKLOG, not done. Run task.sh done $id first" >&2; exit 1;;
    failed:*) echo "[log] refused: $id is $st in the BACKLOG. Run task.sh fail $id first" >&2; exit 1;;
    blocked:*) echo "[log] refused: $id is $st in the BACKLOG, not blocked. Run task.sh drop $id (or fail at the 3rd attempt) first" >&2; exit 1;;
  esac
fi

# version: 1.2.3, "1.2.3" or '1.2.3' (the account plugin sync writes it single-quoted)
version="$(sed -n "s/^[[:space:]]*version:[[:space:]]*[\"']\{0,1\}\([0-9][0-9.]*\)[\"']\{0,1\}[[:space:]]*\$/\1/p" "$here/SKILL.md" | head -1)"
[ -n "$version" ] || version=unknown
mkdir -p .autopilot
f=.autopilot/LOG.md
[ -f "$f" ] || cp "$here/assets/LOG.md" "$f" 2>/dev/null || echo "# LOG" > "$f"
[ -z "$(tail -c 1 "$f")" ] || echo >> "$f"   # the file must end with a newline before appending
# UTC, so entries written on machines in different time zones (a laptop, a cloud session) stay in order
header="## $(date -u +%Y-%m-%dT%H:%MZ) | $id | $status | skill $version"
if head -1 "$f" | grep -q $'\r$'; then   # a CRLF file (Windows checkout) gets CRLF lines
  printf '\r\n%s\r\n%s' "$header" "$(printf '%s' "$body" | sed 's/$/\r/')" >> "$f"; printf '\n' >> "$f"
else
  printf '\n%s\n%s' "$header" "$body" >> "$f"
fi
echo "$header"
# One task = one commit: say so when the last commit names several task IDs (the entry is still written)
if [ "$status" = done ]; then
  subject="$(git log -1 --format=%s 2>/dev/null || true)"
  n="$(printf '%s' "$subject" | grep -oE 'T-[0-9]+' | sort -u | wc -l | tr -d ' ')"
  if [ "${n:-0}" -gt 1 ] || printf '%s' "$subject" | grep -qE 'T-[0-9]+ *(\.\.|~) *T?-?[0-9]+'; then
    echo "[log] warning: the last commit covers several tasks (\"$subject\"). One task = one commit: commit each task before starting the next." >&2
  fi
fi
