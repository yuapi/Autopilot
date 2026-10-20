#!/usr/bin/env bash
# autopilot run status summary: bash status.sh [repository path, default: current directory]
# Only reads the .autopilot/ state files.
set -eu
target="${1:-.}"
root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || (cd "$target" && pwd))"
cd "$root"
[ -d .autopilot ] || { echo "[status] no .autopilot/ in $root. autopilot has not run in this repository yet." >&2; exit 1; }
python3 - "$root" << 'PY'
import os, re, signal, sys
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
    import time
    run = read("RUN")
    sess = (re.findall(r"^session:\s*(\S+)", run, re.M) or ["unknown"])[0]
    idle = int((time.time() - os.path.getmtime(os.path.join(A, "RUN"))) // 60)
    note = " — idle for over 2 h, a new run will take it over" if idle >= 120 else ""
    print(f"Run: running (session mode, session {sess}, last active {idle} min ago{note})")
else:
    print("Run: idle (no RUN or STOP)")

hook = ".claude/hooks/autopilot-stop.sh"
if os.path.exists(hook) and ".autopilot/RUN" not in open(hook, encoding="utf-8", errors="replace").read():
    print("Warning: an old (1.5.x) Stop hook is installed. Without STOP, even sessions not running autopilot cannot end.")
    print(f"  Fix: overwrite {hook} with the skill's assets/autopilot-stop.sh, or create .autopilot/STOP for now.")

cfg = dict(re.findall(r"^(integration|merge|release|language):\s*([^\s#]+)", read("CONFIG.md"), re.M))
print("Integration: " + (", ".join(f"{k}={v}" for k, v in cfg.items()) if cfg else "local (no CONFIG)"))

done = count(rows, "done") + count(archived, "done")
print(f"Tasks: open {count(rows,'open')} · in progress {count(rows,'in_progress')} · done {done} · blocked {count(rows,'blocked') + count(archived,'blocked')}")

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
