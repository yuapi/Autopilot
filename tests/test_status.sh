#!/usr/bin/env bash
# scripts/status.sh (실행 상태 요약) 테스트
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
check "작업 수 집계 (아카이브 포함)" grep -q "open 1 · in progress 1 · done 2 · blocked 1" <<<"$out"
check "실행 상태: 대기" grep -q "Run: idle" <<<"$out"
check "통합 설정·언어 표시" grep -q "integration=pr, merge=auto, release=off, language=ko" <<<"$out"
check "영어 상태 proposed 제안 표시" grep -q "P-003 Switch config format" <<<"$out"
check_not "adopted 제안은 표시 안 함" grep -q "P-004" <<<"$out"
check "최근 성공률은 작업 항목만 셈 (1/2)" grep -q "Success rate of the last 2 runs: 1/2" <<<"$out"
check "열린 작업에 진행 중 포함" grep -q "T-004 \[test\]" <<<"$out"
check "blocked 목록" grep -q "T-002 \[feature\] 막힌 기능" <<<"$out"
check "결정 대기 제안만 표시" grep -q "P-001 설정 파일 형식 변경" <<<"$out"
check_not "거절된 제안은 표시 안 함" grep -q "P-002" <<<"$out"

touch "$d/.autopilot/RUN"
check "RUN 있으면 진행 중" bash -c "bash '$ST' '$d' | grep -q 'Run: running'"
printf '최종 중단: 실질 작업 없음\n- 사이클: 3회\n' > "$d/.autopilot/STOP"
out="$(bash "$ST" "$d/sub" 2>&1)"
check "STOP 있으면 멈춤과 사유 첫 줄" grep -q "Run: stopped — 최종 중단: 실질 작업 없음" <<<"$out"
check "STOP 전체 내용 표시" grep -q "사이클: 3회" <<<"$out"
check "하위 폴더에서도 레포 루트 기준" grep -q "autopilot status — $d" <<<"$out"

mkdir -p "$d/.claude/hooks"
cp "$REPO/$SKILL_REL/assets/autopilot-stop.sh" "$d/.claude/hooks/autopilot-stop.sh"
check_not "새 훅이면 구버전 경고 없음" bash -c "bash '$ST' '$d' | grep -q 'old (1.5.x)'"
printf '#!/usr/bin/env bash\nif [ -f .autopilot/STOP ]; then exit 0; fi\necho block\n' > "$d/.claude/hooks/autopilot-stop.sh"
check "구버전 훅이면 경고와 교체 안내" bash -c "bash '$ST' '$d' | grep -q 'old (1.5.x) Stop hook'"
rm -rf "$d/.claude"

check "출력이 중간에 끊겨도 오류 없음" test -z "$({ bash "$ST" "$d" | head -1 >/dev/null; } 2>&1)"

rm "$d/.autopilot/CONFIG.md"
check "CONFIG 없으면 local" bash -c "bash '$ST' '$d' | grep -q 'local (no CONFIG)'"
e="$(mktemp -d "$TMPROOT/e.XXXX")"
check_not ".autopilot 없으면 실패" bash "$ST" "$e"
before="$(cat "$d"/.autopilot/* | cksum)"; bash "$ST" "$d" >/dev/null 2>&1
check "상태 파일을 바꾸지 않음" test "$(cat "$d"/.autopilot/* | cksum)" = "$before"

finish
