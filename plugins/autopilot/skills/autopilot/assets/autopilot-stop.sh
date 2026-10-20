#!/usr/bin/env bash
# autopilot Stop hook (session mode).
# - Acts only while .autopilot/RUN exists, and only on the session that owns it (the "session:" line
#   in RUN, matched against the session_id Claude Code passes on stdin). Other sessions are never blocked.
# - If .autopilot/STOP exists, removes RUN and lets the session end.
# - After AUTOPILOT_STALL_LIMIT (default 3) consecutive blocks with no change to the LOG
#   or commits, writes STOP and lets the session end (no endless blocking without progress).
# - The skill's frontmatter hook and an older repository copy may both run for the same stop. The
#   transcript size tells them apart: same size = same stop, so it is counted once.
# Release: create .autopilot/STOP, delete .autopilot/RUN, or remove this hook from settings.json
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
A=.autopilot
[ -f "$A/RUN" ] || exit 0
# Claude Code passes JSON on stdin and closes it. Never wait on a terminal, and give up after 2 s
# on a pipe that stays open, so the hook can never hang.
input=""
[ -t 0 ] || IFS= read -r -d '' -t 2 input || true
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
tpath="$(printf '%s' "$input" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
tsz=""; [ -n "$tpath" ] && [ -f "$tpath" ] && tsz="$(wc -c < "$tpath" | tr -d ' ')"
owner="$(sed -n 's/^session:[[:space:]]*//p' "$A/RUN" | head -1)"
if [ -n "$owner" ] && [ "$owner" != unknown ] && [ -n "$sid" ] && [ "$sid" != "$owner" ]; then
  exit 0
fi
if [ -f "$A/STOP" ]; then
  rm -f "$A/RUN" "$A/.hook-state"
  exit 0
fi

sig="$({ cat "$A/LOG.md" 2>/dev/null; git rev-parse HEAD 2>/dev/null; } | cksum | cut -d' ' -f1)"
prev=""; n=0; ptsz=""
if [ -f "$A/.hook-state" ]; then read -r prev n ptsz < "$A/.hook-state" || true; fi
case "$n" in ''|*[!0-9]*) n=0;; esac
if [ "$sig" != "$prev" ]; then n=0
elif [ -z "$tsz" ] || [ "$tsz" != "$ptsz" ]; then n=$((n + 1))
fi

limit="${AUTOPILOT_STALL_LIMIT:-3}"
if [ "$n" -ge "$limit" ]; then
  {
    echo "Final stop: no progress"
    echo "- The Stop hook blocked ending the session ${n} times in a row, but LOG.md and the commits did not change"
    echo "- Work may be stuck on permission denials or an environment problem. Check the last LOG entry"
  } > "$A/STOP"
  rm -f "$A/RUN" "$A/.hook-state"
  exit 0
fi
printf '%s %s%s\n' "$sig" "$n" "${tsz:+ $tsz}" > "$A/.hook-state"

cat << 'JSON'
{"decision":"block","reason":"autopilot session mode. Re-read the .autopilot/ state files and do the next task. If the queue is empty, start with rediscovery (including the product axis). Go straight on, no summary or report."}
JSON
exit 0
