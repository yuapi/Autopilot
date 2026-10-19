#!/usr/bin/env bash
# 버전 올리기: bash scripts/bump.sh <major|minor|patch> "<변경 요약>"
# 갱신 대상: SKILL.md(metadata.version, 본문 **버전 x.y.z**, LOG 예시 skill x.y.z),
#            plugin.json version, CHANGELOG.md 최상단 항목 추가. 커밋은 하지 않는다.
set -eu
cd "$(dirname "$0")/.."
kind="${1:?사용법: bump.sh <major|minor|patch> \"<변경 요약>\"}"
note="${2:?변경 요약이 필요합니다}"
case "$kind" in major|minor|patch) ;; *) echo "major|minor|patch 중 하나" >&2; exit 1;; esac

python3 - "$kind" "$note" << 'PY'
import datetime, json, re, sys
kind, note = sys.argv[1], sys.argv[2]
skill = "plugins/autopilot/skills/autopilot/SKILL.md"
plugin = "plugins/autopilot/.claude-plugin/plugin.json"
log = "CHANGELOG.md"

s = open(skill, encoding="utf-8").read()
m = re.search(r"^metadata:\n\s+version:\s*(\d+)\.(\d+)\.(\d+)\s*$", s, re.M)
if not m:
    sys.exit("SKILL.md에서 metadata.version을 찾지 못함")
a, b, c = map(int, m.groups())
cur = f"{a}.{b}.{c}"
a, b, c = {"major": (a + 1, 0, 0), "minor": (a, b + 1, 0), "patch": (a, b, c + 1)}[kind]
new = f"{a}.{b}.{c}"

def sub(pattern, repl, text, label):
    out, n = re.subn(pattern, repl, text, flags=re.M)
    if n == 0:
        sys.exit(f"SKILL.md에서 {label}을(를) 찾지 못함")
    return out

esc = re.escape(cur)
s = sub(rf"(^metadata:\n\s+version:\s*){esc}", rf"\g<1>{new}", s, "metadata.version")
s = sub(rf"\*\*버전 {esc}\*\*", f"**버전 {new}**", s, "본문 **버전**")
s = sub(rf"skill {esc}\b", f"skill {new}", s, "LOG 형식 skill 버전")
open(skill, "w", encoding="utf-8").write(s)

p = json.load(open(plugin, encoding="utf-8"))
if p.get("version") != cur:
    sys.exit(f"plugin.json 버전({p.get('version')})이 SKILL.md({cur})와 다름. 먼저 맞출 것")
p["version"] = new
open(plugin, "w", encoding="utf-8").write(json.dumps(p, ensure_ascii=False, indent=2) + "\n")

t = open(log, encoding="utf-8").read()
entry = f"## {new} — {datetime.date.today()}\n- {note}\n\n"
i = t.find("\n## ")
if i < 0:
    t = t.rstrip("\n") + "\n\n" + entry
else:
    t = t[: i + 1] + entry + t[i + 1 :]
open(log, "w", encoding="utf-8").write(t)
print(f"{cur} -> {new}")
PY
