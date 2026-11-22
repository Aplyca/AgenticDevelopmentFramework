---
name: track-time
description: With the time-tracking module: draft a task's time entries since the last one logged — one per outcome delivered (a milestone, a completed task, value delivered), each with the AI-assisted time from the transcripts, a senior developer's estimate without AI, and a midpoint between them set by the activities — and write them to the tracker only on the developer's yes. Use after a milestone, significant partial work, or the merge, or when asked to log, track, or report the time spent on a task.
argument-hint: "[tracker task link or ID] [--since <date-time>]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/track-time/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Track time

Give the team three numbers for each outcome of a task's work, as an internal productivity measure:

- **AI-assisted** — the time actually spent: the task's sessions, measured from the transcripts, plus
  the work done outside them, estimated from its evidence.
- **Manual estimate** — how long a senior developer would have spent on the same work without AI.
- **Midpoint** — a reasonable time for the work, between the two, set activity by activity: a
  meeting counts as spent, debugging sits nearer the manual estimate, routine code nearer the
  AI-assisted time.

**An entry is an outcome, not a session or a day:** a milestone reached, a completed task of the
plan, value delivered to the people the task serves — or, for work that delivered nothing yet, what
it found, settled, or unblocked. An outcome that took three days is one entry; two outcomes in one
afternoon are two.

The numbers are **ballpark figures**, resting on the activities actually worked on — not a
timesheet counted by the minute. **The unit is one hour, in every project:** it isn't a setting, so
every team's entries compare. **Every time the draft shows and every entry carries is in whole
hours, rounded up** — never a half hour, a decimal, or minutes.
The developer picks one number per entry, and only what they approve is written. **The time tracking tool is the only record:** nothing about the time
goes into the repository, the spec folder, the pull request, or a memory. The tool also tells the
skill what's already logged, so it can run at each milestone without logging an outcome twice.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`).
   Unless its `modules:` list names `time-tracking`, say "this project doesn't track time — the
   time-tracking module isn't installed" and stop: offer nothing, draft nothing. Then read
   `docs/TIME-TRACKING.md`: how time entries are read and written, the labels, the
   activities with their evidence and where each one's midpoint sits, and any convention for the
   descriptions. Placeholders left in it are questions for the developer before going on. A
   **Unit** line left in it from an older release isn't read — say so
   (`<this skill's base directory>/legacy.md`).

2. **Find the task and what's logged.**
   - **The task:** the argument, the spec's `tracker:` field, or the pull request's tracker link. If
     the developer isn't assigned to it, ask before going on.
   - **The branch:** `git branch --show-current`. In the main checkout of a project with the
     parallel-agents module, ask which task, and use the branch its worktree has.
   - **What's logged:** read the task's time entries with the tracker's tools — this developer's
     entries on it. Each entry ends at its outcome's delivery (step 9), so the end of the latest one
     is where this run starts (`--since`). With none, it starts at the task's first session. An
     argument `--since` wins.

3. **Measure the sessions** with the script in this skill's directory:

   ```bash
   python3 <this skill's base directory>/session_time.py <branch> . --base <base branch> --since <date-time>
   ```

   - From any checkout of the repository, it reads the transcripts of the main checkout and every
     worktree of it, on this machine only.
   - A session counts when it ran on the branch, with the work before its move: all of it in the
     desktop app's own worktree (its generated branch, `claude/<name>` or `worktree-<name>`), and only the run just before the
     move on the base branch. Two of the task's sessions open at once count each minute once.
     Another task's session open at the same time doesn't reduce this one's: each task gets its full time.
   - It prints each day's active time and its working blocks, with their start and end. `--json`
     gives the same in JSON. A task whose worktree sat beside the main checkout and was already
     removed needs one more flag: `<this skill's base directory>/legacy.md`.

4. **Find the outcomes** the window delivered, and when each was delivered:
   - **Where they show:** the spec's `tasks.md` — the tasks ticked in the window, with the acceptance
     criteria they serve; the tracker task's subtasks, checklist items, or milestones closed; the
     pull request opened, approved, accepted on the preview, or merged; the commits
     (`git log --format='%h %ad %s' --date=iso-local`); and what the developer said in the sessions.
   - **What one is:** the smallest piece the people the task serves would recognize as done or
     settled. Tasks that deliver only together — a story's tasks and their test — are one outcome; a
     task that delivers on its own is one. A commit, a session, or a day is never one.
   - **Its delivery:** the moment it was done — the commit that ticked its last task, the approval,
     the merge.
   - **Assign the time:** each working block goes to the outcome it served, by the commits it made
     and the tasks it ticked. A block that served two is split by what it did; each minute counts
     once.
   - **And to its activity,** from the list in `docs/TIME-TRACKING.md`, by what the block did —
     implementation, debugging, research and investigation, code review, reporting — read from its
     commands, its edits, and what was said. Step 7 sets each activity's midpoint from this
     AI-assisted time; the minutes stay unrounded until step 8's totals.
   - **Work toward an outcome not delivered yet:** before the latest delivery, it's an outcome of its
     own — what it found, settled, or unblocked. After it, it waits for the next run, which starts
     there — unless this run is the wrap-up's or the developer asks to log it now: then it's an
     outcome of its own too.

