#!/usr/bin/env bash
# Tests for scripts/status.sh (run status summary). The fixture mixes Korean legacy values on purpose
. "$(dirname "$0")/lib.sh"
ST="$REPO/$SKILL_REL/scripts/status.sh"

d="$(mktemp -d "$TMPROOT/s.XXXX")"
(cd "$d" && git init -q)
mkdir -p "$d/.autopilot" "$d/sub"
cat > "$d/.autopilot/BACKLOG.md" <<'MD'
| ID | 유형 | 상태 | 시도 | 작업 | 완료 기준 | 출처 | 완료일 |
|---|---|---|---|---|---|---|---|
| T-001 | fix | done | 1 | 고친 것 | 기준 | 출처 | 2026-01-01 |
| T-002 | feature | blocked | 3 | 막힌 기능 | 기준 | 출처 | |
| T-003 | enhance | open | 1 | 열린 개선 | 기준 | 출처 | |
| T-004 | test | in_progress | 1 | 진행 중 테스트 | 기준 | 출처 | |
MD
printf '| T-000 | fix | done | 1 | 옛 작업 | 기준 | 출처 | 2025-01-01 |\n' > "$d/.autopilot/BACKLOG.archive.md"
cat > "$d/.autopilot/LOG.md" <<'MD'
# LOG
## 2026-01-01T00:00 | T-001 | done | skill 1.0.0
## 2026-01-01T01:00 | T-002 | failed | skill 1.0.0
## 2026-01-01T02:00 | - | retro | skill 1.0.0
MD
cat > "$d/.autopilot/PROPOSALS.md" <<'MD'
| ID | 상태 | 제목 | 문제·근거 | 제안 | 대안 | 영향·호환성 | 비용(작업 수) | 위험 | 날짜 |
|---|---|---|---|---|---|---|---|---|---|
| P-001 | 제안 | 설정 파일 형식 변경 | a | b | c | d | 3 | e | 2026-01-01 |
| P-002 | 거절 | 거절된 것 | a | b | c | d | 1 | e | 2026-01-01 |
| P-003 | proposed | Switch config format | a | b | c | d | 2 | e | 2026-01-02 |
| P-004 | adopted | Adopted one | a | b | c | d | 1 | e | 2026-01-02 |
MD
printf '```\nintegration: pr\nmerge: auto\nrelease: off\nlanguage: ko\n```\n' > "$d/.autopilot/CONFIG.md"

out="$(bash "$ST" "$d" 2>&1)"
check "task counts (including the archive)" grep -q "open 1 · in progress 1 · done 2 · blocked 1" <<<"$out"
check "run state: idle" grep -q "Run: idle" <<<"$out"
check "shows integration and language" grep -q "integration=pr, merge=auto, release=off, language=ko" <<<"$out"
check "shows English proposed status" grep -q "P-003 Switch config format" <<<"$out"
check_not "hides adopted proposals" grep -q "P-004" <<<"$out"
check "success rate counts task entries only (1/2)" grep -q "Success rate of the last 2 runs: 1/2" <<<"$out"
check "open tasks include in_progress" grep -q "T-004 \[test\]" <<<"$out"
check "blocked list" grep -q "T-002 \[feature\] 막힌 기능" <<<"$out"
check "shows legacy Korean proposed status (제안)" grep -q "P-001 설정 파일 형식 변경" <<<"$out"
check_not "hides rejected proposals" grep -q "P-002" <<<"$out"

touch "$d/.autopilot/RUN"
check "RUN → running" bash -c "bash '$ST' '$d' | grep -q 'Run: running'"
printf 'session: abc-123\nstarted: 2026-01-01T00:00:00Z\n' > "$d/.autopilot/RUN"
check "shows the owning session and last activity" bash -c "bash '$ST' '$d' | grep -q 'session abc-123, last active 0 min ago'"
python3 -c 'import os,time; t=time.time()-3*3600; os.utime("'"$d"'/.autopilot/RUN",(t,t))'
check "flags an abandoned RUN" bash -c "bash '$ST' '$d' | grep -q 'a new run will take it over'"
printf '최종 중단: 실질 작업 없음\n- 사이클: 3회\n' > "$d/.autopilot/STOP"
out="$(bash "$ST" "$d/sub" 2>&1)"
check "STOP → stopped with the first line of the reason" grep -q "Run: stopped — 최종 중단: 실질 작업 없음" <<<"$out"
check "shows the full STOP content" grep -q "사이클: 3회" <<<"$out"
check "works from a subfolder" grep -q "autopilot status — $d" <<<"$out"

mkdir -p "$d/.claude/hooks"
cp "$REPO/$SKILL_REL/assets/autopilot-stop.sh" "$d/.claude/hooks/autopilot-stop.sh"
check_not "no old-hook warning for the new hook" bash -c "bash '$ST' '$d' | grep -q 'old (1.5.x)'"
printf '#!/usr/bin/env bash\nif [ -f .autopilot/STOP ]; then exit 0; fi\necho block\n' > "$d/.claude/hooks/autopilot-stop.sh"
check "old hook → warning and how to replace it" bash -c "bash '$ST' '$d' | grep -q 'old (1.5.x) Stop hook'"
rm -rf "$d/.claude"

check "no error when the output is cut off" test -z "$({ bash "$ST" "$d" | head -1 >/dev/null; } 2>&1)"

rm "$d/.autopilot/CONFIG.md"
check "no CONFIG → local" bash -c "bash '$ST' '$d' | grep -q 'local (no CONFIG)'"
e="$(mktemp -d "$TMPROOT/e.XXXX")"
check_not "fails without .autopilot" bash "$ST" "$e"
before="$(cat "$d"/.autopilot/* | cksum)"; bash "$ST" "$d" >/dev/null 2>&1
check "does not modify state files" test "$(cat "$d"/.autopilot/* | cksum)" = "$before"

# installed skill version, and a warning when the LOG was written by a newer one
mine="$(sed -n 's/^  version: //p' "$REPO/$SKILL_REL/SKILL.md")"
d="$(mktemp -d "$TMPROOT/v.XXXX")"; git -C "$d" init -q; mkdir -p "$d/.autopilot"
printf '# LOG\n## 2026-01-01T00:00 | T-001 | done | skill %s\n' "$mine" > "$d/.autopilot/LOG.md"
out="$(bash "$ST" "$d")"
check "shows the installed skill version" grep -q "^Skill: $mine\$" <<<"$out"
check_not "same version → no warning" grep -q "newer than the installed" <<<"$out"
printf '## 2026-01-02T00:00 | T-002 | done | skill 99.0.0\n' >> "$d/.autopilot/LOG.md"
out="$(bash "$ST" "$d")"
check "LOG from a newer skill → warning" grep -q "already run with skill 99.0.0, newer than the installed $mine" <<<"$out"
printf '# LOG\n## 2026-01-01T00:00 | T-001 | done | skill 1.0.0\n' > "$d/.autopilot/LOG.md"
out="$(bash "$ST" "$d")"
check "LOG from an older skill → noted, no warning" bash -c "grep -q 'LOG written up to 1.0.0' <<<\"\$1\" && ! grep -q 'newer than' <<<\"\$1\"" _ "$out"

finish
