# Module: time-tracking

For teams that measure the time their tasks take. Adds `/track-time`, which drafts a task's time
entries — one per day worked, each with the AI-assisted time spent and an estimate of a senior
developer's time without AI, in whole units — and writes the ones the developer approves, with the
number they pick for each, to the tracker task's time entries
([decision 0043](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0043-track-time-in-the-tracker.md)).

With the module, `/wrap-up` asks whether to log the task's time before it closes up, while the
worktree is still there to measure. A project without the module doesn't track time: `/track-time`
stops there, and `/wrap-up` never asks.

## What it adds

| File | Purpose |
|---|---|
| `docs/TIME-TRACKING.md` | The project's settings — the unit, how time entries are read and written with the tracker's tools, the labels, whether they're billable — and the activities an entry covers, with the evidence `/track-time` looks for |
| `.claude/skills/track-time/` | **Committed install only:** the skill and the script that measures the sessions' time. A packaged project gets `/adf:track-time` from the `adf` plugin, which `module.json` names |

## Install

`/adopt` and `/upgrade` install it when you choose the module. By hand:

- **Committed install:** `cp -Rn modules/time-tracking/files/. /path/to/your-repo/`, then
  `scripts/build-committed.py /path/to/your-repo --modules time-tracking`, which writes `/track-time`
  from the `adf` plugin.
- **Packaged install:** `cp -Rn modules/time-tracking/files/. /path/to/your-repo/`. The skill comes
  with `adf`, already on.

Then add `time-tracking` to the `modules:` list in the stamp on `AGENTS.md`'s first line:
`/track-time` stops in a project whose stamp doesn't name it. Removing it from the stamp turns the
feature off.

## Customize

In `docs/TIME-TRACKING.md`:

1. **Unit** — a whole hour by default. Every number in a draft is a whole number of units, rounded up.
2. **Time entries** — the tracker's tools that read and write a task's time entries. With the
   `clickup` module, they're ClickUp's time-tracking tools (`/mcp` lists them): reading falls under
   its read-only allowlist, and writing prompts.
3. **Labels** — the tag or prefix that says whether an entry carries the AI-assisted time or the
   manual estimate, so reports can tell them apart.
4. **Activities** — the work the team counts, and the evidence of each.

## Good to know

- **Ballpark, not a timesheet.** Each number is rounded up to a whole unit and rests on the work the
  evidence shows. The developer edits any entry before it's written.
- **Only this machine's sessions are measured.** Work on another machine counts as off-session work.
- **Each task gets its full time.** Two tasks whose sessions overlap each count that time.

## Verify

- `head -1 AGENTS.md` names `time-tracking` in its `modules:` list, and `docs/TIME-TRACKING.md` has
  no placeholders left.
- In a task's session, `/track-time` (packaged: `/adf:track-time`) shows the draft and writes
  nothing until you approve it.
