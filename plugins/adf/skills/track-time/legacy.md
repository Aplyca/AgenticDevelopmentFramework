# Legacy — an older release's Unit setting and worktrees

`/adf:track-time` reads this when a project or a task predates a change the skill now relies on: a
**Unit** line left in `docs/TIME-TRACKING.md` (step 1), or a task whose worktree sat beside the main
checkout and was already removed (step 3).

## A Unit setting (step 1)

Before decision 0094, `docs/TIME-TRACKING.md` set the unit, an hour by default. A **Unit** line a
project kept is no longer read.

| Agent says... | Why it's wrong |
|---|---|
| "The project's docs set the unit to 30 minutes, so I'll use half hours" | The unit is one hour in every project. Round up to whole hours, and say the setting is no longer read. |

## A worktree beside the main checkout (step 3)

Pass `--siblings` for a task whose worktree sat beside the main checkout, as before decision 0083,
and was already removed.
