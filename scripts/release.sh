#!/usr/bin/env bash
# Release (on main):
#   bash scripts/release.sh             tag, package and GitHub Release for the current version
#   bash scripts/release.sh --catch-up  every released version that has no tag yet
#   add --dry-run to print what would happen without tags, pushes or Releases (also skips branch/tree checks)
# Packages are built from committed content (git archive).
set -eu
case "${1:-}" in -h|--help) awk 'NR > 1 && /^set -/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;; esac
cd "$(dirname "$0")/.."

mode=""; dry=0
for a in "$@"; do
  case "$a" in
    --catch-up) mode="--catch-up";;
    --dry-run) dry=1;;
    *) echo "usage: release.sh [--catch-up] [--dry-run]" >&2; exit 1;;
  esac
done

if [ "$dry" -eq 0 ]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$branch" != "main" ]; then
    echo "[release] run this on main (current: $branch)." >&2
    exit 1
  fi
  bash scripts/validate.sh
  if [ -n "$(git status --porcelain)" ]; then
    echo "[release] the working tree is not clean. Commit or tidy up, then run again." >&2
    exit 1
  fi
  git fetch --tags origin >/dev/null 2>&1 || true
fi

PLUGIN_JSON=plugins/autopilot/.claude-plugin/plugin.json

# First commit on the current branch's first-parent history where plugin.json became version v (on main: the release merge commit)
first_commit_with_version() {
  local v="$1" c
  for c in $(git rev-list --first-parent --reverse HEAD -- "$PLUGIN_JSON"); do
    if git show "$c:$PLUGIN_JSON" 2>/dev/null | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("version")==sys.argv[1] else 1)' "$v"; then
      echo "$c"; return
    fi
  done
}

# Whether gh exists and can push to this repository (gh auth status is not used: it can fail for repository-scoped tokens)
gh_can_write() {
  command -v gh >/dev/null 2>&1 || return 1
  [ "$(gh api 'repos/{owner}/{repo}' --jq '.permissions.push' 2>/dev/null)" = "true" ]
}

release_one() {
  local ver="$1" commit="$2" tag="v$1" out notes sha
  if [ "$dry" -eq 1 ]; then
    echo "[release] (dry-run) $tag ← $(git rev-parse --short "$commit")"
    return
  fi
  mkdir -p dist
  out="dist/autopilot-$ver.skill"
  rm -f "$out"
  git archive --format=zip --prefix=autopilot/ -o "$out" "$commit:plugins/autopilot/skills/autopilot"
  echo "[release] package: $out ($(git rev-parse --short "$commit"))"

  notes="$(git show "$commit:CHANGELOG.md" | awk -v v="$ver" '$0 ~ "^## "v"( |$)"{f=1; next} f && /^## /{exit} f')"
  sha="$(git rev-parse "$commit^{commit}")"

  git tag -a "$tag" -m "autopilot $ver" "$commit"
  if ! git push origin "$tag"; then
    git tag -d "$tag" >/dev/null
    # Where git cannot push tags (e.g. an environment that only allows branch pushes),
    # create the tag and the Release on GitHub in one go with a gh that can write
    if gh_can_write; then
      echo "[release] tag push failed → creating tag $tag and its Release through the GitHub API ($(git rev-parse --short "$sha"))"
      gh release create "$tag" "$out" --target "$sha" --title "autopilot $ver" --notes "$notes"
      git fetch -q --tags origin 2>/dev/null || true
      echo "[release] GitHub Release $tag created"
      return
    fi
    echo "[release] tag push failed. Deleted the local tag $tag. With a gh (GH_TOKEN) that can write, the API can be used instead." >&2
    exit 1
  fi

  if gh_can_write; then
    gh release create "$tag" "$out" --title "autopilot $ver" --notes "$notes"
    echo "[release] GitHub Release $tag created"
  else
    echo "[release] no gh CLI or no write access. Create the Release for $tag under GitHub → Releases and attach $out."
  fi
}

if [ "$mode" = "--catch-up" ]; then
  done_any=0
  for ver in $(sed -n 's/^## \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' CHANGELOG.md | awk '{l[NR]=$0} END{for(i=NR;i>0;i--) print l[i]}'); do
    git rev-parse -q --verify "refs/tags/v$ver" >/dev/null && continue
    c="$(first_commit_with_version "$ver")"
    if [ -z "$c" ]; then
      echo "[release] $ver: no commit with this version in the main history, skipped"
      continue
    fi
    release_one "$ver" "$c"; done_any=1
  done
  [ "$done_any" -eq 1 ] || echo "[release] no missing tags"
  exit 0
fi

ver="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$PLUGIN_JSON")"
if git rev-parse -q --verify "refs/tags/v$ver" >/dev/null; then
  echo "[release] tag v$ver already exists. Bump the version with bump.sh on a release branch." >&2
  exit 1
fi
release_one "$ver" HEAD
