#!/usr/bin/env bash
# Deterministic part of discovery: list code markers and risky patterns with file:line.
#   bash scan.sh [--all] [repository path, default: current directory]
# autopilot-scan: ignore-file
# Read-only. Skips .autopilot/, .git/, vendored and generated folders. Every line it prints must
# become a task or get a one-line reason under ROADMAP "Not doing" (see SKILL.md 1-B).
# Without an argument it scans the repository root; with one, only that directory.
# A line containing "autopilot-scan: ignore" is skipped; so is a file with "autopilot-scan: ignore-file"
# in its first 5 lines (for code that discusses these patterns, like this script).
# A section prints at most AUTOPILOT_SCAN_MAX lines (default 50), then "… N more lines" and the hit
# count per folder, so a repository with hundreds of markers can be grouped (SKILL.md 1-B). --all prints every line.
set -u
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
max="${AUTOPILOT_SCAN_MAX:-50}"
case "$max" in ''|*[!0-9]*|0) echo "[scan] AUTOPILOT_SCAN_MAX must be a positive number" >&2; exit 1;; esac
if [ "${1:-}" = --all ]; then max=0; shift; fi
if [ $# -gt 0 ]; then
  root="$(cd "$1" 2>/dev/null && pwd)" || { echo "[scan] no such directory: $1" >&2; exit 1; }
else
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$root"

EXCLUDE='(^|/)(\.autopilot|\.git|node_modules|vendor|third_party|dist|build|target|\.venv|venv|__pycache__|\.tox|\.mypy_cache|coverage|fixtures?[^/]*|testdata)(/|$)'
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "[scan] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
# The file list is built once, in one process (it used to cost several processes per file for every
# search: over 2 minutes on a 5000-file repository). NUL-separated, so any file name works.
LIST="$(mktemp)"; trap 'rm -f "$LIST"' EXIT
mode=walk; git rev-parse --git-dir >/dev/null 2>&1 && mode=git
if [ "$mode" = git ]; then git -c core.quotePath=false ls-files -z -co --exclude-standard; fi \
  | "$PY" -c '
import os, re, sys
exclude = re.compile(sys.argv[1])
data = sys.stdin.buffer.read()
names = [n.decode("utf-8", "surrogateescape") for n in data.split(b"\0") if n] if sys.argv[2] == "git" else \
        [os.path.relpath(os.path.join(r, f)) for r, _, fs in os.walk(".") for f in fs]
out = sys.stdout.buffer
for n in names:
    if exclude.search(n) or not os.path.isfile(n):
        continue
    try:
        with open(n, "rb") as fh:
            head = fh.read(8192)
    except OSError:
        continue
    if not head.strip() or b"\0" in head:
        continue   # empty or binary
    if b"autopilot-scan: ignore-file" in b"\n".join(head.split(b"\n")[:5]):
        continue
    out.write(n.encode("utf-8", "surrogateescape") + b"\0")
' "$EXCLUDE" "$mode" > "$LIST"
search() {  # <label> <extended regex> [extra grep flags]
  local hits
  [ -s "$LIST" ] || return 0
  hits="$(xargs -0 grep -HnIE ${3:-} -- "$2" < "$LIST" 2>/dev/null | grep -v 'autopilot-scan: ignore' | cut -c1-200)"
  [ -n "$hits" ] || return 0
  echo "## $1"
  n="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
  if [ "$max" -gt 0 ] && [ "$n" -gt "$max" ]; then
    printf '%s\n' "$hits" | head -n "$max"
    echo "… $((n - max)) more line(s) ($n in total). Too many for one cycle: group them by file or folder (SKILL.md 1-B). Hits per folder:"
    # the deepest folder level that still fits in 20 groups (src/ alone says little; 200 leaf folders say too much)
    printf '%s\n' "$hits" | "$PY" -c '
import collections, sys
dirs = [l.split(":", 1)[0].rsplit("/", 1)[0] if "/" in l.split(":", 1)[0] else "." for l in sys.stdin.read().splitlines()]
best = None
for k in range(1, max(d.count("/") for d in dirs) + 2):
    c = collections.Counter("/".join(d.split("/")[:k]) for d in dirs)
    if len(c) > 20 and best: break
    best = c
for d, n in sorted(best.items(), key=lambda x: (-x[1], x[0]))[:20]:
    print(f"  {d}/: {n}" if d != "." else f"  (top level): {n}")
'
  else
    printf '%s\n' "$hits"
  fi
  echo
}

echo "# autopilot scan — $root"
echo
search "Code markers (todo)" '(#|//|/\*|<!--|--|;|^[[:space:]]*\*)[[:space:]]*(TODO|FIXME|HACK|XXX)\b|NotImplementedError|pass[[:space:]]*#[[:space:]]*stub'
search "Shell command built from strings (security)" 'os\.system\(|os\.popen\(|subprocess\.[a-z_]+\([^)]*shell[[:space:]]*=[[:space:]]*True|child_process\.exec\(|Runtime\.getRuntime\(\)\.exec\(|\bshell_exec\(|\bpassthru\('
search "Dynamic code execution (security)" '(^|[^a-zA-Z_.])(eval|exec)\([^)]|new Function\('
search "Unsafe deserialization (security)" 'pickle\.loads?\(|yaml\.load\([^)]*\)|marshal\.loads\(|unserialize\('
search "TLS verification disabled (security)" 'verify[[:space:]]*=[[:space:]]*False|rejectUnauthorized[[:space:]]*:[[:space:]]*false|InsecureSkipVerify[[:space:]]*:[[:space:]]*true|NODE_TLS_REJECT_UNAUTHORIZED|CURLOPT_SSL_VERIFYPEER[^;]*(0|false)'
search "Possible hard-coded secret (security)" 'AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(password|passwd|secret|api_?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{8,}["'"'"']' -i
echo "# end of scan"
