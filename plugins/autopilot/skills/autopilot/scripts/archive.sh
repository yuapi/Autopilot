#!/usr/bin/env bash
# .autopilot 상태 파일 정리: 오래된 완료 작업과 LOG 항목을 아카이브로 옮긴다. 내용은 바꾸지 않는다.
#   bash archive.sh [레포 루트, 기본 현재 위치]
# 기준: BACKLOG done/blocked 행 > 50 → 오래된 것부터 옮겨 30개 남김
#       LOG 항목(## 로 시작) > 300 → 오래된 것부터 옮겨 100개 남김
set -eu
cd "${1:-.}"
[ -d .autopilot ] || { echo "[archive] .autopilot 없음" >&2; exit 1; }
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
               "# BACKLOG 아카이브 (BACKLOG.md에서 옮긴 완료·blocked 작업)\n\n"
               "| ID | 유형 | 상태 | 시도 | 작업 | 완료 기준 | 출처 | 완료일 |\n|---|---|---|---|---|---|---|---|\n",
               [lines[i] for i in sorted(move)])
        open(p, "w", encoding="utf-8").write("".join(l for i, l in enumerate(lines) if i not in move))
        print(f"[archive] BACKLOG {len(move)}행 이동")

p = f"{A}/LOG.md"
if os.path.exists(p):
    text = open(p, encoding="utf-8").read()
    starts = [m.start() for m in re.finditer(r"^## ", text, re.M)]
    if len(starts) > 300:
        cut = starts[len(starts) - 100]
        head, old, rest = text[: starts[0]], text[starts[0]:cut], text[cut:]
        append(f"{A}/LOG.archive.md", "# LOG 아카이브 (LOG.md에서 옮긴 오래된 항목, append only)\n\n", [old])
        open(p, "w", encoding="utf-8").write(head + rest)
        print(f"[archive] LOG {len(starts) - 100}개 항목 이동")
PY
