---
description: Stop the autopilot loop in this repository after its current task (writes .autopilot/STOP)
allowed-tools: Bash(bash:*)
---

## Stopping autopilot

!`bash "${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/runlock.sh" stop 2>&1`

Tell the person, in their language and in one or two sentences, what the output above says: whether a loop was running and that it stops after its current task, or that nothing was running. Mention that invoking autopilot again resumes it. Do not run anything else and do not start or continue autopilot work.
