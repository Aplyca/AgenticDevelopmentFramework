---
name: implement
description: Plan and implement a feature by making the committed tests pass. Use after spec AND tests have been committed.
user_invocable: true
argument-hint: "[spec name or path]"
---

# Implement from Spec (Plan Then Make Tests Pass; Keep Docs Accurate)

Build the feature by writing code that satisfies the committed spec, makes the committed tests pass, and keeps the committed docs accurate. This skill follows a plan-then-execute pattern: first present an implementation plan for approval, then write the code.

## Prerequisites

Before running this skill, the spec, tests, AND any pre-implementable docs should already be committed:
- **Spec commit** (`spec:` prefix) — defines what to build
- **Test commit** (`test:` prefix) — defines how to verify it (tests should currently be failing)
- **Docs commit** (`docs:` prefix) — drives implementation thinking by describing how the feature will be used (if the spec lists pre-implementable docs)

**Docs enforcement:** If the spec's Documentation section lists pre-implementable docs but no `docs:` commit exists for this feature, refuse to plan. Tell the user to run `/write-docs` first. (If the spec marks Pre-implementable as Not applicable, no docs commit is required and this skill proceeds normally.)

## How docs evolve during implementation

Docs are written first to **drive implementation thinking** — they force articulation of how the feature will be used before code starts. But docs are **living artifacts**: when implementation reveals reality differs from the original docs (a chosen approach changes the UX, requirements shifted during planning, an edge case surfaces that the docs didn't cover), **updating the docs is a normal expected sub-step of this phase, not an exception**.

The discipline isn't "code must conform to original docs". It's "never let docs go stale — update them deliberately when reality moves".

Two clean patterns for doc updates during implementation:
1. **Separate `docs:` commit before the `feat:` commit** — preferred when the doc update is meaningful (changed behavior, new section, removed claim). Update docs, run tests, commit `docs: update X for Y`, then commit code with `feat:`.
2. **Folded into the `feat:` commit** — acceptable when the doc update is small (a sentence, a field name correction). Call it out in the commit message body: "Also updates docs/admin/X.md to reflect [change]".

**Never:** ship code that contradicts committed docs without updating the docs. That's how docs go stale and stop being trusted.

## Phase 1: Plan

1. **Identify the scope from git diff** — Run `git diff` against the spec and test commits to see:
   - What changed in EACH spec section (not just Functional — see `docs/SPEC-MODEL.md`)
   - What tests are expecting (from the test diff)
   - **New spec + tests** → implement everything from scratch
   - **Modified spec + tests** → focus on the diff: new/changed requirements and their tests. Don't re-implement unchanged criteria.

2. **Run the tests — confirm they fail** — Run the test suite to see the current "red" state. The failing tests tell you exactly what the implementation needs to satisfy.

3. **Read the committed docs** — If the previous commit was `docs:` for this feature, read the doc files it added. They describe how the feature is intended to be used and should drive your implementation thinking. As you plan, watch for places where the chosen approach will diverge from the docs — note them as "doc updates needed" so you handle them deliberately during execution (not silently).

4. **Read the full spec — every filled section** — Read the complete spec in `specs/` for full context. The diff tells you what's new; the full spec tells you how it fits together. The implementation plan must address requirements from every filled section, not just Functional:
   - **Functional** — code that satisfies ACs and edge cases
   - **Security** — mitigations (validation, rate-limit, auth checks, secret handling)
   - **Accessibility** — semantic markup, ARIA, keyboard handlers, focus management
   - **Performance** — anything required to hit the SLA (caching, lazy loading, bundle splitting)
   - **Privacy** — consent gates, data-handling code, third-party scripts
   - **SEO** — server rendering, meta tags, structured data, canonical URLs
   - **Analytics** — event firing at the right moments
   - **Localization** — locale-aware rendering, translation keys
   - **Technical** — architecture decisions and integration code
   - **Observability** — logging / metrics / alert hooks
   - **Deployment** — env vars and infra changes go in the plan as preconditions, not code (but call them out)

   Skip sections marked `Not applicable` or `Standard applies`.

5. **Check existing code** — Read the files you'll modify. Understand the current patterns, imports, and conventions before making changes. For modifications, understand what already works and must be preserved.

6. **Present the implementation plan** — Show the user:
   - **Task breakdown** (in dependency order):
     ```
     - [ ] Create `lib/validate.ts` — input validation helpers [tests: 'validates email', 'rejects empty input']
     - [ ] Update `app/api/users/route.ts` — add POST handler [tests: 'creates user', 'returns 400 on bad input']
     - [ ] [P] Update `app/users/page.tsx` — add registration form [tests: 'shows form', 'submits data']
     - [ ] [P] Add `styles/users.css` — form styling [tests: 'form renders correctly']

     [P] = can run in parallel with the previous task
     ```
   - Any architectural decisions or trade-offs
   - For non-trivial features (3+ files): dependency order and which tasks can be parallelized

7. **Get approval** — Wait for the user to approve the implementation plan before writing any code. Iterate if they want changes.

## Phase 2: Execute

8. **Implement** — Follow the approved plan. Write code that makes each failing test pass. Use the committed docs as design context. When you spot a place where the chosen approach will diverge from the docs, note it for reconciliation in step 10 (don't silently diverge). Follow the project's rules and conventions:
   - Match existing patterns in neighboring code
   - Handle edge cases listed in the spec
   - Validate at system boundaries
   - Handle errors gracefully

9. **Run the tests — they should all pass** — This is the TDD "green" phase. If any test fails:
   - Read the failure message carefully
   - Fix the implementation to satisfy the test
   - Only modify a test if it contains a genuine bug (not to make a failing test pass by weakening it)

10. **Reconcile docs with reality** — If pre-implementable docs were committed:
    - Re-read each doc and check accuracy against what was actually built
    - Update any doc claims that diverged (new behavior, renamed fields, additional edge cases discovered, UX changes)
    - Doc updates can land as a separate `docs:` commit (preferred for meaningful updates) or folded into the `feat:` commit (acceptable for small fixes — call out in the message)
    - Get the user's quick review of any non-trivial doc changes before committing
    - This is a **normal sub-step**, not an exception. Most features have at least minor doc adjustments here.

11. **Self-review** — Before presenting to the user:
    - Does each acceptance criterion (especially new/changed ones from the diff) have corresponding code?
    - Are requirements from EVERY filled spec section addressed (Security, Accessibility, Privacy, Performance, Analytics, Localization, Observability)? Skip sections marked Not applicable or Standard applies.
    - Does the code match every claim in the committed docs?
    - Are deployment requirements (env vars, infra changes) called out for the operator even though they're not code?
    - Do all tests pass?
    - Are edge cases handled?
    - Does the code follow project rules (naming, typing, error handling)?
    - No speculative features beyond what the spec says?
    - For modifications: is existing behavior preserved where the spec didn't change?

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "This is a simple change, I'll skip the plan" | Simple changes have the highest rate of unintended side effects. Plan anyway — it takes 30 seconds. |
| "The tests are too restrictive, I'll adjust them" | Tests define the contract. Fix the implementation, not the test. Only modify a test if it has a genuine bug. |
| "I'll add error handling later" | Error handling is part of the spec. If the spec lists edge cases, implement them now. "Later" means "never." |
| "This refactor will make things cleaner" | If it's not in the spec, don't do it. Cleaner ≠ correct. Refactoring is a separate workflow. |
| "I need to add this dependency to make it easier" | Does the spec require this capability? If not, solve it with what's already available. New dependencies need justification. |
| "I'll implement this differently than the plan" | The plan was approved. If you see a better approach, update the plan and get re-approval. Don't silently deviate. |

## Red flags (stop and reassess)

- More than 5 files changing for a single spec — is scope creeping beyond what the spec says?
- Need to modify a test to make it pass — is the implementation wrong, or does the test have a genuine bug?
- Adding a new dependency — does the spec actually require this capability?
- Existing tests breaking — are you accidentally changing behavior the spec didn't touch?
- Implementation feels complex — re-read the spec. Are you building more than what's asked?

## Verification

- [ ] All tests pass — show the test runner output
- [ ] No type errors — show `tsc --noEmit` output (or equivalent)
- [ ] Every AC from the spec diff has corresponding code
- [ ] Every requirement from filled Security / Accessibility / Privacy / Performance / Analytics / Localization / Observability sections is addressed
- [ ] Committed pre-implementable docs are accurate against what was built — either every claim is satisfied as-is, or divergences were captured in a follow-up `docs:` commit / called out in the `feat:` commit body
- [ ] Deployment requirements (env vars, infra) are explicitly listed for the operator
- [ ] No speculative features beyond the spec
- [ ] For UI changes — confirm visual result matches spec (screenshot or manual check)
- [ ] For API changes — show a sample request/response
- [ ] Existing tests still pass (no regressions)

## Principles

- **Plan first, then execute** — present the implementation plan for approval before writing code.
- Build exactly what the spec says — no more, no less.
- The tests define "done". When all tests pass, the implementation is complete.
- For modifications, the git diffs are your scope. Changed ACs = changed code. New tests = new code. Unchanged ACs = unchanged code.
- Follow existing patterns. Don't introduce new patterns unless the spec requires it.
- If something in the spec is unclear or seems wrong, ask the user before implementing a guess.
- Never weaken a test to make it pass — fix the implementation instead.
