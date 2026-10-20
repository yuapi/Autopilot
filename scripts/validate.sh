#!/usr/bin/env bash
# Local validation (instead of CI). Run before every commit: bash scripts/validate.sh
# Exits 1 if any check fails.
set -u
cd "$(dirname "$0")/.."

SKILL_DIR="plugins/autopilot/skills/autopilot"
SKILL_MD="$SKILL_DIR/SKILL.md"
PLUGIN_JSON="plugins/autopilot/.claude-plugin/plugin.json"
MARKET_JSON=".claude-plugin/marketplace.json"
CHECKLIST="docs/open-source-checklist.md"

fail=0; warn=0

# Fallback where timeout is missing (macOS default): timeout → gtimeout → perl alarm
with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm shift; exec @ARGV or exit 127' "$secs" "$@"
  else "$@"
  fi
}
ok()   { echo "  OK    $*"; }
bad()  { echo "  FAIL  $*"; fail=$((fail + 1)); }
wrn()  { echo "  WARN  $*"; warn=$((warn + 1)); }
skip() { echo "  SKIP  $*"; }

# Extract only the SKILL.md frontmatter (the first '---' block)
frontmatter() { awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f' "$SKILL_MD"; }

echo "[1] JSON parsing"
for j in "$MARKET_JSON" "$PLUGIN_JSON"; do
  if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$j" 2>/dev/null; then
    ok "$j"
  else
    bad "$j does not parse"
  fi
done

echo "[2] SKILL.md frontmatter"
fm="$(frontmatter)"
name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -1)"
if [ -z "$name" ]; then bad "name missing"
elif [ "$name" != "autopilot" ]; then bad "name is not autopilot: $name"
else ok "name: $name"; fi
desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -1)"
desc_len="$(printf '%s' "$desc" | python3 -c 'import sys; print(len(sys.stdin.read()))')"
if [ -z "$desc" ]; then
  bad "description missing"
elif [ "$desc_len" -gt 1024 ]; then
  bad "description exceeds 1024 characters ($desc_len)"
else
  ok "description present (${desc_len} characters)"
fi

echo "[2b] Skill files referenced by SKILL.md"
refs="$(grep -oE '(assets|scripts)/[A-Za-z0-9_.-]+\.(md|sh)' "$SKILL_MD" | sort -u)"
missing=0
for r in $refs; do
  [ -f "$SKILL_DIR/$r" ] || { bad "references a missing file: $r"; missing=1; }
done
[ "$missing" -eq 0 ] && ok "all $(printf '%s\n' "$refs" | grep -c .) references exist"
for f in $(cd "$SKILL_DIR" && find assets scripts -type f | sort); do
  printf '%s\n' "$refs" | grep -qxF "$f" || wrn "skill file not mentioned in SKILL.md: $f"
done

echo "[3] Versions match"
v_skill="$(printf '%s\n' "$fm" | sed -n "s/^[[:space:]]\{1,\}version:[[:space:]]*['\"]\{0,1\}\([0-9][0-9.]*\).*/\1/p" | head -1)"
v_plugin="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version",""))' "$PLUGIN_JSON" 2>/dev/null)"
v_log="$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' CHANGELOG.md | head -1)"
v_body="$(sed -n 's/^\*\*Version \([0-9][0-9.]*\)\*\*.*/\1/p' "$SKILL_MD" | head -1)"
v_example="$(grep -m1 -oE '\| skill [0-9]+\.[0-9]+\.[0-9]+' "$SKILL_MD" | grep -oE '[0-9.]+$')"
echo "        SKILL.md metadata.version=$v_skill  body=$v_body  LOG example=$v_example  plugin.json=$v_plugin  CHANGELOG=$v_log"
if [ -n "$v_skill" ] && [ "$v_skill" = "$v_plugin" ] && [ "$v_skill" = "$v_log" ] && [ "$v_skill" = "$v_body" ] && [ "$v_skill" = "$v_example" ]; then
  ok "versions match: $v_skill"
else
  bad "versions differ"
fi

echo "[4] Shell syntax (bash -n)"
while IFS= read -r f; do
  if bash -n "$f" 2>/dev/null; then ok "$f"; else bad "$f has a syntax error"; fi
done < <(find scripts tests "$SKILL_DIR" -name '*.sh' -type f 2>/dev/null | sort)

echo "[5] claude plugin validate"
if [ -n "${AUTOPILOT_IN_TESTS:-}" ]; then
  skip "skipped inside tests"
elif command -v claude >/dev/null 2>&1; then
  if out="$(claude plugin validate . 2>&1)"; then
    printf '%s\n' "$out" | sed 's/^/        /'
    ok "claude plugin validate ."
  else
    printf '%s\n' "$out" | sed 's/^/        /'
    bad "claude plugin validate . failed"
  fi
else
  skip "no claude CLI"
fi

echo "[6] Forbidden patterns ($CHECKLIST)"
patterns="$(awk '/FORBIDDEN-PATTERNS:BEGIN/{f=1; next} /FORBIDDEN-PATTERNS:END/{f=0} f' "$CHECKLIST" \
  | grep -v '^```' | grep -v '^[[:space:]]*#' | grep -v '<add here>' | grep -v '^[[:space:]]*$' || true)"
if [ -z "$patterns" ]; then
  skip "forbidden pattern list is empty (add them to $CHECKLIST)"
else
  hits=0
  while IFS= read -r p; do
    if m="$(grep -rIniE --exclude-dir=.git --exclude-dir=dist --exclude="$(basename "$CHECKLIST")" -e "$p" . 2>/dev/null)"; then
      printf '%s\n' "$m" | sed 's/^/        /'
      bad "forbidden pattern found: $p"
      hits=$((hits + 1))
    fi
  done <<< "$patterns"
  [ "$hits" -eq 0 ] && ok "no forbidden patterns ($(printf '%s\n' "$patterns" | wc -l | tr -d ' ') patterns)"
fi

echo "[7] Placeholders"
ph="$(grep -rIn --exclude-dir=.git --exclude-dir=dist \
  --exclude=validate.sh --exclude="$(basename "$CHECKLIST")" \
  -e '<GITHUB_ID>' -e '<NAME>' . 2>/dev/null || true)"
if [ -n "$ph" ]; then
  printf '%s\n' "$ph" | sed 's/^/        /'
  wrn "placeholders remain"
else
  ok "no placeholders"
fi

echo "[8] Tests (tests/test_*.sh)"
if [ -n "${AUTOPILOT_IN_TESTS:-}" ]; then
  skip "skipped inside tests"
else
  for t in tests/test_*.sh; do
    [ -f "$t" ] || continue
    started=$(date +%s)
    if out="$(with_timeout "${AUTOPILOT_TEST_TIMEOUT:-300}" bash "$t" 2>&1)"; then
      ok "$t ($(printf '%s\n' "$out" | grep -c '^  ok') passed, $(( $(date +%s) - started ))s)"
    else
      printf '%s\n' "$out" | grep -v '^  ok' | sed 's/^/        /'
      bad "$t"
    fi
  done
fi

echo
if [ "$fail" -gt 0 ]; then
  echo "Result: FAIL ($fail failed, $warn warnings)"
  exit 1
fi
echo "Result: PASS ($warn warnings)"
