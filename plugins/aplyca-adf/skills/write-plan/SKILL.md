---
name: write-plan
description: Turn a spec into plan.md (constitution check, architecture, change surface, test strategy, documentation plan, assumptions) and tasks.md (commit-sized TDD tasks), check the folder for consistency, and stop at the approval gate. Use after /aplyca-adf:write-spec and before any implementation code — for new features and change requests alike.
argument-hint: "[spec folder, e.g. specs/007-newsletter-signup]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/write-plan/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Write Plan — and stop at the approval gate

Produce the HOW for an approved-for-planning spec: `plan.md` and `tasks.md` in the same spec
folder. Then stop and get the developer's sign-off on the **change surface** — the files and layers
the change will touch — before a single line of implementation code is written.

Why the gate is here: an agent's analysis is most dangerous when it is convincing. The part most
often wrong or incomplete is which files and layers the change really touches. Before the first
commit, correcting that is a sentence; after it, a rewrite. Approving the spec alone would be
cheaper but checks the wrong thing — the change surface isn't known until the plan exists.

## Prerequisites

- `spec.md` exists with every required section filled (`/aplyca-adf:write-spec` enforces this).
- For a change request: the spec has its `CR N` section with the Delivered → Change table.
- Open questions that block design are answered (they live in spec § Clarifications).

## Phase 1: Plan (`plan.md`)

1. **Read the spec in full** — every filled section, not only Functional. For a change request, read
   the `CR N` section and the delta table first, then what was delivered (`git log -- <folder>`).

2. **Read the context:** `docs/CONSTITUTION.md`; `AGENTS.md` and any nested `AGENTS.md` for the
   areas involved; the relevant `.claude/rules/`; ADRs and PDRs the spec references; the
   `docs/reference/` page for each subsystem you'll touch.

3. **Read the code that will change.** This is where the change surface comes from — not from the
   spec. Search for callers, shared components, configuration, migrations, and existing tests. For
   anything shared, list its other consumers: that is the blast radius the reviewer needs.

4. **Write `plan.md`** from `specs/_templates/plan.md`:
   - **Constitution check** — read every principle against the plan; record conflicts and their resolution.
   - **Approach** — the design, plus the alternatives you rejected (one line each). Justify any new dependency here or don't add it.
   - **Architecture & integrations** — domain concepts and which layer owns each; what must not leak across layers; a diagram only when prose can't carry it.
   - **Change surface** — every file to create or modify, by layer, with why; plus what is deliberately **not** touched.
   - **Data model & contracts** — new migrations (never edits to existing ones), API or contract changes, environment variables (declared in the env template), CMS model changes.
   - **Test strategy** — every acceptance criterion, edge case, and testable requirement from Security, Accessibility, Performance, Privacy, Analytics, and Localization mapped to a named test.
   - **Documentation plan** — from spec § Documentation: pre-implementable docs become Phase 1 tasks; post-implementable ones Phase 5.
   - **Rollout, risks, assumptions, open questions.** Every assumption you are relying on is written down — an unstated assumption is how an invented requirement gets in. Ask the open questions in rounds, each with your recommended answer (`AGENTS.md` § Working economically); name modules and concepts with the terms in `docs/GLOSSARY.md`.

## Phase 2: Tasks (`tasks.md`)

5. **Break the plan into commit-sized tasks** in dependency order, using `specs/_templates/tasks.md`:
   - Phase 0 — the approval itself (T000).
   - Phase 1 — docs first (one task per pre-implementable doc). Omit when there are none.
   - Phase 2 — foundation: migrations, shared types, configuration.
   - Phase 3 — stories: each task names its test (`test: <path> · "<name>"`) and the ACs it serves.
   - Phase 4 — acceptance tests encoding the ACs end to end. Written after the stories, they pass on
     their first run, so each is proven able to fail before its `test:` commit. When the plan asks
     for contract-first acceptance tests, move them ahead of Phase 3; they'll be committed red.
   - Phase 5 — reconcile docs, post-implementable docs, record gate results.
   Mark independent tasks `[P]`. **Sizing:** one task is one red → green cycle and one commit. A task
   that touches more than ~5 files or needs several test files is probably two tasks.

   **For a change request**, don't edit the delivered parts: append a `# CR N — <title>` part to
   `plan.md` and to `tasks.md`, with the templates' headings, covering only the delta. Number its
   tasks from `T<N>00` (T100 for CR 1); its gate results go under that part. Delivered tests the CR
   changes or retires are named in its test strategy, each with the task that touches it.

6. **Fill the verification checklist** with the project's real commands from `AGENTS.md` § Quick reference.

## Phase 3: Analyze (read-only)

