#!/usr/bin/env bash
# Tests for scripts/validate.sh, bump.sh and release.sh
. "$(dirname "$0")/lib.sh"

ver_of() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$1/plugins/autopilot/.claude-plugin/plugin.json"; }
next_patch() { python3 -c 'import sys; a,b,c=map(int,sys.argv[1].split(".")); print(f"{a}.{b}.{c+1}")' "$1"; }
next_minor() { python3 -c 'import sys; a,b,c=map(int,sys.argv[1].split(".")); print(f"{a}.{b+1}.0")' "$1"; }

# --- validate
d="$(sandbox)"
check "validate: current repository passes" bash "$d/scripts/validate.sh"
sedi 's/| skill [0-9.]*/| skill 0.0.1/' "$d/$SKILL_REL/SKILL.md"
check_not "validate: mismatched LOG example version fails" bash "$d/scripts/validate.sh"

d="$(sandbox)"
printf '#!/usr/bin/env bash\nif then\n' > "$d/scripts/broken.sh"
check_not "validate: a script with a syntax error fails" bash "$d/scripts/validate.sh"

d="$(sandbox)"
# 1100 multibyte characters: the limit is counted in characters, not bytes
python3 -c 'import re,sys; p=sys.argv[1]; s=open(p).read(); open(p,"w").write(re.sub(r"^description: .*$", "description: "+"가"*1100, s, count=1, flags=re.M))' "$d/$SKILL_REL/SKILL.md"
check_not "validate: description over 1024 characters fails" bash "$d/scripts/validate.sh"

d="$(sandbox)"
rm "$d/$SKILL_REL/scripts/archive.sh"
check_not "validate: fails when a skill file SKILL.md references is missing" bash "$d/scripts/validate.sh"

# --- bump: Unreleased items become the version section
d="$(sandbox)"; cur="$(ver_of "$d")"; new="$(next_minor "$cur")"
python3 - "$d/CHANGELOG.md" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
s=re.sub(r"^## Unreleased[ \t]*\n(.*?)(?=^## )", "", s, count=1, flags=re.M|re.S)
i=s.index("\n## ")
s=s[:i+1]+"## Unreleased\n- test item A\n- test item B\n\n"+s[i+1:]
open(p,"w").write(s)
PY
check "bump minor (uses Unreleased)" bash "$d/scripts/bump.sh" minor
check "bump: plugin.json $new" test "$(ver_of "$d")" = "$new"
check "bump: SKILL.md body and LOG example" grep -q "Version $new" "$d/$SKILL_REL/SKILL.md"
check "bump: items moved to the new CHANGELOG section" python3 - "$d/CHANGELOG.md" "$new" <<'PY'
import re,sys
s=open(sys.argv[1]).read(); v=sys.argv[2]
assert re.search(r"^## Unreleased\n\n## "+re.escape(v)+r" — \d{4}-\d\d-\d\d\n- test item A\n- test item B\n", s, re.M), s[:400]
PY
check "validate passes after bump" bash "$d/scripts/validate.sh"

# --- bump: empty Unreleased and no summary → fails and changes nothing
cur2="$(ver_of "$d")"
check_not "bump: fails without items or summary" bash "$d/scripts/bump.sh" patch
check "version unchanged when bump fails" test "$(ver_of "$d")" = "$cur2"
check "bump patch (uses the summary)" bash "$d/scripts/bump.sh" patch "summary item"
check "bump: new section from the summary" grep -q "^- summary item" "$d/CHANGELOG.md"

# --- bump: keeps a quoted version quoted
d="$(sandbox)"; cur="$(ver_of "$d")"; new="$(next_patch "$cur")"
sedi -E "s/^(  version: )['\"]?$cur['\"]?/\1'$cur'/" "$d/$SKILL_REL/SKILL.md"
check "validate: quoted version passes" bash "$d/scripts/validate.sh"
check "bump: quoted version" bash "$d/scripts/bump.sh" patch "x"
check "bump: quotes kept" grep -q "^  version: '$new'" "$d/$SKILL_REL/SKILL.md"
check_not "bump: rejects an unknown kind" bash "$d/scripts/bump.sh" huge "x"

