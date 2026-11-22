# 0076: A tracker update that changes only the status needs no prompt

- **Status:** accepted
- **Date:** 2026-11-12
- **Amends:** [0059](0059-task-status-follows-the-work-and-stakeholder-guides.md) and
  [0073](0073-the-ticket-for-stakeholders-the-pull-request-for-the-developer.md) — a status move the
  agent makes on its own can pass the tracker tool's permission prompt

## Context

- **Developers named permission prompts as what slows them most,** in every project: tracker writes
  and shell commands. This record covers the tracker's; the shell's need their own evidence.
- **The status moves on the agent's own, and still asked.** Since 0059 and 0073 an agent moves its
  task to in progress, in review, and delivered without a yes. But a tracker's write tools stay off
  the allow list (`docs/TRACKER-INTEGRATION.md` § Permissions), so each move raised Claude Code's
  permission prompt: three per task, for a step the process says needs no approval.
- **Issue trackers already had none.** On GitHub or GitLab issues the same move is a `gh` or `glab`
  command, which is allowed. Only a tracker with an MCP server prompted.
- **An allow rule can't narrow it.** A permission rule matches a tool's name, not its input, and a
  tracker's update tool also edits the assignee, dates, and the description — writes that still need
  the developer's yes. Allowing the tool allows all of them.
- **Posts are different.** A comment goes out under the developer's name. Developers want to see it
  first, and the prompt shows the text. Removing that prompt was proposed and declined.

## Decision

- **A hook approves the status-only call.** `approve-status-move.sh` runs before an MCP tool call
  and approves it when both hold:
  - the tool is one `APPROVE_STATUS_MOVE` names;
  - the call carries nothing but the fields `STATUS_MOVE_FIELDS` lists — the task's identifier, then
    the status field, last — and the status field has a value.
- **Every other call is left to the prompt:** a comment or any other post; an update that also
  touches an assignee, a date, or the description; an input the hook can't read. The hook approves
  or stays silent. It never blocks.
- **Off until the project names its tool.** The skeleton ships `APPROVE_STATUS_MOVE=""`: it can't
  know the tracker. The `clickup` module's guide gives its value,
  `mcp__clickup__clickup_update_task`, and `/adf:adopt` sets it with the other hook settings.
  `STATUS_MOVE_FIELDS` defaults to `task_id status`.
- **The skills send the status alone, in a call of its own** — `/adf:stakeholder-update`'s status
  rules say so. An agent that adds a field to the call gets the prompt back.
- **What the hook doesn't check stays a rule:** that the task is the session's own, that the move
  goes forward, that delivered means live.

## Consequences

- **Positive:**
  - Three fewer prompts per task on a tracker with an MCP server, with no write beyond the status
    let through.
  - A tracker with an MCP server and one on issues behave alike for the status.
  - The prompt that remains on the update tool means something: the call changes more than a status.
- **Negative / cost:**
  - **Any task's status can move without a prompt,** not only the session's own. The hook sees the
    call, not which task the developer handed over.
  - **A hook process starts before every MCP tool call,** since the wiring can't name a tracker's
    tool ahead of time. It exits on its first line when the setting is empty.
  - **The field names are the project's to get right.** The default fits a tool that takes `task_id`
    and `status`. It wasn't checked against a live ClickUp server; a call with another field simply
    prompts, as before, until the field is listed.
  - **A committed install merges its settings** to wire the hook.

## Alternatives considered

- **Allow the update tool by name.** Declined: it also lets assignee, date, and description edits
  through, which the process says need a yes.
- **Allow the comment tool too, so outcome updates post with no prompt.** Declined: developers want
  to be asked before anything is posted under their name.
- **Leave it to each developer's `settings.local.json`,** as the `clickup` module suggested.
  Declined: per developer and per project, by hand, and it allowed the whole tool.
- **Approve only the session's own task.** Declined: the hook would have to find the task in the
  transcript, which is judging prose.
- **Wire the hook to the tracker's tool by name.** Declined: the plugin's wiring is the same for
  every project, and each tracker names its tool differently.
