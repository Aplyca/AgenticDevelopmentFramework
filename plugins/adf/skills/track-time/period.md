# Track time for a day or a week

`/adf:track-time day [<date>]` or `week [<date>]`: a review across tasks, for a team that logs its
time by the day or the week. It drafts each task's outcomes in the period as steps 4 to 8 do for one
task, then adds a row for each day with the time actually spent, and one for the period. Each task
keeps its full time, as always. The day's row counts a minute that two tasks shared only once.

## The period and what's logged (in place of step 2)

- **The days:** `day` is that date, or today without one. `week` is the week holding that date, or
  this week up to today: Monday to Sunday, unless `docs/TIME-TRACKING.md` § Settings names another
  first day.
- **What's logged:** read the developer's time entries in the period with the tracker's tools —
  across tasks where the tools can, else each task's once the next step finds it. An outcome with an
  entry is logged.
- **Each task's window:** the period, starting after the task's latest entry when that ends later.

## Measure every task's sessions (in place of step 3)

```bash
python3 <this skill's base directory>/period_time.py <first day> <last day> --project . --base <base branch>
```

- It finds every branch a session ran on in the period, except the base branch, and measures each
  one as step 3's script measures a task. A session that moved off the app's generated branch counts
  for the branch it moved to. Sessions only on the base branch aren't any task's.
- For each day it prints each branch's active time and blocks, the day's active time with each
  minute counted once, and the overlap: how far the branches' times add up beyond the day's.
  `--json` gives the same in JSON.
- **Each branch's task:** the `tracker:` field of the spec on that branch, or the tracker link in the
  pull request opened from it (`gh pr list --head <branch> --state all --json number,body`; on
  GitLab, `glab mr list --source-branch <branch>`). A branch with neither is a question for the
  developer. One they leave out, as work with no task, isn't in the review: run the script again
  with `--branch <branch>` for each branch kept, so the day's figures cover only the tasks in it.
- Ask before going on for a task the developer isn't assigned to, as in step 2.

## Each task's rows (steps 4 to 8)

One row per task and outcome, built by steps 4 to 8 from that branch's blocks in the script's output.
The period's end is a cutoff: work toward an outcome not delivered by then is an outcome of its own
for this period — what it found, settled, or unblocked — so the period's time is whole. An outcome
already logged keeps its row, with its three numbers, so the period's figures are whole too. Its
Logged column shows the entry the tracker holds, and it gets no pick.

## The day's row and the period's

- **Each day — AI-assisted only:** the day's active time from the script, plus each task's work
  outside the sessions that day, rounded up once to a whole unit. An activity for several tasks,
  such as a meeting about two of them, counts once. A day has no midpoint or manual estimate of its
  own: those belong to outcomes, which may span days.
- **The period — all three numbers:**
  - **AI-assisted:** the sum of its days.
  - **Manual estimate:** the sum of the tasks' estimates. Without AI, a developer works on one task
    at a time.
  - **Midpoint:** the sum of the tasks' midpoints. Like the manual estimate, it rates the work, and
    each task's work is worth its midpoint whether or not it ran beside another. It always lies
    between the period's other two numbers.
- **The overlap:** when the tasks' sessions overlapped, their AI-assisted rows add up to more than
  the period's. Say by how much, in whole units, from the script's overlap.

## Show the draft (in place of step 9)

```
| # | Task | Delivered | Description | Activities | AI-assisted | Midpoint | Manual estimate | Logged |
|---|------|-----------|-------------|------------|-------------|----------|-----------------|--------|
| 1 | Menu keyboard access | 2026-10-14 | Keyboard users can open the site menu and reach every link in it | Focus handling and its tests (sessions 2h) | 2h | 3h | 4h | — |
| 2 | Newsletter signup | 2026-10-15 | Readers can subscribe to the newsletter from the article they're reading | Understanding the task, signup form and its tests (sessions 2h over two days), manual test | 3h | 6h | 8h | — |
| 3 | Newsletter signup | 2026-10-16 | New subscribers get their confirmation email; the requester confirmed it on the preview | Debugging the confirmation email (sessions 1h), call with the requester, PR review | 2h | 4h | 5h | AI-assisted 2h |
|   | **The days** | | | 2026-10-14: 2h, 1h of the sessions on both tasks at once · 2026-10-15: 2h · 2026-10-16: 2h | | | | |
|   | **Week** | | | Tasks' rows add up to 1h more, shared on 2026-10-14 | **6h** | **13h** | **17h** | |
```

Then step 9's questions, for each row not logged yet. The days' and the period's rows aren't
entries: step 10 writes each approved row on its own task, and nothing for them.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The day's AI-assisted total is the sum of its tasks" | Tasks whose sessions overlapped each keep that time, so the sum counts it twice. The day takes the script's active time, each minute once. |
| "Two tasks ran at once, so I'll split the overlap between their rows" | Each task keeps its full time. Only the days' and the period's rows count the overlap once. |
| "The manual estimates overlap too, so I'll count them once" | Without AI, the tasks' work runs one at a time. The period's estimate is their sum. |
| "The midpoint should count the overlap once, like the AI-assisted time" | The midpoint rates the work, as the manual estimate does. Only the time actually spent counts a shared minute once. |
| "I'll give each day a manual estimate too" | Outcomes span days, so their estimates don't split by day. Days carry the time spent; the period carries all three numbers. |
| "This branch has no task, so I'll log its time to the nearest one" | Ask. A branch the developer leaves out isn't in the review, and its time goes on no task. |

## Red flags (stop and reassess)

- The period's AI-assisted total above the sum of its tasks' rows.
- A period midpoint outside its AI-assisted time and manual estimate.
- A day's row or the period's about to be written as an entry.
- A row for a branch with no tracker task.
- A day's figures that still count a branch the developer left out.
- A time in the days' or the period's rows with a half unit, a decimal, or minutes.
