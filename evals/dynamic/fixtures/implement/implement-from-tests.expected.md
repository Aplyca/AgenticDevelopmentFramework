# Expected — implement plans against full spec + docs

The AI's Phase 1 output (implementation plan) should satisfy ALL of these invariants.

## Behavior invariants

- [ ] AI presents a PLAN first (does NOT immediately write code)
- [ ] AI explicitly waits for approval
- [ ] AI confirms it ran git diff on spec, test, and docs commits
- [ ] AI confirms it ran the test suite to verify red state

## Plan structure invariants

- [ ] Plan has a task breakdown in dependency order
- [ ] Each task lists: file path, what changes, which test(s) it makes pass
- [ ] Tasks reference doc claims they need to honor (or surface as needing reconciliation)
- [ ] Files explicitly NOT touched are listed (the agent's commitment)

## Coverage invariants — every filled section addressed

- [ ] Plan addresses Functional ACs (form rendering, validation, submission)
- [ ] Plan addresses Security requirements (reCAPTCHA integration, rate limiter, server-side validation)
- [ ] Plan addresses Accessibility requirements (ARIA roles, label association, keyboard navigation, focus management)
- [ ] Plan addresses Privacy requirements (IP TTL, data handling)
- [ ] Plan addresses Performance requirements (the 500ms SLA approach)
- [ ] Plan addresses Observability if specified
- [ ] Plan addresses Deployment preconditions (env vars for reCAPTCHA secret, Salesforce credentials)

## Doc-as-design-context invariants

- [ ] Plan references the committed admin guide (e.g., "we promised X in docs/admin/contact-form.md, the implementation must do X")
- [ ] If the plan diverges from a doc claim, it explicitly flags: "this approach differs from doc claim Y; we'll reconcile in step N"
- [ ] AI mentions Phase 4 doc reconciliation as a normal sub-step (not an exception)

## Docs-enforcement invariants (variant: missing docs commit)

- [ ] AI REFUSES to plan when pre-impl docs are listed in the spec but not committed
- [ ] AI tells the user to run `/write-docs` first
- [ ] AI does NOT proceed with planning despite the missing commit

## Anti-pattern invariants

- [ ] Plan does NOT contain code in Phase 1
- [ ] Plan does NOT skip filled sections (no "we'll add Accessibility later")
- [ ] Plan does NOT silently exceed scope (no files outside the spec's footprint)
- [ ] AI does NOT modify a test to make it pass (tests are the contract)

## Pass criteria

All Behavior + Plan structure + Coverage (every section) + Doc-as-context + Anti-pattern invariants must pass. Docs-enforcement invariants required only for the variant case.
