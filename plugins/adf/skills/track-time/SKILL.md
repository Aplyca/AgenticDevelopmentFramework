---
name: track-time
description: With the time-tracking module: draft a task's time entries since the last one logged — the AI-assisted time from the transcripts beside an estimate without AI — and write them to the tracker only once the developer approves. Use after a milestone or the merge, or when asked to log time.
argument-hint: "[tracker task link or ID] [--since <date-time>]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/track-time/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Track time

Give the team two numbers for each day of a task's work, as an internal productivity measure:

- **AI-assisted** — the time actually spent: the task's sessions, measured from the transcripts, plus
  the work done outside them, estimated from its evidence.
- **Manual estimate** — how long a senior developer would have spent on the same work without AI.

Both are **ballpark figures in whole units, rounded up**, resting on the activities actually worked
on — not a timesheet counted by the minute. The developer picks one number per entry, and only what
they approve is written. **The time tracking tool is the only record:** nothing about the time goes
into the repository, the spec folder, the pull request, or a memory. The tool also tells the skill
what's already logged, so it can run at each milestone without logging a day twice.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`).
   Unless its `modules:` list names `time-tracking`, say "this project doesn't track time — the
   time-tracking module isn't installed" and stop: offer nothing, draft nothing. Then read
   `docs/TIME-TRACKING.md`: the unit, how time entries are read and written, the labels, and the
   activities with their evidence. Placeholders left in it are questions for the developer before
   going on.

2. **Find the task and what's logged.**
   - **The task:** the argument, the spec's `tracker:` field, or the pull request's tracker link. If
     the developer isn't assigned to it, ask before going on.
   - **The branch:** `git branch --show-current`. In the main checkout of a project with the
     parallel-agents module, ask which task, and use the branch its worktree has.
   - **What's logged:** read the task's time entries with the tracker's tools — this developer's
     entries on it. The end of the latest one is where this run starts (`--since`). With none, it
     starts at the task's first session. An argument `--since` wins.

3. **Measure the sessions** with the script in this skill's directory:

   ```bash
   python3 <this skill's base directory>/session_time.py <branch> . --base <base branch> --since <date-time>
   ```

   - From any checkout of the repository, it reads the transcripts of the main checkout and every
     worktree of it, on this machine only.
   - A session counts when it ran on the branch, with the work before its move: all of it in the
     desktop app's own worktree (its generated `claude/<name>` branch), and only the run just before the
     move on the base branch. Two of the task's sessions open at once count each minute once.
     Another task's session open at the same time doesn't reduce this one's: each task gets its full time.
   - It prints each day's active time and its working blocks. `--json` gives the same in JSON. Pass
     `--siblings` when the task's worktree was already removed.

4. **Estimate the work outside the sessions,** for each day, activity by activity, from the list in
   `docs/TIME-TRACKING.md` — understanding the task, research and investigation, debugging, manual
   testing, code review, task management, reporting and stakeholder communication, meetings:
   - Look for each activity's evidence: the tracker task's comments and status changes, the pull
     request's reviews and comments (`gh pr view --json reviews,comments`), commits outside every block
     (`git log --format='%h %ad %s' --date=iso-local`), the local and preview checks the developer
     approved, stakeholder updates, and what the developer said in the sessions.
   - Estimate the activities the evidence shows, in whole units, rounded up. An activity with no
     evidence isn't in the draft.
   - Ask once, in the draft, what else the developer did outside the sessions — a call, a meeting, a
     manual test, work on another machine.

5. **Estimate the manual time** for each day: what **a senior developer** — fluent in the project's
   stack, familiar with the codebase, working without AI — would have spent on the same activities.
   - Base it on the day's work: the diff and commits, the tests, the spec and docs, the investigation
     and debugging, and the off-session activities from step 4. A meeting or a manual test takes about
     as long without AI; writing, researching, and debugging usually take longer.
   - Never below the AI-assisted number without saying why.

6. **Round and build the entries.** One entry per day worked. Each number is the day's total in
   whole units, rounded up: a day with 1h 10m in the sessions and an hour of estimated review is 3
   units at one hour (2h 10m → 3). Name the activities behind each number in a few words.

7. **Show the full draft** of the entries, as the last text of your turn:

   ```
   | # | Day | Activities | AI-assisted | Manual estimate |
   |---|-----|------------|-------------|-----------------|
   | 1 | 2026-10-14 | Understanding the task, signup form and its tests (sessions 1h 50m), manual test | 3h | 8h |
   | 2 | 2026-10-15 | Debugging the confirmation email (sessions 40m), call with the requester, PR review | 2h | 5h |
   ```

   Then the totals of each column, and the questions: **anything else done outside the sessions?**
   And for each entry: **AI-assisted, manual estimate, an edited value, or skip?** One answer may
   cover them all ("AI-assisted for all, skip 2").

8. **Write the approved entries** — ask before posting, and post only what the developer approved, in
   one go:
   - One time entry per approved day on the tracker task: the day's first block as its start, the
     chosen number of units as its duration, and the activities as its description, marked with the
     label for the number it carries.
   - Read the task's entries back and confirm they match. Report what was written, and anything that
     wasn't and why.
   - Write nothing else, anywhere: no file, commit, comment, or memory with the times. The draft
     stays in the conversation.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The project has `/adf:track-time` available, so I'll offer it" | The plugin carries it for every project. Only a stamp that names `time-tracking` turns it on. |
| "1h 10m is closer to 1 than to 2" | Numbers round up to a whole unit. A ballpark that rounds down undercounts every day. |
| "I'll log the estimate to the minute, to be precise" | The measure is a ballpark in whole units. Minutes suggest a precision the estimate doesn't have. |
| "No evidence of a meeting, but there's usually one, so I'll add an hour" | Every activity rests on evidence or on what the developer says. Ask in the draft instead. |
| "The off-session work isn't measured, so I'll leave it out" | It's part of the task's time. Estimate each activity the evidence shows, and the developer corrects it. |
| "I'll keep the breakdown in the spec folder, so the estimate is traceable" | The time tracking tool is the only record. The breakdown stays in the conversation. |
| "Last run logged until Friday, I remember" | The tracker's entries say what's logged, not the conversation. Read them each time. |
| "Two tasks ran at once, so I'll split the overlap" | Each task gets its full time; the measure is per task. |
| "The developer said log my time, so I'll post the entries now" | The request starts the draft. Show it, and post only the entries approved, with their chosen numbers. |

## Red flags (stop and reassess)

- The stamp doesn't name `time-tracking`, and you're about to draft or offer anything.
- A number with a fraction of a unit, or one rounded down.
- An activity in the draft with no evidence behind it and no word from the developer.
- An entry for a day already logged on the task.
- You're about to write a time, an estimate, or a breakdown anywhere but the time tracking tool.

## Verification

- [ ] The stamp names `time-tracking`, and `docs/TIME-TRACKING.md` was read
- [ ] The task's existing entries were read first, and the window starts after the latest one
- [ ] Session time came from the script; each off-session activity has its evidence
- [ ] One entry per day, both numbers in whole units rounded up, with the activities behind them
- [ ] The full draft was shown, and the developer chose a number, an edit, or skip for each entry
- [ ] Only the approved entries were written, each labelled with the number it carries, and read back
- [ ] Nothing about the time was written anywhere else

## Principles

- Only where the project turned it on.
- Two numbers per day, in whole units rounded up; the developer picks.
- Measured where possible, estimated from evidence where not — a ballpark, never invented.
- The time tracking tool is the only record — and the source of what's already logged.
