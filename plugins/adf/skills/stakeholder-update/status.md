# Status moves — the rules

`/adf:stakeholder-update` reads this for a move it makes itself: with the argument `status`, or at
step 6 when the move didn't happen at its moment. `/adf:triage`, `/adf:open-pr`, and `/adf:wrap-up`
carry the same rules in their own step.

- **The task's own statuses decide.** Read them with the tracker's tools (§ Project settings), and use
  the one `docs/TRACKER-INTEGRATION.md` § Stakeholder updates maps to the moment. A status the task
  doesn't have is a question for the developer, not a guess.
- **Forward only.** A task already at or past the target — a developer moved it by hand, or it's
  waiting on the requester — stays where it is. Never move it back.
- **Only the developer's tasks.** A task the developer isn't assigned to stays as it is, unless they
  say so.
- **The status only.** The assignee, priority, due date, and time entries still need a yes
  (`docs/TRACKER-INTEGRATION.md` § Rules for agents).
- **Say it in one line** — "Moved the task to In Progress" — so the developer can correct it. With
  no tracker tool connected, say which status the developer should set, and go on.
- **The tracker's own prompt still applies.** The status move is a write; where the project leaves
  it off the allowlist, the permission prompt is the developer's say, not the skill's to skip.
- **Through the project's server, as the developer,** like the post (`/adf:stakeholder-update`
  step 6). With only a tracker connector built into the host app, say which status the developer
  should set.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The task is at Review already — I'll set it to In progress anyway" | Forward only. A task past the target stays where it is. |
| "I'm moving the status, so I'll change the assignee too" | Status moves on its own; the assignee, priority, due date, and time entries still need a yes. |

## Red flags (stop and reassess)

- A status move that goes backward, or onto a task the developer isn't assigned to.
