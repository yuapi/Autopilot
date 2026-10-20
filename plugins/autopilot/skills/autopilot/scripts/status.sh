#!/usr/bin/env bash
# autopilot run status summary: bash status.sh [repository path, default: current directory]
# Only reads the .autopilot/ state files.
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
target="${1:-.}"
[ -d "$target" ] || { echo "[status] no such directory: $target" >&2; exit 1; }
root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || (cd "$target" && pwd))"
cd "$root"
[ -d .autopilot ] || { echo "[status] no .autopilot/ in $root. autopilot has not run in this repository yet." >&2; exit 1; }
"$PY" - "$root" "$self" << 'PY'
import os, re, signal, sys, time
signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # exit quietly when the output is cut off (e.g. `| head`)
root = sys.argv[1]; A = ".autopilot"
def read(p):
    try: return open(os.path.join(A, p), encoding="utf-8").read()
    except FileNotFoundError: return ""

row = re.compile(r"^\|\s*(T-\d+)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*(\d+)\s*\|\s*([^|]*?)\s*\|", re.M)
rows = row.findall(read("BACKLOG.md"))
archived = row.findall(read("BACKLOG.archive.md"))
count = lambda rs, st: sum(1 for r in rs if r[2] == st)

print(f"autopilot status — {root}")
stop = read("STOP").strip()
if stop:
    print(f"Run: stopped — {stop.splitlines()[0]}")
elif os.path.exists(os.path.join(A, "RUN")):
    run = read("RUN")
    sess = (re.findall(r"^session:\s*(\S+)", run, re.M) or ["unknown"])[0]
    idle = int((time.time() - os.path.getmtime(os.path.join(A, "RUN"))) // 60)
    note = " — idle for over 2 h, a new run will take it over" if idle >= 120 else ""
    bud = re.findall(r"^tasks:\s*(\d+)", run, re.M)
    if bud:
        note += f", {(re.findall(r'^done:\s*(\d+)', run, re.M) or ['0'])[0]}/{bud[0]} tasks of its budget done"
    print(f"Run: running (session mode, session {sess}, last active {idle} min ago{note})")
else:
    print("Run: idle (no RUN or STOP)")

def ver(v): return tuple(int(x) for x in v.split("."))
skill_md = os.path.join(os.path.dirname(os.path.abspath(sys.argv[2])), "..", "SKILL.md")
try: mine = (re.findall(r"^\s*version:\s*[\"']?(\d+\.\d+\.\d+)", open(skill_md, encoding="utf-8").read(), re.M) or [""])[0]
except OSError: mine = ""
seen = re.findall(r"\|\s*skill (\d+\.\d+\.\d+)\s*$", read("LOG.md") + read("LOG.archive.md"), re.M)
newest = max(seen, key=ver) if seen else ""
if mine:
    print(f"Skill: {mine}" + (f" (LOG written up to {newest})" if newest and newest != mine else ""))
    if newest and ver(newest) > ver(mine):
        print(f"Warning: this repository was already run with skill {newest}, newer than the installed {mine}. Its rules may not match the state files; update the plugin or skill first.")

hook = ".claude/hooks/autopilot-stop.sh"
asset = os.path.join(os.path.dirname(os.path.abspath(sys.argv[2])), "..", "assets", "autopilot-stop.sh")
if os.path.exists(hook):
    installed = open(hook, encoding="utf-8", errors="replace").read()
    if ".autopilot/RUN" not in installed:
        print("Warning: an old (1.5.x) Stop hook is installed. Without STOP, even sessions not running autopilot cannot end.")
        print(f"  Fix: run the skill's scripts/hook.sh install, or create .autopilot/STOP for now.")
    elif os.path.exists(asset) and open(asset, encoding="utf-8", errors="replace").read() != installed:
        print("Note: the installed Stop hook is a copy from another skill version. The next run updates it (or run scripts/hook.sh install).")
    print("Note: the skill declares its own Stop hook since 1.16; the copy in .claude/hooks is only needed where skill hooks are ignored. Remove it with scripts/hook.sh uninstall.")

cfg = dict(re.findall(r"^(integration|merge|release|language|scope):\s*([^\s#]+)", read("CONFIG.md"), re.M))
print("Integration: " + (", ".join(f"{k}={v}" for k, v in cfg.items()) if cfg else "local (no CONFIG)"))
if os.environ.get("CLAUDE_CODE_REMOTE") == "true" and cfg.get("integration", "local") == "local":
    print("Warning: this is a cloud session and integration is local: the loop's commits stay in this container and are lost when it is reclaimed. Set integration: branch (or pr) in .autopilot/CONFIG.md to push them.")

done = count(rows, "done") + count(archived, "done")
print(f"Tasks: open {count(rows,'open')} · in progress {count(rows,'in_progress')} · done {done} · blocked {count(rows,'blocked') + count(archived,'blocked')}")

cur = [r for r in rows if r[2] == "in_progress"]
if cur:
    since = ""
    marker = os.path.join(A, ".task")
    if os.path.exists(marker) and read(".task").split()[:1] == [cur[0][0]]:
        mins = int((time.time() - os.path.getmtime(marker)) // 60)
        since = f", started {mins} min ago"
    print(f"Now: {cur[0][0]} [{cur[0][1]}] {cur[0][4][:70]} (attempt {cur[0][3]}{since})")

log = read("LOG.md")
heads = re.findall(r"^## (\S+) \| ([^|]*?) \| (\w+) \|", log, re.M)
tasks = [h for h in heads if h[2] in ("done", "failed", "blocked")]
if tasks:
    last10 = tasks[-10:]
    ok = sum(1 for h in last10 if h[2] == "done")
    print(f"Success rate of the last {len(last10)} runs: {ok}/{len(last10)}")

opens = [r for r in rows if r[2] in ("open", "in_progress")]
if opens:
    print("\nOpen tasks:")
    for r in opens[:8]:
        print(f"  {r[0]} [{r[1]}] {r[4][:70]}" + (" (attempts %s)" % r[3] if r[3] != "0" else ""))
    if len(opens) > 8: print(f"  … and {len(opens)-8} more")

blocked = [r for r in rows if r[2] == "blocked"]
if blocked:
    print("\nBlocked (needs a person):")
    for r in blocked: print(f"  {r[0]} [{r[1]}] {r[4][:70]}")

# `제안` is the Korean status used by state files from 1.8.x and earlier
prop = re.findall(r"^\|\s*(P-\d+)\s*\|\s*(?:proposed|제안)\s*\|\s*([^|]*?)\s*\|", read("PROPOSALS.md"), re.M)
if prop:
    print("\nProposals awaiting a decision (set the status in PROPOSALS.md to adopted / rejected / deferred):")
    for pid, title in prop: print(f"  {pid} {title}")

if heads:
    print("\nLatest entries:")
    for h in heads[-5:]: print(f"  {h[0]}  {h[1] or '-'}  {h[2]}")
if stop and len(stop.splitlines()) > 1:
    print("\nSTOP content:"); print("\n".join("  " + l for l in stop.splitlines()))
PY
