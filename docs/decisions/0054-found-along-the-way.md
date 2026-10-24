# 0054: What an agent finds along the way is reported and routed — never dropped, never fixed in passing

- **Status:** accepted
- **Date:** 2026-10-23
- **Refines:** [0050](0050-spec-records-name-roles-and-contracts.md) — change requests before the
  merge come from the requester; this record covers what the agent finds on its own

## Context

An agent reads far more code than it changes. Developers find what it notices there among the most
useful things it does: a bug in another feature, a missing test, a slow query, a stale doc, a better
way to build the feature at hand — whether or not it relates to the task.

The framework had no route for it. `/adf:implement` said only "not in this branch" about nearby
code. `/adf:dispatch` offered a new session for "one found along the way", but only with the
parallel-agents module, and a chip nobody started was gone in a week. `/adf:wrap-up` started
follow-ups from a pull request's `## Follow-ups`, but only `/adf:upgrade` wrote that section, and only
after a merge. Reviews had nowhere to put a bug outside the diff except the verdict. 0050's
change requests before the merge covered the requester's feedback, not the agent's own findings,
and didn't say that a bug in the branch's own work isn't a change request at all.

So a finding was dropped, buried in one turn's report, or fixed in passing in a branch about
something else.

## Decision

- **Nothing found is dropped, and nothing found is fixed in passing** (`AGENTS.md` § AI interaction
  rules; `specs/README.md` § Found along the way). The agent reports each finding in that turn's
  report — what, where (`file:line`), how it knows, the lane it would take — and routes it:
  - **a bug in this branch's own work** is fixed in the task, with a regression test — not a change
    request, before the merge or after;
  - **an improvement to what this branch builds** is the developer's call — a change request on the
    branch if they take it before the merge, a follow-up if not now;
  - **anything else**, however unrelated, is its own task: a follow-up, and with the parallel-agents
    module a new session offered at once;
  - **what can't wait** — a security hole, data at risk, production broken — goes to the developer
    first, whatever it relates to.
- **Follow-ups live in the pull request's `## Follow-ups`**, one `- [ ] <task> — <why> (found in
  <file:line>)` line each. `/adf:open-pr` writes the session's findings there, the github module's
  template has the section, and on an open draft the agent adds a line at once, as upkeep. The agent
  only adds lines; the developer drops one by ticking or deleting it.
- **`/adf:wrap-up` offers them after any ending** — merged, or closed and dropped — and an answer's
  follow-ups too. `/adf:upgrade`'s commands still wait for a merge.
- **Reviews list what's outside the diff apart from the verdict**: `/adf:review`, `@adf:code-reviewer`
  (`[outside]`), and `/adf:deep-review` (its `followUps`). `/adf:debug` routes other bugs it meets the
  same way, and `/adf:handoff` carries findings not yet in a pull request.

## Consequences

- A finding survives the session that made it: in the pull request, on origin, until the developer
  starts or drops it.
- Branches stay about one thing: the fix for an unrelated bug gets its own task, review, and test.
- Pull requests gain a section people may see filled. "- none" keeps it short when there's nothing.
- A finding the developer started from a chip still sits in `## Follow-ups` until they tick it; the
  close-up lists it again, and they drop it there.
