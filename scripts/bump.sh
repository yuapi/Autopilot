#!/usr/bin/env bash
# Bump the version (on a release/<ver> branch): bash scripts/bump.sh <major|minor|patch> ["<extra summary>"]
# Updates: SKILL.md (metadata.version, body **Version x.y.z**, LOG example skill x.y.z),
#          plugin.json version, CHANGELOG.md (## Unreleased → ## x.y.z — date). Does not commit.
set -eu
cd "$(dirname "$0")/.."
kind="${1:-}"
note="${2:-}"
case "$kind" in major|minor|patch) ;; *) echo "usage: bump.sh <major|minor|patch> [\"<extra summary>\"]" >&2; exit 1;; esac

python3 - "$kind" "$note" << 'PY'
import datetime, json, re, sys
kind, note = sys.argv[1], sys.argv[2].strip()
skill = "plugins/autopilot/skills/autopilot/SKILL.md"
plugin = "plugins/autopilot/.claude-plugin/plugin.json"
log = "CHANGELOG.md"

s = open(skill, encoding="utf-8").read()
m = re.search(r"^metadata:\n\s+version:\s*['\"]?(\d+)\.(\d+)\.(\d+)['\"]?\s*$", s, re.M)
if not m:
    sys.exit("metadata.version not found in SKILL.md")
a, b, c = map(int, m.groups())
cur = f"{a}.{b}.{c}"
a, b, c = {"major": (a + 1, 0, 0), "minor": (a, b + 1, 0), "patch": (a, b, c + 1)}[kind]
new = f"{a}.{b}.{c}"

# Work out the CHANGELOG first so a failure changes no files
t = open(log, encoding="utf-8").read()
today = datetime.date.today()
um = re.search(r"^## Unreleased[ \t]*\n(.*?)(?=^## |\Z)", t, re.M | re.S)
items = um.group(1).strip() if um else ""
if items:
    body = items + (f"\n- {note}" if note else "")
    t = t[: um.start()] + f"## Unreleased\n\n## {new} — {today}\n{body}\n\n" + t[um.end():]
else:
    if not note:
        sys.exit("no items under ## Unreleased. Pass a summary or add items to the CHANGELOG first")
    entry = f"## {new} — {today}\n- {note}\n\n"
    if um:
        t = t[: um.start()] + "## Unreleased\n\n" + entry + t[um.end():]
    else:
        i = t.find("\n## ")
        t = t.rstrip("\n") + "\n\n" + entry if i < 0 else t[: i + 1] + entry + t[i + 1 :]

p = json.load(open(plugin, encoding="utf-8"))
if p.get("version") != cur:
    sys.exit(f"plugin.json version ({p.get('version')}) differs from SKILL.md ({cur}). Make them match first")

def sub(pattern, repl, text, label):
    out, n = re.subn(pattern, repl, text, flags=re.M)
    if n == 0:
        sys.exit(f"{label} not found in SKILL.md")
    return out

esc = re.escape(cur)
s = sub(rf"(^metadata:\n\s+version:\s*['\"]?){esc}", rf"\g<1>{new}", s, "metadata.version")
s = sub(rf"\*\*Version {esc}\*\*", f"**Version {new}**", s, "body **Version**")
s = sub(rf"skill {esc}\b", f"skill {new}", s, "LOG format skill version")

p["version"] = new
open(skill, "w", encoding="utf-8").write(s)
open(plugin, "w", encoding="utf-8").write(json.dumps(p, ensure_ascii=False, indent=2) + "\n")
open(log, "w", encoding="utf-8").write(t)
print(f"{cur} -> {new}")
PY
