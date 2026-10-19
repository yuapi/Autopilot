#!/usr/bin/env bash
# 릴리스: bash scripts/release.sh   (사람이 main 브랜치에서 직접 실행. 자동화·에이전트 실행 금지)
# 순서: validate → 작업 트리 확인 → 태그 미존재 확인 → .skill 패키징 → 태그 push → GitHub Release
set -eu
cd "$(dirname "$0")/.."

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "$branch" != "main" ]; then
  echo "[release] main 브랜치에서 실행하세요 (현재: $branch). git flow: release/<ver> → main 병합 후 실행" >&2
  exit 1
fi

bash scripts/validate.sh

if [ -n "$(git status --porcelain)" ]; then
  echo "[release] 작업 트리가 깨끗하지 않습니다. 커밋하거나 정리한 뒤 다시 실행하세요." >&2
  exit 1
fi

ver="$(python3 -c 'import json; print(json.load(open("plugins/autopilot/.claude-plugin/plugin.json"))["version"])')"
tag="v$ver"
git fetch --tags origin >/dev/null 2>&1 || true
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "[release] 태그 $tag 가 이미 있습니다. bump.sh로 버전을 올리세요." >&2
  exit 1
fi

mkdir -p dist
out="dist/autopilot-$ver.skill"
rm -f "$out"
(cd plugins/autopilot/skills && zip -qr -X "../../../$out" autopilot -x '*.DS_Store')
echo "[release] 패키지: $out"

git tag -a "$tag" -m "autopilot $ver"
if ! git push origin "$tag"; then
  git tag -d "$tag" >/dev/null
  echo "[release] 태그 push 실패. 로컬 태그 $tag 를 지웠습니다. 원인을 해결한 뒤 다시 실행하세요." >&2
  exit 1
fi

notes="$(awk -v v="$ver" '$0 ~ "^## "v"( |$)"{f=1; next} f && /^## /{exit} f' CHANGELOG.md)"
if command -v gh >/dev/null 2>&1; then
  gh release create "$tag" "$out" --title "autopilot $ver" --notes "$notes"
  echo "[release] GitHub Release $tag 생성 완료"
else
  echo "[release] gh CLI가 없습니다. 수동으로 마무리하세요:"
  echo "  1. GitHub 레포 → Releases → Draft a new release → 태그 $tag 선택"
  echo "  2. 제목: autopilot $ver"
  echo "  3. 본문: CHANGELOG.md 의 '## $ver' 섹션"
  echo "  4. 첨부: $out"
fi
