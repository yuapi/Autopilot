---
description: Start the autopilot loop in this repository; with a number, stop after that many tasks (e.g. /autopilot:run 3)
argument-hint: "[number of tasks]"
---

## Run autopilot

Arguments: `$ARGUMENTS`

Use the autopilot skill (`autopilot:autopilot`) now and follow its procedure in session mode.

- If the arguments are a positive whole number N, the person asked for N tasks: claim the run with `runlock.sh start --tasks N` in Phase 0, so the loop stops after the Nth completed task.
- If there are no arguments, run until `.autopilot/STOP` exists, as the skill describes.
- Anything else in the arguments is a note from the person about what to focus on; treat it as a request, within the skill's rules.

Do not ask questions before starting.
