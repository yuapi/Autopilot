#!/usr/bin/env bash
# Make sure autopilot does not commit straight onto a default branch in local mode.
#   bash workbranch.sh [repository path, default: current directory]
#   bash workbranch.sh --push [repository path]
# In `integration: local` (the default) with `local_branch: auto` (the default), when HEAD is on a
# default branch (main, master, develop, trunk or the remote's default) or detached, create and switch
# to autopilot/<YYYYMMDD-HHMM> from the current commit. Uncommitted changes come along.
# On any other branch it stays put, so running it before every task is safe. It never pushes.
# Prints the branch to work on as the last line.
# --push (after the state commit of every task): in a cloud session (CLAUDE_CODE_REMOTE=true) whose
# CONFIG sets no `integration`, push the work branch to origin, since the container and its commits are
# reclaimed. Never a default branch or a detached HEAD (refused, exit 1). Does nothing outside a cloud
# session, or when CONFIG sets `integration` (local stays local; branch and pr publish on their own).
# Exit 1 when the push fails: write that in the LOG and go on.
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
push=0; [ "${1:-}" = --push ] && { push=1; shift; }
[ -d "${1:-.}" ] || { echo "[workbranch] no such directory: ${1:-.}" >&2; exit 1; }
root="$(git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || { echo "[workbranch] not inside a git repository" >&2; exit 1; }
cd "$root"

cfg_value() {
  [ -f .autopilot/CONFIG.md ] || return 0
  sed -n "s/^$1:[[:space:]]*\([^[:space:]#]*\).*/\1/p" .autopilot/CONFIG.md | head -1
}
integration="$(cfg_value integration)"; integration_set="$integration"; integration="${integration:-local}"
local_branch="$(cfg_value local_branch)"; local_branch="${local_branch:-auto}"
# An unknown value (a typo such as "prr") counts as the safest one: otherwise it would read as
# "not local" and leave the loop committing on a default branch
case "$integration" in local|branch|pr) ;; *)
  echo "[workbranch] CONFIG integration: $integration is not local, branch or pr; treating it as local" >&2; integration=local;; esac
case "$local_branch" in auto|current) ;; *)
  echo "[workbranch] CONFIG local_branch: $local_branch is not auto or current; treating it as auto" >&2; local_branch=auto;; esac

current="$(git symbolic-ref --short -q HEAD || true)"
remote_default="$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
protected=0
case "$current" in
  ""|main|master|develop|trunk) protected=1;;
esac
[ -n "$remote_default" ] && [ "$current" = "$remote_default" ] && protected=1

if [ "$push" = 1 ]; then
  if [ "${CLAUDE_CODE_REMOTE:-}" != true ]; then echo "[workbranch] not a cloud session: local mode does not push"; exit 0; fi
  if [ -n "$integration_set" ]; then echo "[workbranch] CONFIG sets integration: $integration_set; not pushing here (that mode decides)"; exit 0; fi
  [ "$protected" = 0 ] || { echo "[workbranch] refused: ${current:-detached HEAD} is a default branch; only a work branch is pushed. Run workbranch.sh first" >&2; exit 1; }
  git remote get-url origin >/dev/null 2>&1 || { echo "[workbranch] no remote named origin: the commits stay in this container and are lost when it is reclaimed" >&2; exit 0; }
  if git push -q -u origin "$current" 2>/dev/null; then
    echo "[workbranch] pushed $current to origin (cloud session without integration in CONFIG; no PR, no merge)"; exit 0
  fi
  echo "[workbranch] push of $current failed (blocked or offline): write it in the LOG and go on; the commits stay in this container" >&2; exit 1
fi

if [ "$integration" != "local" ] || [ "$local_branch" = "current" ]; then
  echo "${current:-HEAD}"; exit 0
fi
if [ "$protected" -eq 0 ]; then
  echo "$current"; exit 0
fi

base="autopilot/$(date +%Y%m%d-%H%M)"; name="$base"; i=2
while git show-ref --verify -q "refs/heads/$name"; do name="$base-$i"; i=$((i + 1)); done
git switch -q -c "$name"
echo "[workbranch] ${current:-detached HEAD} is a default branch; created and switched to $name" >&2
echo "$name"
