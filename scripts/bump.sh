#!/usr/bin/env bash
# 버전 올리기 (release/<ver> 브랜치에서): bash scripts/bump.sh <major|minor|patch> ["<추가 요약>"]
# 갱신 대상: SKILL.md(metadata.version, 본문 **Version x.y.z**, LOG 예시 skill x.y.z),
#            plugin.json version, CHANGELOG.md (## Unreleased → ## x.y.z — 날짜). 커밋은 하지 않는다.
set -eu
cd "$(dirname "$0")/.."
kind="${1:-}"
note="${2:-}"
case "$kind" in major|minor|patch) ;; *) echo "사용법: bump.sh <major|minor|patch> [\"<추가 요약>\"]" >&2; exit 1;; esac

python3 - "$kind" "$note" << 'PY'
import datetime, json, re, sys
kind, note = sys.argv[1], sys.argv[2].strip()
skill = "plugins/autopilot/skills/autopilot/SKILL.md"
plugin = "plugins/autopilot/.claude-plugin/plugin.json"
log = "CHANGELOG.md"

s = open(skill, encoding="utf-8").read()
m = re.search(r"^metadata:\n\s+version:\s*['\"]?(\d+)\.(\d+)\.(\d+)['\"]?\s*$", s, re.M)
if not m:
    sys.exit("SKILL.md에서 metadata.version을 찾지 못함")
a, b, c = map(int, m.groups())
cur = f"{a}.{b}.{c}"
a, b, c = {"major": (a + 1, 0, 0), "minor": (a, b + 1, 0), "patch": (a, b, c + 1)}[kind]
new = f"{a}.{b}.{c}"

# CHANGELOG 먼저 계산 (실패 시 아무 파일도 바꾸지 않도록)
t = open(log, encoding="utf-8").read()
today = datetime.date.today()
um = re.search(r"^## Unreleased[ \t]*\n(.*?)(?=^## |\Z)", t, re.M | re.S)
items = um.group(1).strip() if um else ""
if items:
    body = items + (f"\n- {note}" if note else "")
    t = t[: um.start()] + f"## Unreleased\n\n## {new} — {today}\n{body}\n\n" + t[um.end():]
else:
    if not note:
        sys.exit("## Unreleased 항목이 없음. 요약을 인자로 주거나 CHANGELOG에 항목을 먼저 쓸 것")
    entry = f"## {new} — {today}\n- {note}\n\n"
    if um:
        t = t[: um.start()] + "## Unreleased\n\n" + entry + t[um.end():]
    else:
        i = t.find("\n## ")
        t = t.rstrip("\n") + "\n\n" + entry if i < 0 else t[: i + 1] + entry + t[i + 1 :]

p = json.load(open(plugin, encoding="utf-8"))
if p.get("version") != cur:
    sys.exit(f"plugin.json 버전({p.get('version')})이 SKILL.md({cur})와 다름. 먼저 맞출 것")

def sub(pattern, repl, text, label):
    out, n = re.subn(pattern, repl, text, flags=re.M)
    if n == 0:
        sys.exit(f"SKILL.md에서 {label}을(를) 찾지 못함")
    return out

esc = re.escape(cur)
s = sub(rf"(^metadata:\n\s+version:\s*['\"]?){esc}", rf"\g<1>{new}", s, "metadata.version")
s = sub(rf"\*\*Version {esc}\*\*", f"**Version {new}**", s, "본문 **Version**")
s = sub(rf"skill {esc}\b", f"skill {new}", s, "LOG 형식 skill 버전")

p["version"] = new
open(skill, "w", encoding="utf-8").write(s)
open(plugin, "w", encoding="utf-8").write(json.dumps(p, ensure_ascii=False, indent=2) + "\n")
open(log, "w", encoding="utf-8").write(t)
print(f"{cur} -> {new}")
PY
