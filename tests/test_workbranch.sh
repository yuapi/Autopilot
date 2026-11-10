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

# a CONFIG typo counts as the safest value, never as "not local"
d="$(newrepo main)"; printf 'integration: prr\n' > "$d/.autopilot/CONFIG.md"
out="$(bash "$WB" "$d" 2>&1)"
check "unknown integration → treated as local, leaves main" grep -q '^autopilot/' <<<"$(branch "$d")"
check "unknown integration → says so" grep -q 'integration: prr is not local, branch or pr' <<<"$out"
d="$(newrepo main)"; printf 'local_branch: curent\n' > "$d/.autopilot/CONFIG.md"
bash "$WB" "$d" >/dev/null 2>&1
check "unknown local_branch → treated as auto, leaves main" grep -q '^autopilot/' <<<"$(branch "$d")"
d="$(newrepo main)"; printf 'integration: pr\n' > "$d/.autopilot/CONFIG.md"
out="$(bash "$WB" "$d" 2>&1)"
check "integration: pr → stays, no warning" bash -c "test '$(branch "$d")' = main && ! grep -q 'is not' <<<'$out'"

# --push: in a cloud session without integration in CONFIG, push the work branch, never a default branch
origin="$(mktemp -d "$TMPROOT/o.XXXX")"; git init -q --bare "$origin"
d="$(newrepo main)"; git -C "$d" remote add origin "$origin"
out="$(CLAUDE_CODE_REMOTE=true bash "$WB" --push "$d" 2>&1)"; rc=$?
check "--push on main → refused (exit 1)" test "$rc" -eq 1
check "--push on main → nothing pushed" test -z "$(git -C "$origin" branch --list)"
b="$(bash "$WB" "$d" 2>/dev/null | tail -1)"
out="$(CLAUDE_CODE_REMOTE=true bash "$WB" --push "$d" 2>&1)"
check "--push on the work branch in a cloud session → pushed" bash -c "grep -q 'pushed $b to origin' <<<\"\$1\" && git -C '$origin' show-ref -q --verify 'refs/heads/$b'" _ "$out"
check "--push sets the upstream" test "$(git -C "$d" rev-parse --abbrev-ref '@{u}')" = "origin/$b"
check "--push outside a cloud session → does nothing" bash -c "CLAUDE_CODE_REMOTE= bash '$WB' --push '$d' | grep -q 'not a cloud session'"
printf 'integration: local\n' > "$d/.autopilot/CONFIG.md"
check "--push with integration: local in CONFIG → does nothing" bash -c "CLAUDE_CODE_REMOTE=true bash '$WB' --push '$d' | grep -q 'CONFIG sets integration: local; not pushing'"
rm "$d/.autopilot/CONFIG.md"; git -C "$d" remote remove origin
check "--push without origin → says the commits stay here (exit 0)" bash -c "CLAUDE_CODE_REMOTE=true bash '$WB' --push '$d' 2>&1 | grep -q 'no remote named origin'"
git -C "$d" remote add origin "$TMPROOT/no-such-remote"
check_not "--push that fails → exit 1" bash -c "CLAUDE_CODE_REMOTE=true bash '$WB' --push '$d' >/dev/null 2>&1"

# the whole flow in a cloud session without integration in CONFIG: leave main, do a task, push only the work branch
origin="$(mktemp -d "$TMPROOT/of.XXXX")"; git init -q --bare "$origin"
d="$(newrepo main)"; git -C "$d" remote add origin "$origin"; git -C "$d" push -q origin main
printf '| ID | Type | Status | Attempts | Task | Done when | Source | Completed |\n| T-001 | fix | open | 0 | a | t | s | |\n' > "$d/.autopilot/BACKLOG.md"
(cd "$d" && git add -A && git commit -qm state)
b="$(bash "$WB" "$d" 2>/dev/null | tail -1)"; TS="$REPO/$SKILL_REL/scripts/task.sh"
(cd "$d" && bash "$TS" start T-001 >/dev/null && echo fix >> f && git commit -qam "autopilot(T-001): fix" && bash "$TS" done T-001 >/dev/null && git add -A && git commit -qm "autopilot: record state")
main_before="$(git -C "$origin" rev-parse main)"
CLAUDE_CODE_REMOTE=true bash "$WB" --push "$d" >/dev/null 2>&1
check "flow: the work branch with the task and its state is on origin" test "$(git -C "$origin" rev-parse "refs/heads/$b")" = "$(git -C "$d" rev-parse HEAD)"
check "flow: origin main is untouched" test "$(git -C "$origin" rev-parse main)" = "$main_before"
check "the driver says the work branch will be pushed" grep -q "after every task the work branch is pushed" "$REPO/$SKILL_REL/scripts/autopilot.sh"

finish
