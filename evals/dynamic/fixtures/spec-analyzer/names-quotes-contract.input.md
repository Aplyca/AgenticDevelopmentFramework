# Input — @spec-analyzer flags names, tracker quotes, and a contract change against a consumer spec

This fixture verifies that `@adf:spec-analyzer` ([decision 0050](../../../../docs/decisions/0050-spec-records-name-roles-and-contracts.md)):
- Flags a person's name where a decision should name a role (`approvals:`, a clarification, a
  change request's *Requested* line, an assumption)
- Flags text quoted or copied from the tracker, and a "the requester said…"
- Doesn't flag an agent's name (`@spec-analyzer`) as a person
- Flags a change to a shared contract against the consumer spec that relies on it

## Setup

A project from the skeleton with two spec folders. The names and the tracker text are fictional.

`specs/012-topic-catalog/spec.md` — the provider, `status: in-review`, with only these parts that
matter here (fill the other required sections with "Standard applies" or a one-line requirement):

```markdown
---
title: "Topic catalog API"
status: in-review
feature-type: api
personal-data: no
tracker: "https://tracker.example.com/t/MKT-601"
approvals:
  - "2026-10-20 · Robin (tech lead) · initial scope"
references:
  related-specs:
    - "specs/013-topic-picker/ (consumer)"
---

## Functional

- **AC1** — `GET /api/topics?state=active` returns the active topics.
- **AC2** — `GET /api/topics?state=archived` returns the archived topics.

## Constraints & prior decisions

- Shared contract with `specs/013-topic-picker/` (consumer): `GET /api/topics?status=active|archived`
  returns `{ id, label }` — Reason: the feature is split across both folders.

## Clarifications

- **Q:** Are archived topics listed? — **A:** Yes, on request. _(2026-10-18, Jordan)_
- **Q:** Sort order? — **A:** As the requester said in the tracker: "alphabetical please, and put
  Culture first because the board loves it". _(2026-10-18, requester)_
- **Q:** Paging? — **A:** None; at most 20 topics. _(2026-10-19, tech lead — raised by @spec-analyzer)_
```

`specs/012-topic-catalog/plan.md`, § Data model & contracts:

```markdown
- The query parameter is renamed from `status` to `state`, to match the CMS field.
```

§ Assumptions:

```markdown
- A1 — The CMS keeps topic IDs stable when a topic is renamed. (Confirmed by Robin.)
```

`specs/012-topic-catalog/tasks.md` — one task per AC, each naming its test.

`specs/013-topic-picker/spec.md` — the consumer, `status: approved`, whose `related-specs` names
`specs/012-topic-catalog/ (provider)`, and whose § Constraints & prior decisions records the
contract as `GET /api/topics?status=active|archived` returns `{ id, label }`. Its pull request is
open; neither it nor the spec mentions the rename.

## Prompt to give the AI

```
@adf:spec-analyzer analyze specs/012-topic-catalog
```

(In a committed install: `@spec-analyzer`.)

## What to do with this fixture

1. Build the two folders above in a throwaway project.
2. Run the prompt.
3. Compare the report against `names-quotes-contract.expected.md`.
