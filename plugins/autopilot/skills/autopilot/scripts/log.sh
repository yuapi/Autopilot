#!/usr/bin/env bash
# Append one entry to the end of .autopilot/LOG.md with the current time and this skill's version.
#   bash log.sh <task ID or -> <status> [repository path] <<'EOF'
#   - Changed: …
#   - Verified: …
#   EOF
# status: done failed blocked retro discover stop. Body lines come from stdin; a line that does not
# start with "- " gets one. Earlier entries are never touched, so the LOG stays in time order.
# Prints the header it wrote. Exit 1 on a bad argument or an empty body.
set -eu
id="${1:-}"; status="${2:-}"
usage() { echo "usage: log.sh <task ID or -> <done|failed|blocked|retro|discover|stop> [repository path] < body" >&2; exit 1; }
case "$id" in -|T-[0-9]*) ;; *) usage;; esac
case "$id" in -) ;; *[!T0-9-]*|T-) usage;; esac
case "$status" in done|failed|blocked|retro|discover|stop) ;; *) usage;; esac
here="$(cd "$(dirname "$0")/.." && pwd)"
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

version="$(sed -n 's/^[[:space:]]*version:[[:space:]]*"\{0,1\}\([0-9][0-9.]*\)"\{0,1\}[[:space:]]*$/\1/p' "$here/SKILL.md" | head -1)"
[ -n "$version" ] || version=unknown
mkdir -p .autopilot
f=.autopilot/LOG.md
[ -f "$f" ] || cp "$here/assets/LOG.md" "$f" 2>/dev/null || echo "# LOG" > "$f"
[ -z "$(tail -c 1 "$f")" ] || echo >> "$f"   # the file must end with a newline before appending
header="## $(date +%Y-%m-%dT%H:%M) | $id | $status | skill $version"
printf '\n%s\n%s' "$header" "$body" >> "$f"
echo "$header"