# --- release --catch-up --dry-run: maps untagged released versions to main's release merge commits
d="$(sandbox)"
(
  cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t
  git add -A && git commit -qm init
  git checkout -q -b release/x && bash scripts/bump.sh patch "r1" >/dev/null && git commit -qam r1
  git checkout -q main && git merge -q --no-ff -m "merge r1" release/x
  git checkout -q release/x && bash scripts/bump.sh patch "r2" >/dev/null && git commit -qam r2
  git checkout -q main && git merge -q --no-ff -m "merge r2" release/x
) >/dev/null 2>&1
v1="$(next_patch "$(cd "$d" && git show HEAD~2:plugins/autopilot/.claude-plugin/plugin.json | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])')")"
v2="$(next_patch "$v1")"
m1="$(cd "$d" && git rev-parse --short HEAD~1)"; m2="$(cd "$d" && git rev-parse --short HEAD)"
out="$(cd "$d" && bash scripts/release.sh --catch-up --dry-run 2>&1)"
check "catch-up: v$v1 → first release merge commit" grep -q "v$v1 ← $m1" <<<"$out"
check "catch-up: v$v2 → second release merge commit" grep -q "v$v2 ← $m2" <<<"$out"
(cd "$d" && git tag "v$v1" "$m1")
out="$(cd "$d" && bash scripts/release.sh --catch-up --dry-run 2>&1)"
check_not "catch-up: skips existing tags" grep -q "v$v1 ←" <<<"$out"
check_not "release: rejects an unknown option" bash "$d/scripts/release.sh" --bogus

# a clone with core.autocrlf=true (Windows default) still checks shell scripts out with LF
if git -C "$REPO" rev-parse HEAD >/dev/null 2>&1; then
  c="$(mktemp -d "$TMPROOT/crlf.XXXX")"
  (cd "$REPO" && git ls-files -z -- '*.sh' | tar --null -T - -cf -) | (cd "$c" && tar -xf -)
  [ ! -f "$REPO/.gitattributes" ] || cp "$REPO/.gitattributes" "$c/"
  (cd "$c" && git init -q && git config core.autocrlf true && git config user.email t@t && git config user.name t \
    && git add -A && git commit -qm x && rm -rf ./* && git checkout -q -- . ) >/dev/null 2>&1
  n="$(cd "$c" && git ls-files '*.sh' | while IFS= read -r f; do grep -l $'\r$' "$f"; done | wc -l | tr -d ' ')"
  check "autocrlf=true checkout keeps every .sh LF ($n with CRLF)" test "$n" -eq 0
  check "a script from that checkout runs" bash -c "cd '$c' && bash -n '$SKILL_REL/scripts/task.sh'"
fi

# every script answers -h/--help with its usage and exit 0, without touching anything
h="$(mktemp -d "$TMPROOT/help.XXXX")"
for f in "$REPO/$SKILL_REL"/scripts/*.sh "$REPO"/scripts/*.sh; do
  n="${f#$REPO/}"
  out="$(cd "$h" && bash "$f" --help 2>&1)"; rc=$?
  check "$n --help → exit 0" test "$rc" -eq 0
  check "$n --help shows a usage line" grep -q "bash .*$(basename "$f")" <<<"$out"
  check "$n -h works too" bash -c "cd '$h' && bash '$f' -h >/dev/null 2>&1"
done
check "--help created nothing" test -z "$(ls -A "$h")"

# a path that does not exist gets a clear message, never a raw shell error
S="$REPO/$SKILL_REL/scripts"
for c in "status.sh" "archive.sh" "workbranch.sh" "finalstop.sh" "runlock.sh start" "task.sh start T-001" "hook.sh install" "scan.sh"; do
  out="$(echo x | bash $S/${c%% *} ${c#* } /no/such/dir 2>&1)"; [ "$c" = "${c#* }" ] && out="$(bash $S/$c /no/such/dir 2>&1 </dev/null)"
  check "$c on a missing path → 'no such directory'" grep -q "no such directory: /no/such/dir" <<<"$out"
done
check "log.sh on a missing path → 'no such directory'" bash -c "echo x | bash '$S/log.sh' - discover /no/such/dir 2>&1 | grep -q 'no such directory: /no/such/dir'"

finish
