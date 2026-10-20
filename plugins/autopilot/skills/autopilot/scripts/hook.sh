#!/usr/bin/env bash
# Install, update or remove the repository copy of the session-mode Stop hook.
# Since 1.16 the skill declares the hook itself; the copy is only a fallback for environments
# that ignore skill hooks.
#   bash hook.sh install [repository path]
#   bash hook.sh uninstall [repository path]   (removes the copy and its settings.json entry)
# - copies assets/autopilot-stop.sh to .claude/hooks/autopilot-stop.sh when it is missing or differs
#   (copies made by an older skill version are replaced, so fixes reach repositories that already have it)
# - merges the Stop entry into .claude/settings.json without touching other settings or hooks;
#   an entry that runs autopilot-stop.sh with an old command is rewritten
# - uninstall removes only autopilot's entry; other hooks and settings stay. Empty Stop/hooks keys go too
# Prints what it did. Exit 1 if settings.json exists but is not valid JSON (it is then left alone).
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
PY="$(command -v python3 || command -v python || true)"   # Windows Git Bash often has only python
[ -n "$PY" ] || { echo "[autopilot] needs Python 3 on PATH (python3 or python)" >&2; exit 1; }
cmd="${1:-}"
case "$cmd" in install|uninstall) ;; *) echo "usage: hook.sh install|uninstall [repository path]" >&2; exit 1;; esac
here="$(cd "$(dirname "$0")/.." && pwd)"
root="$(git -C "${2:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[hook] not inside a git repository" >&2; exit 1; }
cd "$root"

if [ "$cmd" = uninstall ]; then
  dst=.claude/hooks/autopilot-stop.sh
  if [ -f "$dst" ]; then rm -f "$dst"; hook_state=removed; else hook_state="not present"; fi
  rmdir .claude/hooks 2>/dev/null || true
  settings_state="not present"
  if [ -f .claude/settings.json ]; then
    settings_state="$("$PY" - <<'PY'
import json, sys
p = ".claude/settings.json"
try:
    data = json.load(open(p, encoding="utf-8"))
except ValueError:
    print("invalid"); sys.exit(0)
if not isinstance(data, dict):
    print("invalid"); sys.exit(0)
hooks = data.get("hooks") if isinstance(data.get("hooks"), dict) else {}
stop = hooks.get("Stop") if isinstance(hooks.get("Stop"), list) else []
removed = False
kept = []
for group in stop:
    if isinstance(group, dict) and isinstance(group.get("hooks"), list):
        rest = [h for h in group["hooks"] if "autopilot-stop.sh" not in str(h.get("command", ""))]
        if len(rest) != len(group["hooks"]):
            removed = True
            if not rest:
                continue
            group = dict(group, hooks=rest)
    kept.append(group)
if not removed:
    print("no entry"); sys.exit(0)
if kept:
    hooks["Stop"] = kept
else:
    hooks.pop("Stop", None)
    if not hooks:
        data.pop("hooks", None)
with open(p, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2); f.write("\n")
print("entry removed")
PY
)"
  fi
  if [ "$settings_state" = invalid ]; then
    echo "[hook] .claude/settings.json is not valid JSON; left it alone. Remove the autopilot-stop.sh entry by hand." >&2
    echo "[hook] hook script: $hook_state"
    exit 1
  fi
  echo "[hook] hook script: $hook_state; settings.json: $settings_state"
  exit 0
fi

src="$here/assets/autopilot-stop.sh"; dst=.claude/hooks/autopilot-stop.sh
mkdir -p .claude/hooks
if [ ! -f "$dst" ]; then hook_state=installed
elif ! cmp -s "$src" "$dst"; then hook_state=updated
else hook_state="up to date"
fi
[ "$hook_state" = "up to date" ] || cp "$src" "$dst"
chmod +x "$dst"

settings_state="$("$PY" - <<'PY'
import json, os, sys
p = ".claude/settings.json"
want = 'bash "$CLAUDE_PROJECT_DIR/.claude/hooks/autopilot-stop.sh"'
data = {}
if os.path.exists(p):
    try:
        data = json.load(open(p, encoding="utf-8"))
    except ValueError:
        print("invalid"); sys.exit(0)
    if not isinstance(data, dict):
        print("invalid"); sys.exit(0)
stop = data.setdefault("hooks", {}).setdefault("Stop", [])
state = "added"
for group in stop:
    for h in group.get("hooks", []) if isinstance(group, dict) else []:
        if "autopilot-stop.sh" in str(h.get("command", "")):
            if h.get("command") == want and h.get("type") == "command":
                state = "ok"
            else:
                h["type"], h["command"] = "command", want
                state = "updated"
if state == "added":
    stop.append({"hooks": [{"type": "command", "command": want}]})
if state != "ok":
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2); f.write("\n")
print(state)
PY
)"
if [ "$settings_state" = invalid ]; then
  echo "[hook] .claude/settings.json is not valid JSON; left it alone. Fix it, then run again." >&2
  echo "[hook] hook script: $hook_state"
  exit 1
fi
echo "[hook] hook script: $hook_state; settings.json: $settings_state"
