#!/usr/bin/env bash
# Deterministic part of discovery: list code markers and risky patterns with file:line.
#   bash scan.sh [repository path, default: current directory]
# autopilot-scan: ignore-file
# Read-only. Skips .autopilot/, .git/, vendored and generated folders. Every line it prints must
# become a task or get a one-line reason under ROADMAP "Not doing" (see SKILL.md 1-B).
# Without an argument it scans the repository root; with one, only that directory.
# A line containing "autopilot-scan: ignore" is skipped; so is a file with "autopilot-scan: ignore-file"
# in its first 5 lines (for code that discusses these patterns, like this script).
set -u
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
  printf '%s\n' "$hits"
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
