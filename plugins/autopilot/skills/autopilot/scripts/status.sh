#!/usr/bin/env bash
# autopilot 실행 상태 요약: bash status.sh [레포 경로, 기본 현재 위치]
# .autopilot/ 상태 파일을 읽기만 한다.
set -eu
target="${1:-.}"
root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || (cd "$target" && pwd))"
cd "$root"
[ -d .autopilot ] || { echo "[status] $root 에 .autopilot/ 이 없습니다. 아직 autopilot을 실행하지 않은 레포입니다." >&2; exit 1; }
python3 - "$root" << 'PY'
import os, re, sys
root = sys.argv[1]; A = ".autopilot"
def read(p):
    try: return open(os.path.join(A, p), encoding="utf-8").read()
    except FileNotFoundError: return ""

row = re.compile(r"^\|\s*(T-\d+)\s*\|\s*([^|]*?)\s*\|\s*([^|]*?)\s*\|\s*(\d+)\s*\|\s*([^|]*?)\s*\|", re.M)
rows = row.findall(read("BACKLOG.md"))
archived = row.findall(read("BACKLOG.archive.md"))
count = lambda rs, st: sum(1 for r in rs if r[2] == st)

print(f"autopilot 상태 — {root}")
stop = read("STOP").strip()
if stop:
    print(f"실행: 멈춤 — {stop.splitlines()[0]}")
elif os.path.exists(os.path.join(A, "RUN")):
    print("실행: 진행 중 (세션 연속 모드)")
else:
    print("실행: 대기 (RUN·STOP 없음)")

cfg = dict(re.findall(r"^(integration|merge|release):\s*([^\s#]+)", read("CONFIG.md"), re.M))
print("통합: " + (", ".join(f"{k}={v}" for k, v in cfg.items()) if cfg else "local (CONFIG 없음)"))

done = count(rows, "done") + count(archived, "done")
print(f"작업: open {count(rows,'open')} · 진행 {count(rows,'in_progress')} · 완료 {done} · blocked {count(rows,'blocked') + count(archived,'blocked')}")

log = read("LOG.md")
heads = re.findall(r"^## (\S+) \| ([^|]*?) \| (\w+) \|", log, re.M)
tasks = [h for h in heads if h[2] in ("done", "failed", "blocked")]
if tasks:
    last10 = tasks[-10:]
    ok = sum(1 for h in last10 if h[2] == "done")
    print(f"최근 {len(last10)}회 성공률: {ok}/{len(last10)}")

opens = [r for r in rows if r[2] in ("open", "in_progress")]
if opens:
    print("\n열린 작업:")
    for r in opens[:8]:
        print(f"  {r[0]} [{r[1]}] {r[4][:70]}" + (" (시도 %s)" % r[3] if r[3] != "0" else ""))
    if len(opens) > 8: print(f"  … 외 {len(opens)-8}개")

blocked = [r for r in rows if r[2] == "blocked"]
if blocked:
    print("\nblocked (사람 확인 필요):")
    for r in blocked: print(f"  {r[0]} [{r[1]}] {r[4][:70]}")

prop = re.findall(r"^\|\s*(P-\d+)\s*\|\s*제안\s*\|\s*([^|]*?)\s*\|", read("PROPOSALS.md"), re.M)
if prop:
    print("\n결정 대기 제안 (PROPOSALS.md 상태를 채택/거절/보류로):")
    for pid, title in prop: print(f"  {pid} {title}")

if heads:
    print("\n최근 기록:")
    for h in heads[-5:]: print(f"  {h[0]}  {h[1] or '-'}  {h[2]}")
if stop and len(stop.splitlines()) > 1:
    print("\nSTOP 내용:"); print("\n".join("  " + l for l in stop.splitlines()))
PY
