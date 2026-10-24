# 0050: Spec folders name roles, a change request can ride the open pull request, and a split feature shares one written contract

- **Status:** accepted; refined by [0054](0054-found-along-the-way.md) (what the agent finds on its own, and a bug in the branch's own work)
- **Date:** 2026-10-23
- **Refines:** [0001](0001-spec-folders-as-record-of-intent.md) — what the record holds, and whose
  words stay in the tracker; [0011](0011-lanes-ceremony-follows-risk.md) — light and full change
  requests, now before the merge as well as after it

## Context

A session in an adopting project ran into three gaps in the spec folder's rules:

- **A spec quoted a person.** The agent copied a stakeholder's reply from the tracker into the spec
  and attributed it by name. The `tracker:` field already said "link it, never copy it", but the
  templates invited names: `approvals:` read `<who>`, a clarification ended `(date, who)`, and a
  change request's *Requested* line ended `· by [who]`. The `specs/README.md` example attributed a
  request to a named person, and the framework's own examples named their fictional people in the
  spec folders. A repository has a different audience from the tracker's, and it outlives the time anyone
  holds a role.
- **Feedback before the merge had no home.** The requester asked for changes twice while the pull
  request was still open. Change requests were defined for delivered work only, with a new branch
  each time, so the agent either edited the approved spec in place, losing the delta, or would have
  opened a second branch for work that hadn't merged.
- **A split feature's contract lived in conversations.** A provider spec changed a query parameter at
  its own gate. Its consumer, on a parallel branch cut before that change, would have broken
  silently: nothing written in either folder said they shared an interface.

## Decision

- **Records name roles** (`specs/README.md` § Records name roles). `spec.md`, `plan.md`, and
  `tasks.md` date each decision and attribute it to a role — requester, developer, tech lead,
  legal — never to a person's name. Decisions are written in the folder's own words: no quotes or
  text copied from the tracker, no "the requester said…". The `tracker:` link is where people's
  words live; git history holds who committed what. The templates' formats change to match
  (`<role>`, `[role]`), `owners:` stays role labels with no "names if you prefer", and the examples'
  spec folders use roles while their stories keep the fictional names.
- **`@adf:spec-analyzer`, `/adf:deep-spec-analysis`, `/adf:context-audit`, and
  `/adf:deep-context-audit` flag** a personal name or a quoted tracker comment in a spec folder.
- **A change request can come before the merge** (`specs/README.md` § Before the merge). Feedback
  while the pull request is open rides the same branch and the same draft, with the two weights
  change requests already have. No separate "amendment" concept:
  - **light** — the `CR N … · light` section, committed with the change, and no status cycle;
  - **full** — the status goes `implemented` → `in-review` → `approved`, with a dated, role-based
    `approvals:` line for the CR, and back to `implemented` with the CR's gate results; a `# CR N`
    part in `plan.md` and `tasks.md` covers the delta, tasks numbered `T<N>00`; superseded entries
    are struck through, not deleted; red then green per task.

  After the merge, a change request still needs a new branch. `/adf:open-pr` keeps the pull
  request's description current with each push, so the CR shows there too.
- **A feature split across spec folders shares one written contract** (`specs/README.md` §
  Granularity). Before the split, the shared interface — parameter names, accepted values, field
  IDs, endpoints — goes into § Constraints & prior decisions of both specs; the consumer names the
  provider's folder in `related-specs`, and the provider names its consumers. A change to it is
  recorded in the consumer's spec and pull request, and after each sync with the base branch the
  consumer re-checks it against the provider's spec. `/adf:dispatch` carries the contract in the
  brief for each part, and `@adf:spec-analyzer` flags a contract change against a named consumer
  spec.

## Consequences

- A spec folder can be read by anyone with repository access without exposing who said what; the
  tracker keeps the conversation, under its own access rules.
- Existing spec folders keep their names until they next change: the record isn't rewritten for
  its own sake. The audits report them, and the next change request can move them to roles.
- Feedback on an open pull request leaves the same visible delta as feedback after the merge, so
  the reviewer of the draft sees what changed since the gate.
- The contract is written twice, once per spec. That's the cost of each side reading it without the
  other's branch; the analyzer's check is what catches the two drifting apart.
