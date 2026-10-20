#!/usr/bin/env bash
# Tidy the .autopilot state files: move old completed tasks and LOG entries to archives, content unchanged.
#   bash archive.sh [repository root, default: current directory]
# Rules: BACKLOG done/blocked rows > 50 → move the oldest, keep 30
#        LOG entries (lines starting with ##) > 300 → move the oldest, keep 100
set -eu
cd "${1:-.}"
[ -d .autopilot ] || { echo "[archive] no .autopilot directory" >&2; exit 1; }
python3 - << 'PY'
import os, re
A = ".autopilot"

def append(path, header, chunks):
    new = not os.path.exists(path)
    with open(path, "a", encoding="utf-8") as f:
        if new:
            f.write(header)
        f.write("".join(chunks))

p = f"{A}/BACKLOG.md"
if os.path.exists(p):
    lines = open(p, encoding="utf-8").read().splitlines(keepends=True)
    row = re.compile(r"^\| *T-\d+ *\| *[^|]*\| *(done|blocked) *\|")
    idx = [i for i, l in enumerate(lines) if row.match(l)]
    if len(idx) > 50:
        move = set(idx[: len(idx) - 30])
        append(f"{A}/BACKLOG.archive.md",
               "# BACKLOG archive (done and blocked tasks moved from BACKLOG.md)\n\n"
               "| ID | Type | Status | Attempts | Task | Done when | Source | Completed |\n|---|---|---|---|---|---|---|---|\n",
               [lines[i] for i in sorted(move)])
        open(p, "w", encoding="utf-8").write("".join(l for i, l in enumerate(lines) if i not in move))
        print(f"[archive] BACKLOG: moved {len(move)} rows")

p = f"{A}/LOG.md"
if os.path.exists(p):
    text = open(p, encoding="utf-8").read()
    starts = [m.start() for m in re.finditer(r"^## ", text, re.M)]
    if len(starts) > 300:
        cut = starts[len(starts) - 100]
        head, old, rest = text[: starts[0]], text[starts[0]:cut], text[cut:]
        append(f"{A}/LOG.archive.md", "# LOG archive (old entries moved from LOG.md, append only)\n\n", [old])
        open(p, "w", encoding="utf-8").write(head + rest)
        print(f"[archive] LOG: moved {len(starts) - 100} entries")
PY