5. **Estimate the work outside the sessions,** for each outcome, activity by activity, from the list
   in `docs/TIME-TRACKING.md` — understanding the task, research and investigation, debugging, manual
   testing, code review, task management, reporting and stakeholder communication, meetings:
   - Look for each activity's evidence: the tracker task's comments and status changes, the pull
     request's reviews and comments (`gh pr view --json reviews,comments`; on GitLab,
     `glab mr view <n> --comments --output json`, whose discussions carry the approvals as system
     notes), commits outside every block, the local and preview checks the developer approved,
     stakeholder updates, and what the developer said in the sessions.
   - Give each activity to the outcome it served, by what it was about and when it happened.
   - Estimate the activities the evidence shows, in whole hours. An activity with no
     evidence isn't in the draft.
   - Ask once, in the draft, what else the developer did outside the sessions — a call, a meeting, a
     manual test, work on another machine.

6. **Estimate the manual time** for each outcome: what **a senior developer** — fluent in the
   project's stack, familiar with the codebase, working without AI — would have spent on the same
   activities, each in whole hours.
   - Base it on the outcome's work: the diff and commits, the tests, the spec and docs, the
     investigation and debugging, and the off-session activities from step 5. A meeting or a manual
     test takes about as long without AI; writing, researching, and debugging usually take longer.
   - Never below the AI-assisted number without saying why.

7. **Set the midpoint** for each outcome, activity by activity — its AI-assisted time from step 4's
   blocks and step 5's estimate, against step 6's manual estimate — where `docs/TIME-TRACKING.md` §
   Activities puts each one:
   - **As spent:** the AI-assisted time — for work that takes as long either way, such as a meeting
     or a manual test.
   - **Halfway** between the activity's two times.
   - **Nearer the AI-assisted time** or **nearer the manual estimate:** a quarter of the way from
     that end.
   - The evidence may move an activity from its default: routine code — boilerplate, repetitive
     tests, a rename across files — nearer the AI-assisted time; judgment the developer brought — a
     design choice, a hard investigation, the review of what the AI wrote — nearer the manual
     estimate. Say why in the activities.
   - A project whose § Activities has no midpoint column: halfway, and as spent for a meeting or a
     manual test.
   - Never below the AI-assisted time, never above the manual estimate.
   - Leave the activities' midpoints unrounded: step 8 rounds their sum once.

8. **Round and build the entries.** One entry per outcome:
   - **The numbers:** each is the outcome's total, rounded up to whole hours: an outcome with 1h 10m
     in the sessions and an hour of estimated review is 3 hours (2h 10m → 3h). The midpoint is the
     sum of its activities' midpoints, rounded up once: halfway between 3h and 8h is 6h, not 5.5h.
   - **The description** — what the entry says in the tracker: what the outcome delivered, in
     business terms, for the people the task serves. Take it from the task's goal (the tracker task,
     the spec's Business section) and what the outcome achieved toward it. For work that delivered
     nothing yet, say what it found, settled, or unblocked. One or two sentences, with no code, file,
     or component names, commands, branches, or tool names. `docs/TIME-TRACKING.md` § Descriptions
     may set the team's own convention.
   - **The activities:** the work behind the numbers, in a few words, so the developer can check
     them. They stay in the draft. A time given beside one is rounded up too: sessions of 1h 50m read
     "sessions 2h".

9. **Show the full draft** of the entries, as the last text of your turn:

   ```
   | # | Delivered | Description | Activities | AI-assisted | Midpoint | Manual estimate |
   |---|-----------|-------------|------------|-------------|----------|-----------------|
   | 1 | 2026-10-15 | Readers can subscribe to the newsletter from the article they're reading | Understanding the task, signup form and its tests (sessions 2h over two days), manual test | 3h | 6h | 8h |
   | 2 | 2026-10-16 | New subscribers get their confirmation email; the requester confirmed it on the preview | Debugging the confirmation email (sessions 1h), call with the requester, PR review | 2h | 4h | 5h |
   ```

   Then the totals of each column, and the questions: **anything else done outside the sessions?**
   And for each entry: **AI-assisted, midpoint, manual estimate, an edited value in whole hours, or skip?** — with
   any change to its description. One answer may cover them all ("midpoint for all, skip 2"). An
   edited value that isn't whole hours: round it up and say so, or ask.

