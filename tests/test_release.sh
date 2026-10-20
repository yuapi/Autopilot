#!/usr/bin/env bash
# scripts/release.sh real release path: when the tag push is refused, create it through the gh API instead
. "$(dirname "$0")/lib.sh"

# Fake gh: api → permission answer (FAKE_GH_PUSH), release → records its arguments
FAKEBIN="$TMPROOT/fakebin"; mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/gh" <<'SH'
#!/usr/bin/env bash
case "$1" in
  api) [ "${FAKE_GH_PUSH:-true}" = true ] && echo true || echo false;;
  release) printf '%s\n' "$@" > "$GH_LOG";;
esac
SH
chmod +x "$FAKEBIN/gh"

# A remote that refuses tag pushes, and a repository on main
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
check "tag push refused + gh can write → success" test "$rc" -eq 0
check "calls gh release create" grep -qx "create" "$GH_LOG"
check "--target is the release commit sha" grep -qx "$sha" "$GH_LOG"
check "tag name v$v" grep -qx "v$v" "$GH_LOG"
check "attaches the .skill package" grep -qx "dist/autopilot-$v.skill" "$GH_LOG"
check "notes contain the CHANGELOG section" bash -c "grep -A1 -x -- '--notes' '$GH_LOG' | tail -1 | grep -q ."
check "leaves no local tag" test -z "$(git -C "$d" tag -l "v$v")"
check "prints that the API path is used" grep -q "through the GitHub API" <<<"$out"

d="$(setup)"; v="$(ver_of "$d")"
export GH_LOG="$TMPROOT/gh2.log"
out="$(cd "$d" && FAKE_GH_PUSH=false PATH="$FAKEBIN:$PATH" bash scripts/release.sh 2>&1)"; rc=$?
check "gh cannot write → fails" test "$rc" -ne 0
check "gh cannot write → release not called" test ! -e "$GH_LOG"
check "local tag cleaned up on failure" test -z "$(git -C "$d" tag -l "v$v")"

finish