7. **Check the folder for consistency** before showing it to anyone:
   - every AC → at least one task → a named test; every task → an AC, or a stated reason (foundation, docs);
   - every testable requirement in the filled non-functional sections → a test;
   - every pre-implementable doc → a doc task;
   - every file named in a task appears in the change surface;
   - no conflict with the constitution, and no contradiction between spec and plan;
   - assumptions listed; open questions empty.

8. **Get an independent check for non-trivial work.** Run `@aplyca-adf:spec-analyzer` on the folder — an
   isolated, read-only agent that tries to find what the plan missed. For high-stakes changes (auth,
   payments, personal data, migrations, many layers), the user can run the `/aplyca-adf:deep-spec-analysis`
   workflow instead. Fix every gap it confirms; note any you disagree with, and why.

## Phase 4: Approval gate — stop here

9. **Present the gate** to the developer, in this order:
   - **Scope** — the ACs in, and what is explicitly out.
   - **Change surface** — the table, the shared code and its other consumers, what is not touched.
   - **Assumptions and risks** — every one, plainly.
   - **Verification** — the test strategy in a few lines, and what will be checked manually.
   - **Docs** — what will be written before code.
   - End with: *"No implementation code until you approve. Reply with changes, or approve."*

10. **Wait.** Fold every change the developer asks for into the files, and show the result again.

11. **On approval:**
    - set `status: approved` in `spec.md`, and add an `approvals:` line — `YYYY-MM-DD · <who> · initial scope` (or `· CR N`);
    - tick T000;
    - commit the folder: `spec: approve <slug> scope and plan` (or `spec: approve <slug> CR N`). Don't push.

12. **Hand off:** `/aplyca-adf:write-docs` when Phase 1 has tasks, then `/aplyca-adf:implement`. Suggest doing that in a
    **fresh session on `sonnet`**: an approved plan with named tests is a clear spec with a way to
    check the result, the spec folder carries everything the next session needs, and the wait at the
    gate has usually let the prompt cache expire anyway — so the switch costs nothing extra.

## After approval

The plan is a living record. When implementation contradicts it, `/aplyca-adf:implement` corrects `plan.md` in
the same branch. If the change surface grows — a new layer, a new shared component, a file outside
the table — stop and re-confirm with the developer before continuing.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The spec is clear enough — I'll go straight to code" | The spec says WHAT. The change surface — the thing most often wrong — only exists once the plan does. |
| "I'll list the files I expect to change" | Expected isn't verified. The change surface comes from reading the code, callers and shared components included. |
| "My analysis is thorough, a second check is redundant" | A convincing analysis is exactly the one worth checking. Run `@aplyca-adf:spec-analyzer` for anything non-trivial. |
| "One task, 'implement the feature', is simpler" | Tasks are commits and red → green cycles. A task you can't name a single test for is too big. |
| "I'll keep the assumptions in mind" | An assumption that isn't written down can't be checked at the gate — it becomes an invented requirement. |
| "The developer approved the spec earlier, so the plan is approved too" | The gate approves scope **and** change surface together. Spec-level agreement isn't sign-off on the files. |
| "This change request is small — I'll reuse the old plan" | Add the CR's own plan and tasks to the folder; the delta is what gets approved. |

## Red flags (stop and reassess)

- The change surface touches shared code with consumers the spec never mentions.
- An AC has no test you can name, or a test has no AC — the spec or the plan is ambiguous.
- More than ~15 tasks, or several unrelated layers — the spec may be more than one PR; consider splitting.
- A new dependency, service, or migration appears that the spec didn't ask for.
- You catch yourself writing implementation code "to check the plan works" — that's a spike; say so.

## Verification

- [ ] `plan.md` has every section filled, including the change surface and assumptions
- [ ] The change surface was built by reading the code, and lists shared code's other consumers
- [ ] Every AC and testable requirement maps to a named test; every task names its test and ACs
- [ ] Every pre-implementable doc has a Phase 1 task
- [ ] The constitution check is done, and conflicts are resolved or recorded
- [ ] `@aplyca-adf:spec-analyzer` (or `/aplyca-adf:deep-spec-analysis`) ran for non-trivial work, and its confirmed gaps are fixed
- [ ] The gate was presented — scope, change surface, assumptions — and the developer explicitly approved
- [ ] `status: approved` and an `approvals:` line are set; the folder is committed with `spec:`, not pushed

## Principles

- The gate checks the change surface, because that is what convincing analyses get wrong.
- Change surface comes from the code, not from the spec.
- Every task is a commit with a test that will go red first.
- Write every assumption down; unstated assumptions become invented requirements.
- No implementation code before an explicit approval.
