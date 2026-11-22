# Time Tracking

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: how the team logs the time its tasks take, with /track-time -->

The team logs the time its tasks take as an internal productivity measure. `/track-time` drafts a
task's entries, one per outcome — a milestone reached, a completed task of the plan, value delivered,
or what an investigation found or settled — never one per session or day. Each entry has three
numbers in whole units:

- **AI-assisted** — the time actually spent: the task's Claude Code sessions, measured, plus the work
  done outside them, estimated.
- **Manual estimate** — the time a senior developer would have spent on the same work without AI.
- **Midpoint** — a reasonable time for the work, between the two, set activity by activity as
  § Activities says.

Each entry's description says what its outcome delivered, in business terms, and the entry ends when
the outcome was delivered. The developer picks one number per entry, and only the entries they
approve are written to the tracker task's time entries. **The tracker is the only record:** no time
goes into the repository, the spec folders, or the pull requests.

## Settings

<!-- CUSTOMIZE: fill these in. -->

- **Unit:** [1 hour] — every number is a whole number of units, rounded up.
- **Time entries:** [how to read and write a task's time entries with the tracker's tools — e.g. the
  time-tracking tools listed by `/mcp`; each entry has a start, a duration, and a description]
- **Labels:** [what marks the number an entry carries — e.g. the tag `ai-assisted` for the time spent,
  `midpoint` for the midpoint, `manual-estimate` for the estimate; or a prefix in the description]
- **Billable:** [no — the entries are an internal measure — or how the team sets it]

## Descriptions

An entry's description says what its outcome delivered for the people the task serves — or, for
work that delivered nothing yet, what it found, settled, or unblocked. One or two sentences, with no code,
file, or component names, commands, or tool names. The activities behind the numbers stay in the
draft. <!-- CUSTOMIZE: add the team's own convention, if any — the audience the reports go to, a prefix. -->

| Not this | This |
|---|---|
| Implementation, tests, PR review | Readers can subscribe to the newsletter from the article they're reading |
| Debugging the confirmation email | Found why new subscribers got no confirmation email; the fix is agreed with the requester |

## Activities

The work an entry covers, in the sessions or outside them. `/track-time` estimates each one from the
evidence that it happened, and the developer corrects the draft. The midpoint column says where each
activity's midpoint sits between its AI-assisted time and its manual estimate: **as spent** (work
that takes as long either way), **halfway**, or **nearer** one end — a quarter of the way from it.
The evidence may move an activity: routine code nearer the AI-assisted time, judgment the developer
brought nearer the manual estimate, with the reason in the draft. <!-- CUSTOMIZE: add, remove, or rename; move a midpoint. -->

| Activity | Evidence it looks for | Midpoint |
|---|---|---|
| Understanding the task | The tracker task and its comments read, questions asked, the spec written | Halfway |
| Research and investigation | Docs, code, and options explored, in the sessions or mentioned by the developer | Halfway |
| Implementation | Commits, the diff, tests written | Halfway |
| Debugging | Failing runs, hypotheses, fixes in the sessions; issues the developer mentions | Nearer the manual estimate |
| Manual testing | The developer's own testing of the draft, locally and on the preview | As spent |
| Code review | Reviews and comments on the pull request, received and given | Nearer the manual estimate |
| Task management | Status changes, comments, and links on the tracker task | As spent |
| Reporting and stakeholder communication | Stakeholder updates drafted or posted, messages, the handoff | Halfway |
| Meetings | Calls and meetings about the task, named on the task or by the developer | As spent |
