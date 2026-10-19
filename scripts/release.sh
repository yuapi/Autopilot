#!/usr/bin/env bash
# 릴리스 (main 브랜치에서):
#   bash scripts/release.sh             현재 버전 태그·패키지·GitHub Release
#   bash scripts/release.sh --catch-up  태그가 없는 과거 릴리스 버전 전부 처리
#   --dry-run 을 붙이면 태그·push·Release 없이 할 일만 출력 (브랜치·작업 트리 검사도 생략)
# 패키지는 커밋된 내용으로 만든다 (git archive).
set -eu
cd "$(dirname "$0")/.."

mode=""; dry=0
for a in "$@"; do
  case "$a" in
    --catch-up) mode="--catch-up";;
    --dry-run) dry=1;;
    *) echo "사용법: release.sh [--catch-up] [--dry-run]" >&2; exit 1;;
  esac
done

if [ "$dry" -eq 0 ]; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$branch" != "main" ]; then
    echo "[release] main 브랜치에서 실행하세요 (현재: $branch)." >&2
    exit 1
  fi
  bash scripts/validate.sh
  if [ -n "$(git status --porcelain)" ]; then
    echo "[release] 작업 트리가 깨끗하지 않습니다. 커밋하거나 정리한 뒤 다시 실행하세요." >&2
    exit 1
  fi
  git fetch --tags origin >/dev/null 2>&1 || true
fi

PLUGIN_JSON=plugins/autopilot/.claude-plugin/plugin.json

# 현재 브랜치 first-parent 기록에서 plugin.json이 버전 v가 된 첫 커밋 (main에선 릴리스 merge 커밋)
first_commit_with_version() {
  local v="$1" c
  for c in $(git rev-list --first-parent --reverse HEAD -- "$PLUGIN_JSON"); do
    if git show "$c:$PLUGIN_JSON" 2>/dev/null | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("version")==sys.argv[1] else 1)' "$v"; then
      echo "$c"; return
    fi
  done
}

release_one() {
  local ver="$1" commit="$2" tag="v$1" out notes
  if [ "$dry" -eq 1 ]; then
    echo "[release] (dry-run) $tag ← $(git rev-parse --short "$commit")"
    return
  fi
  mkdir -p dist
  out="dist/autopilot-$ver.skill"
  rm -f "$out"
  git archive --format=zip --prefix=autopilot/ -o "$out" "$commit:plugins/autopilot/skills/autopilot"
  echo "[release] 패키지: $out ($(git rev-parse --short "$commit"))"

  git tag -a "$tag" -m "autopilot $ver" "$commit"
  if ! git push origin "$tag"; then
    git tag -d "$tag" >/dev/null
    echo "[release] 태그 push 실패. 로컬 태그 $tag 를 지웠습니다. 원인을 해결한 뒤 다시 실행하세요." >&2
    exit 1
  fi

  notes="$(git show "$commit:CHANGELOG.md" | awk -v v="$ver" '$0 ~ "^## "v"( |$)"{f=1; next} f && /^## /{exit} f')"
  if command -v gh >/dev/null 2>&1; then
    gh release create "$tag" "$out" --title "autopilot $ver" --notes "$notes"
    echo "[release] GitHub Release $tag 생성 완료"
  else
    echo "[release] gh CLI가 없습니다. GitHub → Releases → $tag 로 Release를 만들고 $out 를 첨부하세요."
  fi
}

if [ "$mode" = "--catch-up" ]; then
  done_any=0
  for ver in $(sed -n 's/^## \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' CHANGELOG.md | tac); do
    git rev-parse -q --verify "refs/tags/v$ver" >/dev/null && continue
    c="$(first_commit_with_version "$ver")"
    if [ -z "$c" ]; then
      echo "[release] $ver: main 기록에서 해당 버전 커밋을 찾지 못해 건너뜀"
      continue
    fi
    release_one "$ver" "$c"; done_any=1
  done
  [ "$done_any" -eq 1 ] || echo "[release] 밀린 태그 없음"
  exit 0
fi

ver="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$PLUGIN_JSON")"
if git rev-parse -q --verify "refs/tags/v$ver" >/dev/null; then
  echo "[release] 태그 v$ver 가 이미 있습니다. release 브랜치에서 bump.sh로 버전을 올리세요." >&2
  exit 1
fi
release_one "$ver" HEAD
