#!/usr/bin/env bash
# scripts/release.sh 실제 릴리스 경로: 태그 push가 거부될 때 gh API로 대신 만드는지
. "$(dirname "$0")/lib.sh"

# 가짜 gh: api → 권한 응답(FAKE_GH_PUSH), release → 인자 기록
FAKEBIN="$TMPROOT/fakebin"; mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/gh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  api) [ "${FAKE_GH_PUSH:-true}" = true ] && echo true || echo false;;
  release) printf '%s\n' "$@" > "$GH_LOG";;
esac
SH
chmod +x "$FAKEBIN/gh"

# 태그 push를 거부하는 원격과 main 브랜치 레포
setup() {
  local d; d="$(sandbox)"
  git init -q --bare "$d.remote.git"
  printf '#!/bin/sh\nwhile read o n r; do case "$r" in refs/tags/*) echo "tags denied" >&2; exit 1;; esac; done\n' > "$d.remote.git/hooks/pre-receive"
  chmod +x "$d.remote.git/hooks/pre-receive"
  (cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t \
    && git add -A && git commit -qm init && git remote add origin "$d.remote.git" && git push -q origin main) >/dev/null 2>&1
  echo "$d"
}
ver_of() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$1/plugins/autopilot/.claude-plugin/plugin.json"; }

d="$(setup)"; v="$(ver_of "$d")"; sha="$(git -C "$d" rev-parse HEAD)"
export GH_LOG="$TMPROOT/gh1.log"
out="$(cd "$d" && PATH="$FAKEBIN:$PATH" bash scripts/release.sh 2>&1)"; rc=$?
check "태그 push 거부 + gh 쓰기 가능 → 성공" test "$rc" -eq 0
check "gh release create 호출" grep -qx "create" "$GH_LOG"
check "--target 에 릴리스 커밋 sha" grep -qx "$sha" "$GH_LOG"
check "태그 이름 v$v" grep -qx "v$v" "$GH_LOG"
check ".skill 패키지 첨부" grep -qx "dist/autopilot-$v.skill" "$GH_LOG"
check "노트에 CHANGELOG 섹션" bash -c "grep -A1 -x -- '--notes' '$GH_LOG' | tail -1 | grep -q ."
check "로컬 태그 남기지 않음" test -z "$(git -C "$d" tag -l "v$v")"
check "API 경로 안내 출력" grep -q "GitHub API로 태그" <<<"$out"

d="$(setup)"; v="$(ver_of "$d")"
export GH_LOG="$TMPROOT/gh2.log"
out="$(cd "$d" && FAKE_GH_PUSH=false PATH="$FAKEBIN:$PATH" bash scripts/release.sh 2>&1)"; rc=$?
check "gh 쓰기 권한 없음 → 실패" test "$rc" -ne 0
check "gh 쓰기 권한 없음 → release 호출 안 함" test ! -e "$GH_LOG"
check "실패 시 로컬 태그 정리" test -z "$(git -C "$d" tag -l "v$v")"

finish
