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

# a repository with a single matching file still prints file:line; non-ASCII and spaced names are kept
d="$(mktemp -d "$TMPROOT/s1.XXXX")"; git -C "$d" init -q; echo "# TODO: only one" > "$d/한글 name.py"
out="$(bash "$SC" "$d")"
check "single file → file name in the output" grep -q "한글 name.py:1:# TODO: only one" <<<"$out"

# speed: one file list for all searches (it took minutes on a few thousand files)
d="$(mktemp -d "$TMPROOT/big.XXXX")"; git -C "$d" init -q
python3 -c 'import os,sys
for i in range(3000):
    p=os.path.join(sys.argv[1],"m%d" % (i % 30)); os.makedirs(p, exist_ok=True)
    open(os.path.join(p,"f%d.py" % i),"w").write("x = %d\n" % i + ("# TODO: big\n" if i == 2999 else ""))' "$d"
start=$(date +%s); out="$(bash "$SC" "$d")"; secs=$(( $(date +%s) - start ))
check "3000 files scanned in under 10 s (${secs}s)" test "$secs" -lt 10
check "the marker in file 3000 is found" grep -q "f2999.py:2:# TODO: big" <<<"$out"
e="$(mktemp -d "$TMPROOT/empty.XXXX")"; git -C "$e" init -q; echo "# TODO: untracked-but-ignored" > "$e/ign.py"; echo "ign.py" > "$e/.gitignore"
check_not "an empty git repository does not fall back to scanning ignored files" grep -q "untracked-but-ignored" <<<"$(bash "$SC" "$e")"

# a large section is cut off with the count left and the hits per folder; --all prints every line
d="$(mktemp -d "$TMPROOT/big.XXXX")"; git -C "$d" init -q
mkdir -p "$d/src/a" "$d/src/b" "$d/lib"
for i in $(seq 1 30); do echo "# TODO a$i" > "$d/src/a/f$i.py"; echo "# TODO b$i" > "$d/src/b/f$i.py"; done
echo "# FIXME" > "$d/lib/x.py"
out="$(bash "$SC" "$d")"
check "a section prints at most 50 lines" test "$(grep -c ':1:# \(TODO\|FIXME\)' <<<"$out")" -eq 50
check "the cut-off says how many are left" grep -q '^… 11 more line(s) (61 in total)' <<<"$out"
check "hits per folder, at the deepest level that fits" grep -qx '  src/a/: 30' <<<"$out"
check "a folder with one hit is listed too" grep -qx '  lib/: 1' <<<"$out"
check "--all prints every line" test "$(bash "$SC" --all "$d" | grep -c ':1:# ')" -eq 61
check "AUTOPILOT_SCAN_MAX changes the limit" bash -c "AUTOPILOT_SCAN_MAX=5 bash '$SC' '$d' | grep -q '^… 56 more line(s)'"
check_not "AUTOPILOT_SCAN_MAX=0 is refused" bash -c "AUTOPILOT_SCAN_MAX=0 bash '$SC' '$d'"

# subagents line: required over 20 tracked files (CONFIG subagents: on, the default), optional below, absent when off
d="$(mktemp -d "$TMPROOT/sa.XXXX")"; git -C "$d" init -q
for i in $(seq 1 21); do echo "x = $i" > "$d/m$i.py"; done; git -C "$d" add -A
check "over 20 tracked files → subagents required" bash -c "bash '$SC' '$d' | grep -q '^# subagents: required this discovery cycle (21 tracked files > 20'"
mkdir -p "$d/sub"; echo "y = 1" > "$d/sub/a.py"; git -C "$d" add -A
check "scan.sh <folder> still counts the whole repository" bash -c "bash '$SC' '$d/sub' | grep -q '(22 tracked files > 20'"
git -C "$d" rm -q --cached m21.py m20.py sub/a.py
check "20 tracked files → optional (untracked ones do not count)" bash -c "bash '$SC' '$d' | grep -q '^# subagents: optional this cycle (19 tracked files'"
git -C "$d" add -A; mkdir -p "$d/.autopilot"; printf 'subagents: off\r\n' > "$d/.autopilot/CONFIG.md"
check "subagents: off (CRLF) → scan succeeds without a subagents line" bash -c "out=\$(bash '$SC' '$d') && grep -q '^# end of scan' <<<\"\$out\" && ! grep -q '^# subagents' <<<\"\$out\""
check "subagents: off is read from the repository root when scanning a folder" bash -c "out=\$(bash '$SC' '$d/sub') && ! grep -q '^# subagents' <<<\"\$out\""
printf 'scope: sub\n' > "$d/.autopilot/CONFIG.md"
check "CONFIG scope limits the count" bash -c "bash '$SC' '$d/sub' | grep -q '^# subagents: optional this cycle (1 tracked files'"

finish
