# 0059: A tracker task's status follows the work on its own, every session is named after its task, and end-user docs are stakeholder guides

- **Status:** accepted
- **Date:** 2026-10-28
- **Amends:** [0053](0053-stakeholder-updates-at-three-moments.md) — the status is no longer part of
  the message's approval; [0048](0048-end-user-docs-in-the-doc-tool.md) — the pages are stakeholder
  guides

## Context

- **Status.** 0053 moved the task only on the developer's yes, bundled with the message. In practice
  the board lagged: the developer moved tasks by hand, or not at all. A status isn't a message — it
  says where the work is, and the requester reads the message, not the status, as the developer's
  words.
- **Session names.** `/adf:triage` names the session (step 5), but only after a triage, and a bare
  tracker link left a title that tells nothing in the session list.
- **End-user docs.** 0048 framed the module around public end users. The pages teams actually need are
  guides for stakeholders — editorial (create, edit, publish content) and administrative (users,
  settings) — as much as visitor-facing help.

## Decision

1. **The status moves on its own at three moments,** forward only, for a task the developer is
   assigned to, with one line saying so: in progress after the triage (`/adf:triage`), in review once
   the branch is pushed and the pull request is open (`/adf:open-pr`), done once it merges or an
   answer is delivered (`/adf:wrap-up`). `/adf:stakeholder-update status <moment>` makes the move;
   the project's words come from `docs/TRACKER-INTEGRATION.md` § Status at each moment. Messages,
   assignees, priorities, due dates, and time entries still need the developer's yes. A tracker tool
   the project leaves off its allowlist still prompts.
2. **Every session is named after its task,** in every lane, answers included, as the first step after
   the triage text.
3. **`end-user-docs` writes stakeholder guides:** user, editorial, and administrative guides — how the
   people who use the system do their work with it. The module keeps its name, so stamps stay valid.
   Technical docs (runbooks, API contracts, architecture) stay in the repository.

## Consequences

- The board is current without the developer's attention; a wrong move is one line to correct.
- A project that wants the old behavior removes the status rule from its own instructions.
