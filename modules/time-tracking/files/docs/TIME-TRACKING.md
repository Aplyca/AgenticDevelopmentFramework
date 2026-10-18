# Time Tracking

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: how the team logs the time its tasks take, with /track-time -->

The team logs the time its tasks take as an internal productivity measure. `/track-time` drafts a
task's entries, one per day worked, each with two numbers in whole units:

- **AI-assisted** — the time actually spent: the task's Claude Code sessions, measured, plus the work
  done outside them, estimated.
- **Manual estimate** — the time a senior developer would have spent on the same work without AI.

The developer picks one number per entry, and only the entries they approve are written to the
tracker task's time entries. **The tracker is the only record:** no time goes into the repository,
the spec folders, or the pull requests.

## Settings

<!-- CUSTOMIZE: fill these in. -->

- **Unit:** [1 hour] — every number is a whole number of units, rounded up.
- **Time entries:** [how to read and write a task's time entries with the tracker's tools — e.g. the
  time-tracking tools listed by `/mcp`; each entry has a start, a duration, and a description]
- **Labels:** [what marks the number an entry carries — e.g. the tag `ai-assisted` for the time spent,
  `manual-estimate` for the estimate; or a prefix in the description]
- **Billable:** [no — the entries are an internal measure — or how the team sets it]

## Activities

The work an entry covers, in the sessions or outside them. `/track-time` estimates each one from the
evidence that it happened, and the developer corrects the draft. <!-- CUSTOMIZE: add, remove, or rename. -->

| Activity | Evidence it looks for |
|---|---|
| Understanding the task | The tracker task and its comments read, questions asked, the spec written |
| Research and investigation | Docs, code, and options explored, in the sessions or mentioned by the developer |
| Implementation | Commits, the diff, tests written |
| Debugging | Failing runs, hypotheses, fixes in the sessions; issues the developer mentions |
| Manual testing | The developer's own testing of the draft, locally and on the preview |
| Code review | Reviews and comments on the pull request, received and given |
| Task management | Status changes, comments, and links on the tracker task |
| Reporting and stakeholder communication | Stakeholder updates drafted or posted, messages, the handoff |
| Meetings | Calls and meetings about the task, named on the task or by the developer |
