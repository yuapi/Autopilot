#!/usr/bin/env bash
# Install or update the session-mode Stop hook in a repository.
#   bash hook.sh install [repository path]
# - copies assets/autopilot-stop.sh to .claude/hooks/autopilot-stop.sh when it is missing or differs
#   (copies made by an older skill version are replaced, so fixes reach repositories that already have it)
# - merges the Stop entry into .claude/settings.json without touching other settings or hooks;
#   an entry that runs autopilot-stop.sh with an old command is rewritten
# Prints what it did. Exit 1 if settings.json exists but is not valid JSON (it is then left alone).
set -eu
cmd="${1:-}"
[ "$cmd" = install ] || { echo "usage: hook.sh install [repository path]" >&2; exit 1; }
here="$(cd "$(dirname "$0")/.." && pwd)"
root="$(git -C "${2:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[hook] not inside a git repository" >&2; exit 1; }
cd "$root"

src="$here/assets/autopilot-stop.sh"; dst=.claude/hooks/autopilot-stop.sh
mkdir -p .claude/hooks
if [ ! -f "$dst" ]; then hook_state=installed
elif ! cmp -s "$src" "$dst"; then hook_state=updated
else hook_state="up to date"
fi
[ "$hook_state" = "up to date" ] || cp "$src" "$dst"
chmod +x "$dst"

settings_state="$(python3 - <<'PY'
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
