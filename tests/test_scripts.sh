#!/usr/bin/env bash
# scripts/validate.sh, bump.sh, release.sh 동작 테스트
. "$(dirname "$0")/lib.sh"

ver_of() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$1/plugins/autopilot/.claude-plugin/plugin.json"; }
next_patch() { python3 -c 'import sys; a,b,c=map(int,sys.argv[1].split(".")); print(f"{a}.{b}.{c+1}")' "$1"; }
next_minor() { python3 -c 'import sys; a,b,c=map(int,sys.argv[1].split(".")); print(f"{a}.{b+1}.0")' "$1"; }

# --- validate
d="$(sandbox)"
check "validate: 현재 레포 PASS" bash "$d/scripts/validate.sh"
sedi 's/| skill [0-9.]*/| skill 0.0.1/' "$d/$SKILL_REL/SKILL.md"
check_not "validate: LOG 예시 버전 불일치 FAIL" bash "$d/scripts/validate.sh"

d="$(sandbox)"
printf '#!/usr/bin/env bash\nif then\n' > "$d/scripts/broken.sh"
check_not "validate: 문법 오류 스크립트 FAIL" bash "$d/scripts/validate.sh"

d="$(sandbox)"
python3 -c 'import re,sys; p=sys.argv[1]; s=open(p).read(); open(p,"w").write(re.sub(r"^description: .*$", "description: "+"가"*1100, s, count=1, flags=re.M))' "$d/$SKILL_REL/SKILL.md"
check_not "validate: description 1024자 초과 FAIL" bash "$d/scripts/validate.sh"

d="$(sandbox)"
rm "$d/$SKILL_REL/scripts/archive.sh"
check_not "validate: SKILL.md가 참조하는 스킬 파일이 없으면 FAIL" bash "$d/scripts/validate.sh"

# --- bump: Unreleased 항목을 버전 섹션으로
d="$(sandbox)"; cur="$(ver_of "$d")"; new="$(next_minor "$cur")"
python3 - "$d/CHANGELOG.md" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
s=re.sub(r"^## Unreleased[ \t]*\n(.*?)(?=^## )", "", s, count=1, flags=re.M|re.S)
i=s.index("\n## ")
s=s[:i+1]+"## Unreleased\n- 테스트 항목 A\n- 테스트 항목 B\n\n"+s[i+1:]
open(p,"w").write(s)
PY
check "bump minor (Unreleased 사용)" bash "$d/scripts/bump.sh" minor
check "bump: plugin.json $new" test "$(ver_of "$d")" = "$new"
check "bump: SKILL.md 본문·LOG 예시" grep -q "버전 $new" "$d/$SKILL_REL/SKILL.md"
check "bump: CHANGELOG 새 섹션에 항목 이동" python3 - "$d/CHANGELOG.md" "$new" <<'PY'
import re,sys
s=open(sys.argv[1]).read(); v=sys.argv[2]
assert re.search(r"^## Unreleased\n\n## "+re.escape(v)+r" — \d{4}-\d\d-\d\d\n- 테스트 항목 A\n- 테스트 항목 B\n", s, re.M), s[:400]
PY
check "bump 후 validate PASS" bash "$d/scripts/validate.sh"

# --- bump: Unreleased 비었고 요약도 없으면 실패, 아무 파일도 안 바뀜
cur2="$(ver_of "$d")"
check_not "bump: 항목·요약 없으면 실패" bash "$d/scripts/bump.sh" patch
check "bump 실패 시 버전 그대로" test "$(ver_of "$d")" = "$cur2"
check "bump patch (요약 사용)" bash "$d/scripts/bump.sh" patch "요약 항목"
check "bump: 요약으로 새 섹션" grep -q "^- 요약 항목" "$d/CHANGELOG.md"

# --- bump: 따옴표 붙은 버전 보존
d="$(sandbox)"; cur="$(ver_of "$d")"; new="$(next_patch "$cur")"
sedi -E "s/^(  version: )['\"]?$cur['\"]?/\1'$cur'/" "$d/$SKILL_REL/SKILL.md"
check "validate: 따옴표 버전 PASS" bash "$d/scripts/validate.sh"
check "bump: 따옴표 버전" bash "$d/scripts/bump.sh" patch "x"
check "bump: 따옴표 유지" grep -q "^  version: '$new'" "$d/$SKILL_REL/SKILL.md"
check_not "bump: 잘못된 종류 거부" bash "$d/scripts/bump.sh" huge "x"

# --- release --catch-up --dry-run: 태그 없는 릴리스 버전을 main의 릴리스 merge 커밋에 매핑
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
check "catch-up: v$v1 → 첫 릴리스 merge 커밋" grep -q "v$v1 ← $m1" <<<"$out"
check "catch-up: v$v2 → 두 번째 릴리스 merge 커밋" grep -q "v$v2 ← $m2" <<<"$out"
(cd "$d" && git tag "v$v1" "$m1")
out="$(cd "$d" && bash scripts/release.sh --catch-up --dry-run 2>&1)"
check_not "catch-up: 이미 있는 태그는 건너뜀" grep -q "v$v1 ←" <<<"$out"
check_not "release: 알 수 없는 옵션 거부" bash "$d/scripts/release.sh" --bogus

finish
