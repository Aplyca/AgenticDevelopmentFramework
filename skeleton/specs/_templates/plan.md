# Plan: [feature name]

<!--
  HOW. Derived from spec.md and checked against docs/CONSTITUTION.md. Written by /write-plan
  together with tasks.md, and approved with them at the approval gate — before any
  implementation code. The section the gate scrutinizes most is "Change surface": the most
  common way a convincing plan is wrong is touching more (or other) files and layers than it
  says. When implementation contradicts this plan, fix the plan in the same branch rather than
  leaving it stale; if the change surface grows, re-confirm with the developer.
  Change request: leave the delivered plan as it is and append a "# CR N — <title>" part with
  these headings, covering only the delta.
-->

- **Spec:** ./spec.md · **Tasks:** ./tasks.md
- **Last updated:** YYYY-MM-DD

## Constitution check

Every principle in `docs/CONSTITUTION.md` was read against this plan.

- [ ] No conflicts — or each conflict is listed below with its resolution (amendment, or an
      explicit exception recorded in spec.md)
<!-- CUSTOMIZE: mirror your constitution's gates here, e.g.
- [ ] Authorization boundaries unchanged, or the broadening is justified in spec.md § Security
- [ ] Migrations are new files only (append-only history)
- [ ] No new dependency, or each one is justified under Approach
- [ ] Types not silenced; accessibility lint kept green -->

## Approach

<!-- The design in a few paragraphs: which layers change and why, and the alternatives you
     rejected (one line each). New dependencies are justified here or not added. -->

## Architecture & integrations

<!-- Domain concepts this feature introduces or touches, and which layer owns each piece.
     Name what must NOT leak (e.g. domain rules into UI components or data plumbing).
     External integrations: what is called, from where, with which credentials.

     Add a Mermaid diagram only when prose can't carry it — a non-trivial sequence across
     components, a state machine, or a data-model change:

     ```mermaid
     sequenceDiagram
         actor User
         participant UI as Form
         participant API as /api/subscribe
         participant ESP as Email provider
         User->>UI: submit email
         UI->>API: POST { email }
         API->>ESP: subscribe(email)
         ESP-->>API: subscribed | error
         API-->>UI: 200 | 502
     ```
-->

## Change surface

<!-- REQUIRED. Every file and layer this change will create or modify, verified by reading the
     code (search for callers, shared components, configs, tests). Shared code: list its other
     consumers so the reviewer can judge the blast radius. -->

| Area / layer | File (new / changed) | Why |
| --- | --- | --- |
| [e.g. API] | [`app/api/subscribe/route.ts` (new)] | [AC1–AC3: accepts and validates the signup] |

**Not touched (deliberately):** [areas a reader might expect to change, and why they don't]

## Data model & contracts

<!-- Schema changes (new migrations only — history is append-only), API/contract changes
     (see ./contracts/ if used), new or changed environment variables (declared in the env
     template), CMS content-model changes. "None" is a valid answer. -->

## Test strategy

<!-- Map every AC, edge case and testable requirement (Security, Accessibility, Performance,
     Privacy, Analytics, Localization) to a test. tasks.md repeats the test on the task that
     makes it pass. Note anything verified manually and why it can't be automated. -->

| Requirement | Test (file · name) | Type |
| --- | --- | --- |
| AC1 | [`tests/subscribe.test.ts` · "accepts a valid email"] | [unit / integration / e2e] |

**Contract-first acceptance tests:** [none | list end-to-end tests to write and commit red
before implementation tasks, when the team wants the verification contract up front]

## Documentation plan

<!-- From spec.md § Documentation. Pre-implementable docs become Phase 1 tasks (written before
     code); post-implementable docs become Phase 5 tasks. "None — <reason>" is valid. -->

| Doc | Audience | Pre / post | Task |
| --- | --- | --- | --- |
| [`docs/admin/<feature>.md`] | [site administrator] | pre | [T001] |

## Rollout & deployment

<!-- Ordering constraints (schema before code, CMS type before deploy), feature flags, how to
     roll back — including what can NOT be rolled back (data, migrations). -->

## Risks & mitigations

- [Risk] — [mitigation]

## Assumptions

<!-- Anything this plan relies on that the spec or the code does not state. The approval gate
     shows these to the developer explicitly — an unstated assumption is how an invented
     requirement slips in. -->

- [Assumption] — [why it is believed true / who confirmed it]

## Open questions

<!-- Must be empty (resolved, with answers folded into spec.md § Clarifications) before
     approval. -->
