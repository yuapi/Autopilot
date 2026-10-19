#!/usr/bin/env bash
# 로컬 검증 (CI 대체). 커밋 전에 반드시 실행: bash scripts/validate.sh
# 실패 항목이 하나라도 있으면 exit 1.
set -u
cd "$(dirname "$0")/.."

SKILL_DIR="plugins/autopilot/skills/autopilot"
SKILL_MD="$SKILL_DIR/SKILL.md"
PLUGIN_JSON="plugins/autopilot/.claude-plugin/plugin.json"
MARKET_JSON=".claude-plugin/marketplace.json"
CHECKLIST="docs/open-source-checklist.md"

fail=0; warn=0
ok()   { echo "  OK    $*"; }
bad()  { echo "  FAIL  $*"; fail=$((fail + 1)); }
wrn()  { echo "  WARN  $*"; warn=$((warn + 1)); }
skip() { echo "  SKIP  $*"; }

# SKILL.md frontmatter(첫 '---' 블록)만 추출
frontmatter() { awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f' "$SKILL_MD"; }

echo "[1] JSON 파싱"
for j in "$MARKET_JSON" "$PLUGIN_JSON"; do
  if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$j" 2>/dev/null; then
    ok "$j"
  else
    bad "$j 파싱 실패"
  fi
done

echo "[2] SKILL.md frontmatter"
fm="$(frontmatter)"
name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
if [ -z "$name" ]; then bad "name 없음"
elif [ "$name" != "autopilot" ]; then bad "name이 autopilot이 아님: $name"
else ok "name: $name"; fi
desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -1)"
desc_len="$(printf '%s' "$desc" | python3 -c 'import sys; print(len(sys.stdin.read()))')"
if [ -z "$desc" ]; then
  bad "description 없음"
elif [ "$desc_len" -gt 1024 ]; then
  bad "description이 1024자를 넘음 ($desc_len자)"
else
  ok "description 존재 (${desc_len}자)"
fi

echo "[3] 버전 일치"
v_skill="$(printf '%s\n' "$fm" | sed -n "s/^[[:space:]]\{1,\}version:[[:space:]]*['\"]\{0,1\}\([0-9][0-9.]*\).*/\1/p" | head -1)"
v_plugin="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$PLUGIN_JSON" 2>/dev/null)"
v_log="$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' CHANGELOG.md | head -1)"
v_body="$(sed -n 's/^\*\*버전 \([0-9][0-9.]*\)\*\*.*/\1/p' "$SKILL_MD" | head -1)"
v_example="$(grep -m1 -oE '\| skill [0-9]+\.[0-9]+\.[0-9]+' "$SKILL_MD" | grep -oE '[0-9.]+$')"
echo "        SKILL.md metadata.version=$v_skill  본문=$v_body  LOG예시=$v_example  plugin.json=$v_plugin  CHANGELOG=$v_log"
if [ -n "$v_skill" ] && [ "$v_skill" = "$v_plugin" ] && [ "$v_skill" = "$v_log" ] && [ "$v_skill" = "$v_body" ] && [ "$v_skill" = "$v_example" ]; then
  ok "버전 일치: $v_skill"
else
  bad "버전 불일치"
fi

echo "[4] 셸 스크립트 문법 (bash -n)"
while IFS= read -r f; do
  if bash -n "$f" 2>/dev/null; then ok "$f"; else bad "$f 문법 오류"; fi
done < <(find scripts tests "$SKILL_DIR" -name '*.sh' -type f 2>/dev/null | sort)

echo "[5] claude plugin validate"
if [ -n "${AUTOPILOT_IN_TESTS:-}" ]; then
  skip "테스트 안에서는 생략"
elif command -v claude >/dev/null 2>&1; then
  if out="$(claude plugin validate . 2>&1)"; then
    printf '%s\n' "$out" | sed 's/^/        /'
    ok "claude plugin validate ."
  else
    printf '%s\n' "$out" | sed 's/^/        /'
    bad "claude plugin validate . 실패"
  fi
else
  skip "claude CLI 없음"
fi

echo "[6] 금지어 ($CHECKLIST)"
patterns="$(awk '/FORBIDDEN-PATTERNS:BEGIN/{f=1; next} /FORBIDDEN-PATTERNS:END/{f=0} f' "$CHECKLIST" \
  | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '<여기에 추가>' | grep -v '^[[:space:]]*$' || true)"
if [ -z "$patterns" ]; then
  skip "금지어 목록이 비어 있음 ($CHECKLIST 에 추가)"
else
  hits=0
  while IFS= read -r p; do
    if m="$(grep -rIniE --exclude-dir=.git --exclude-dir=dist --exclude="$(basename "$CHECKLIST")" -e "$p" . 2>/dev/null)"; then
      printf '%s\n' "$m" | sed 's/^/        /'
      bad "금지어 발견: $p"
      hits=$((hits + 1))
    fi
  done <<< "$patterns"
  [ "$hits" -eq 0 ] && ok "금지어 없음 ($(printf '%s\n' "$patterns" | wc -l | tr -d ' ')개 패턴)"
fi

echo "[7] 플레이스홀더"
ph="$(grep -rIn --exclude-dir=.git --exclude-dir=dist \
  --exclude=validate.sh --exclude="$(basename "$CHECKLIST")" \
  -e '<GITHUB_ID>' -e '<NAME>' . 2>/dev/null || true)"
if [ -n "$ph" ]; then
  printf '%s\n' "$ph" | sed 's/^/        /'
  wrn "플레이스홀더가 남아 있음"
else
  ok "플레이스홀더 없음"
fi

echo "[8] 테스트 (tests/test_*.sh)"
if [ -n "${AUTOPILOT_IN_TESTS:-}" ]; then
  skip "테스트 안에서는 생략"
else
  for t in tests/test_*.sh; do
    [ -f "$t" ] || continue
    if out="$(timeout "${AUTOPILOT_TEST_TIMEOUT:-300}" bash "$t" 2>&1)"; then
      ok "$t ($(printf '%s\n' "$out" | grep -c '^  ok') 통과)"
    else
      printf '%s\n' "$out" | grep -v '^  ok' | sed 's/^/        /'
      bad "$t"
    fi
  done
fi

echo
if [ "$fail" -gt 0 ]; then
  echo "결과: FAIL ($fail 실패, $warn 경고)"
  exit 1
fi
echo "결과: PASS ($warn 경고)"
