#!/usr/bin/env bash
# Tests for scripts/workbranch.sh (keeps local mode off default branches)
. "$(dirname "$0")/lib.sh"
WB="$REPO/$SKILL_REL/scripts/workbranch.sh"

newrepo() {
  local d; d="$(mktemp -d "$TMPROOT/w.XXXX")"
  (cd "$d" && git init -q -b "${1:-main}" && git config user.email t@t && git config user.name t \
    && mkdir .autopilot && echo x > f && git add -A && git commit -qm init)
  echo "$d"
}
branch() { git -C "$1" symbolic-ref --short -q HEAD || echo DETACHED; }

d="$(newrepo main)"; echo dirty >> "$d/f"
out="$(bash "$WB" "$d" 2>/dev/null)"
check "on main → creates an autopilot/ branch" grep -qE '^autopilot/[0-9]{8}-[0-9]{4}$' <<<"$(branch "$d")"
check "prints the new branch" test "$out" = "$(branch "$d")"
check "uncommitted changes come along" grep -qx dirty <(tail -1 "$d/f")
check "main itself is untouched" test "$(git -C "$d" rev-parse main)" = "$(git -C "$d" rev-parse HEAD)"
b1="$(branch "$d")"
bash "$WB" "$d" >/dev/null 2>&1
check "already on a work branch → stays (idempotent)" test "$(branch "$d")" = "$b1"
check "only one autopilot branch" test "$(git -C "$d" branch --list 'autopilot/*' | wc -l)" -eq 1

for b in master develop trunk; do
  d="$(newrepo "$b")"; bash "$WB" "$d" >/dev/null 2>&1
  check "on $b → creates an autopilot/ branch" grep -q '^autopilot/' <<<"$(branch "$d")"
done

d="$(newrepo main)"; git -C "$d" checkout -q -b my-feature
bash "$WB" "$d" >/dev/null 2>&1
check "on a person's own branch → stays" test "$(branch "$d")" = my-feature

d="$(newrepo main)"; git -C "$d" checkout -q --detach
bash "$WB" "$d" >/dev/null 2>&1
check "detached HEAD → creates an autopilot/ branch" grep -q '^autopilot/' <<<"$(branch "$d")"

# remote default branch with an unusual name
d="$(newrepo prod)"; r="$TMPROOT/remote.$$.git"; git init -q --bare "$r"
(cd "$d" && git remote add origin "$r" && git push -q origin prod && git remote set-head origin prod) >/dev/null 2>&1
bash "$WB" "$d" >/dev/null 2>&1
check "on the remote's default branch → creates an autopilot/ branch" grep -q '^autopilot/' <<<"$(branch "$d")"

# same minute twice: unique names
d="$(newrepo main)"; bash "$WB" "$d" >/dev/null 2>&1; git -C "$d" checkout -q main
bash "$WB" "$d" >/dev/null 2>&1
check "second branch in the same minute gets a suffix" test "$(git -C "$d" branch --list 'autopilot/*' | wc -l)" -eq 2

d="$(newrepo main)"; printf '```\nlocal_branch: current\n```\n' > "$d/.autopilot/CONFIG.md"
bash "$WB" "$d" >/dev/null 2>&1
check "local_branch: current → stays on main" test "$(branch "$d")" = main

d="$(newrepo main)"; printf '```\nintegration: pr\n```\n' > "$d/.autopilot/CONFIG.md"
bash "$WB" "$d" >/dev/null 2>&1
check "pr mode → leaves branching to the integration policy" test "$(branch "$d")" = main

d="$(newrepo main)"; mkdir -p "$d/sub"
bash "$WB" "$d/sub" >/dev/null 2>&1
check "works from a subfolder" grep -q '^autopilot/' <<<"$(branch "$d")"

check_not "fails outside a git repository" bash "$WB" "$(mktemp -d "$TMPROOT/n.XXXX")"

finish
