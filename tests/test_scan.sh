#!/usr/bin/env bash
# Tests for scripts/scan.sh (deterministic markers and risky patterns)
# autopilot-scan: ignore-file
. "$(dirname "$0")/lib.sh"
SC="$REPO/$SKILL_REL/scripts/scan.sh"

d="$(mktemp -d "$TMPROOT/s.XXXX")"; git -C "$d" init -q
mkdir -p "$d/src" "$d/node_modules/x" "$d/.autopilot" "$d/tests/fixtures" "$d/docs"
cat > "$d/src/app.py" <<'PY'
import os, pickle, subprocess, yaml
# TODO: handle retries
def run(cmd):
    os.system("ls " + cmd)
    subprocess.run(cmd, shell=True)
    return eval(cmd)
def load(b):
    return pickle.loads(b), yaml.load(b)
API_KEY = "sk_live_abcdefghijklmnop"
requests_get = dict(verify=False)
def stub():
    raise NotImplementedError
x = 1  # this one is fine autopilot-scan: ignore TODO
PY
printf '// FIXME: leaks\nconst a = 1;\n' > "$d/src/app.js"
printf 'This README talks about TODO markers in prose.\n' > "$d/docs/README.md"
printf '# TODO: vendored\n' > "$d/node_modules/x/lib.py"
printf '# TODO: state\n' > "$d/.autopilot/notes.py"
printf '# TODO: seeded on purpose\n' > "$d/tests/fixtures/seed.py"
printf '# autopilot-scan: ignore-file\n# TODO: documented pattern\n' > "$d/src/patterns.py"
printf '\x00\x01binary TODO\n' > "$d/src/blob.bin"

out="$(bash "$SC" "$d")"
check "finds a comment marker in Python" grep -q "src/app.py:2:# TODO: handle retries" <<<"$out"
check "finds a comment marker in JavaScript" grep -q "src/app.js:1:// FIXME" <<<"$out"
check "finds NotImplementedError" grep -q "src/app.py:12:" <<<"$out"
check "finds os.system with concatenation" grep -q 'src/app.py:4:' <<<"$out"
check "finds shell=True" grep -q 'src/app.py:5:' <<<"$out"
check "finds eval()" grep -q 'src/app.py:6:' <<<"$out"
check "finds pickle.loads and yaml.load" grep -q 'src/app.py:8:' <<<"$out"
check "finds a hard-coded secret" grep -q 'src/app.py:9:' <<<"$out"
check "finds verify=False" grep -q 'src/app.py:10:' <<<"$out"
check_not "skips prose that mentions TODO" grep -q "docs/README.md" <<<"$out"
check_not "skips node_modules" grep -q "node_modules" <<<"$out"
check_not "skips .autopilot" grep -q ".autopilot/" <<<"$out"
check_not "skips fixtures" grep -q "fixtures" <<<"$out"
check_not "honours ignore-file" grep -q "patterns.py" <<<"$out"
check_not "honours an inline ignore" grep -q "src/app.py:13:" <<<"$out"
check_not "skips binary files" grep -q "blob.bin" <<<"$out"
check "groups findings under headings" grep -q "^## Code markers (todo)" <<<"$out"

clean="$(mktemp -d "$TMPROOT/c.XXXX")"; printf 'print("hi")\n' > "$clean/ok.py"
out="$(bash "$SC" "$clean")"
check "a clean directory prints only the frame" test "$(grep -c '^## ' <<<"$out")" -eq 0
check "works outside a git repository" grep -q "^# end of scan" <<<"$out"
check "scanning the fixture directly finds its seeded defects" bash -c "bash '$SC' '$REPO/tests/eval/fixture-todo' | grep -q 'todo.py:38'"
check_not "fails cleanly on a missing directory" bash "$SC" "$TMPROOT/nope"
check "this repository scans clean" bash -c "cd '$REPO' && test \"\$(bash '$SC' | grep -c '^## ')\" -eq 0"

finish
