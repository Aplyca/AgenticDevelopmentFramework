# Status moves — the rules

`/adf:stakeholder-update` reads this for a move it makes itself: with the argument `status`, or at
step 6 when the move didn't happen at its moment. `/adf:triage`, `/adf:open-pr`, and `/adf:wrap-up`
carry the same rules in their own step.

**The rules are `docs/TRACKER-INTEGRATION.md` § Rules for agents** — its status-move bullet, and the
ones on the session's own task, any other task state, the project's tracker tool, and reading back.
Read the task's statuses with the tracker's tools (§ Project settings). This file adds what they
leave out:

- **On GitHub or GitLab issues** the status is a label, and delivered closes the issue (§ Issues as
  the tracker); a label the repository lacks is a question too — never create one.
- **Delivered means live.** Move to it only once the change is verified live (`SKILL.md` § Live), or
  an answer is delivered.
- **Forward only,** in the tracker's own order of statuses (§ Rules for agents): a task already at or
  past the target — a developer moved it by hand — stays where it is, and so does one at a status
  outside that order, such as blocked or waiting on the requester.
- **Send the status alone, in a call of its own.** Where the project names the tracker's status
  tool in `APPROVE_STATUS_MOVE` (`.claude/hooks/config.sh`), a call that carries only the task and
  its status passes without a prompt; any other field in the same call brings the prompt back.
  Where it names none, the move prompts: that is the developer's say, not the skill's to skip.
- **Can't write** — no tracker tool, or only a connector built into the host app: open your report
  with the status the developer should set, and go on. Don't leave it for the end.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The task is at Review already — I'll set it to In progress anyway" | Forward only. A task past the target stays where it is. |
| "I'm moving the status, so I'll change the assignee too" | Status moves on its own; the assignee, priority, due date, and time entries still need a yes. |
| "It merged — I'll move it to done" | Delivered means live. Between review and delivered, the statuses are the developer's. |
| "The developer moved it to acceptance testing — I'll move it on once the checks pass" | Those statuses say a person checked or released it. Leave them; your next move is delivered, once it's live. |
| "The repository has no 'in review' label — I'll create it" | Labels are the team's vocabulary. Ask which one to use. |

## Red flags (stop and reassess)

- A status move that goes backward, or onto a task that isn't this session's.
- A move to delivered for a change that merged but isn't live, or to a quality-control, acceptance, or release status.
