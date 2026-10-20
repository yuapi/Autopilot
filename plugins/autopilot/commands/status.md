---
description: Show what autopilot is doing in this repository (running or stopped, tasks, proposals awaiting a decision)
allowed-tools: Bash(bash:*)
---

## autopilot status

!`bash "${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/status.sh" 2>&1`

Show the status above to the person exactly as printed, in a code block. After it, add at most two short sentences in the person's language: what needs their attention (blocked tasks, proposals awaiting a decision, a STOP reason), or that nothing does. Do not run anything else.
