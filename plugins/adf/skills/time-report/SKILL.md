---
name: time-report
description: Propose the time to report for a tracker task, or review the time of a day or a week, from local evidence — agent session time per day and branch from Claude Code's transcripts, and the developer's commits — plus labeled estimates for work outside the sessions. Use right after a change is delivered (after /adf:open-pr or /adf:stakeholder-update), or when asked how much time to log for a task, a day, or a week. Proposes only; logging time in the tracker needs the developer's yes.
argument-hint: "[task ID or link] | [--from YYYY-MM-DD --to YYYY-MM-DD]"
---

# Time report

Turn the evidence this machine already keeps into a time proposal the developer can check line by
line. Measured time and estimated time stay apart, and every estimate says what it's for.
Everything stays local: the script reads `~/.claude/projects/` and the git log.

Two modes:
- **Close-out** — one task, once its change is delivered: after `/adf:open-pr`, or after
  `/adf:stakeholder-update` on a later round of feedback. Once per delivery, never per commit.
- **Period review** — a day or a week, when the developer asks to review or fix their time.

## Steps

1. **The window and the task.** Close-out: the task ID (from the spec folder's `tracker:`, the
   branch, or the request) and the days its sessions ran. Period review: the days asked for.

2. **Run the script** in this skill's directory, from the project:

   ```bash
   python3 <this skill's base directory>/time_report.py . --from <YYYY-MM-DD> --to <YYYY-MM-DD> [--task <ID>] --worktrees
   ```

   It prints the session time per day (blocks of activity; overlapping sessions share their time),
   the total per branch, and the developer's commits. `--task` keeps the sessions whose branch or
   prompts mention the ID; `--worktrees` adds the worktrees `git worktree list` shows, so run a
   close-out before `/adf:wrap-up` removes the task's worktree.

3. **Time already logged.** If the project connects its tracker (`docs/TRACKER-INTEGRATION.md`), read
   the task's time entries for the window — with the `clickup` module, `clickup_get_time_entries`.
   Propose only what isn't logged yet.

4. **Map the evidence to tasks.** A worktree's branch is its task; on a shared branch, use the task
   IDs and prompts in the session blocks. Time with no task goes to the project's fallback task,
   or is listed for the developer to place.

5. **Add estimates for work the transcripts can't show,** with the project's allowances
   (`docs/TRACKER-INTEGRATION.md` § Time reports) or, without them, the defaults below. Count each
   only when it happened, once per round, and drop it when a session already covers it.

6. **Apply the project's rounding** (§ Time reports — whole hours, quarter hours) once per task for
   the window, never per block. Without a rule, report minutes.

7. **Return the proposal:** per task and day, measured, each estimate on its own line, total, and a
   one-line entry description in the task's language — imperative, at most eight words, no file
   names. Period review: one row per entry, marked new, already logged, or change from X to Y. End
   by asking whether to log the entries or leave them to the developer.

## Default allowances (minutes, when the project sets none)

Size: **S** one visual or copy change in one place; **M** a behavior change, two repositories, or
work in an external console; **L** a new feature, a migration, or several rounds of feedback.

| Work outside the sessions | Count it when | S | M | L |
|---|---|---|---|---|
| Reproduce and understand the request | First round on the task only | 30 | 45 | 60 |
| Manual check across devices and browsers | The change is visible to users | 30 | 60 | 120 |
| Check on the preview or staging | Something was deployed there; once per deploy, split across its tasks | 20 | 30 | 45 |
| Work in an external console | The task needed it and the evidence shows it | 0 | 60 | 90 |
| Client update | A message was written outside a session | 15 | 20 | 30 |

## Rules

- **Proposes only.** Logging time, changing a task's status, or posting a comment each needs the
  developer's explicit yes for that entry — they carry the developer's name.
- **Measured and estimated apart,** item by item; an estimate is always labeled as one.
- **The script reads the evidence.** Don't read transcripts or the git log by hand; that costs far
  more tokens and shows the same.
- **Session prompts can contain client or task details.** Keep the report in the conversation; don't
  paste prompt labels into commits, pull requests, or shared documents.
- Read-only: the skill never edits transcripts, the repository, or the tracker on its own.

## Verification

- [ ] The report ran on the task's folders and window (the "Folders" line and the header say which)
- [ ] Time already logged is left out of the proposal
- [ ] Each estimate names its activity and size, and happened in the window
- [ ] Rounding is applied once per task, and the description fits one line
- [ ] Nothing was written to the tracker without the developer's yes
