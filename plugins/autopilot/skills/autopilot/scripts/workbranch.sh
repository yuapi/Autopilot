#!/usr/bin/env bash
# Make sure autopilot does not commit straight onto a default branch in local mode.
#   bash workbranch.sh [repository path, default: current directory]
# In `integration: local` (the default) with `local_branch: auto` (the default), when HEAD is on a
# default branch (main, master, develop, trunk or the remote's default) or detached, create and switch
# to autopilot/<YYYYMMDD-HHMM> from the current commit. Uncommitted changes come along.
# On any other branch it stays put, so running it before every task is safe. It never pushes.
# Prints the branch to work on as the last line.
set -eu
root="$(git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[workbranch] not inside a git repository" >&2; exit 1; }
cd "$root"

cfg_value() {
  [ -f .autopilot/CONFIG.md ] || return 0
  sed -n "s/^$1:[[:space:]]*\([^[:space:]#]*\).*/\1/p" .autopilot/CONFIG.md | head -1
}
integration="$(cfg_value integration)"; integration="${integration:-local}"
local_branch="$(cfg_value local_branch)"; local_branch="${local_branch:-auto}"

current="$(git symbolic-ref --short -q HEAD || true)"
if [ "$integration" != "local" ] || [ "$local_branch" = "current" ]; then
  echo "${current:-HEAD}"; exit 0
fi

remote_default="$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
protected=0
case "$current" in
  ""|main|master|develop|trunk) protected=1;;
esac
[ -n "$remote_default" ] && [ "$current" = "$remote_default" ] && protected=1
if [ "$protected" -eq 0 ]; then
  echo "$current"; exit 0
fi

base="autopilot/$(date +%Y%m%d-%H%M)"; name="$base"; i=2
while git show-ref --verify -q "refs/heads/$name"; do name="$base-$i"; i=$((i + 1)); done
git switch -q -c "$name"
echo "[workbranch] ${current:-detached HEAD} is a default branch; created and switched to $name" >&2
echo "$name"