10. **Write the approved entries** — ask before posting, and post only what the developer approved,
    in one go, through the project's tracker server (`docs/TRACKER-INTEGRATION.md` § Rules for
    agents): an entry is logged to whoever is signed in, so say which account that is first.
    - One time entry per approved outcome on the tracker task, ending at its delivery: its start is
      the delivery minus the chosen number of hours, its duration that number. It carries the
      approved description, marked with the label for the number it carries.
    - Read the task's entries back and confirm they match. Report what was written, and anything
      that wasn't and why.
    - Write nothing else, anywhere: no file, commit, comment, or memory with the times. The draft
      stays in the conversation.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The project has `/adf:track-time` available, so I'll offer it" | The plugin carries it for every project. Only a stamp that names `time-tracking` turns it on. |
| "One entry per day is simpler, and the description says the outcome" | An entry is an outcome. A day is when the work happened, not what it delivered: an outcome that took three days is one entry, and two outcomes in one afternoon are two. |
| "Each commit or session is an outcome" | A commit and a session are steps. An outcome is what the people the task serves recognize as done or settled. |
| "The midpoint is the average of the two totals" | It's set activity by activity: a meeting stays as spent, debugging sits nearer the manual estimate, routine code nearer the AI-assisted time. |
| "1h 10m is closer to 1 than to 2" | Numbers round up to whole hours. A ballpark that rounds down undercounts every outcome. |
| "No evidence of a meeting, but there's usually one, so I'll add an hour" | Every activity rests on evidence or on what the developer says. Ask in the draft instead. |
| "The off-session work isn't measured, so I'll leave it out" | It's part of the task's time. Estimate each activity the evidence shows, and the developer corrects it. |
| "I'll keep the breakdown in the spec folder, so the estimate is traceable" | The time tracking tool is the only record. The breakdown stays in the conversation. |
| "Last run logged until Friday, I remember" | The tracker's entries say what's logged, not the conversation. Read them each time. |
| "Two tasks ran at once, so I'll split the overlap" | Each task gets its full time; the measure is per task. |
| "The activities explain the time, so they're the description" | The entries are read by people who don't see the code or the sessions. The description says what the outcome delivered; the activities stay in the draft. |
| "Nothing was delivered yet, so the description lists what I worked on" | An investigation has an outcome too: what it found, settled, or unblocked. Say that. |
| "The developer said log my time, so I'll post the entries now" | The request starts the draft. Show it, and post only the entries approved, with their chosen numbers. |

## Red flags (stop and reassess)

- The stamp doesn't name `time-tracking`, and you're about to draft or offer anything.
- An entry that covers a day, a session, or a commit instead of an outcome.
- A time in the draft or the entries that isn't whole hours, or one rounded down.
- A midpoint below the AI-assisted time or above the manual estimate, or an activity moved from its
  default with no reason given.
- An activity in the draft with no evidence behind it and no word from the developer.
- An entry for an outcome already logged on the task.
- A description that lists activities, or names code, files, commands, or tools.
- You're about to write a time, an estimate, or a breakdown anywhere but the time tracking tool.

## Verification

- [ ] The stamp names `time-tracking`, and `docs/TIME-TRACKING.md` was read
- [ ] The task's existing entries were read first, and the window starts after the latest one
- [ ] Session time came from the script; each off-session activity has its evidence
- [ ] One entry per outcome, each with its delivery; every block and activity in the window belongs to one, or waits for the next run
- [ ] Three numbers per entry, the midpoint set activity by activity between the other two, with the activities behind them; every time in the draft and the entries in whole hours, rounded up
- [ ] Each description says what the outcome delivered in business terms, with no technical names
- [ ] The full draft was shown, and the developer chose a number, an edit, or skip for each entry
- [ ] Only the approved entries were written, through the project's server as the developer, each ending at its delivery and labelled with the number it carries, and read back
- [ ] Nothing about the time was written anywhere else

## Principles

- Only where the project turned it on.
- One entry per outcome — a milestone, a completed task, value delivered — never per session or day.
- Three numbers per outcome, in whole hours; the developer picks.
- Measured where possible, estimated from evidence where not — a ballpark, never invented.
- Each entry says what the outcome delivered, for the people the task serves.
- The time tracking tool is the only record — and the source of what's already logged.
