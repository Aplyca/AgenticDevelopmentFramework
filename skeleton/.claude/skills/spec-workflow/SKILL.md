---
name: spec-workflow
description: Spec-driven development workflow — check, write, approve, implement, test, verify
user_invocable: true
---

# Development Workflows

This project follows three workflows depending on the situation.

## Workflow 1: Project Setup (one-time)

Use `/init-project` for first-time setup. The key output is technical documentation that serves as persistent context for AI agents throughout the project:

1. Customize `CLAUDE.md` with project identity, stack, and critical rules
2. Customize `.claude/rules/` (files with `<!-- CUSTOMIZE -->` markers)
3. Write initial technical docs:
   - `docs/ARCHITECTURE.md` — system context, components, data flow, tech stack rationale
   - `docs/security/SECURITY.md` — auth scheme, data classification, threat model
   - `docs/infrastructure/OVERVIEW.md` — platform, environments, CI/CD
   - `docs/GLOSSARY.md` — domain terminology for consistent language
4. Commit all configuration and documentation

These docs are not just for humans — AI agents read them before every design review, security audit, and implementation task. Invest in them early.

## Workflow 2: Feature Development (new features, modifications, bug fixes)

Use this for any planned change — new features, modifications to existing features, or non-urgent bug fixes.

### Phase 1: Spec

1. **Check existing specs** — Read `specs/` before starting. If a spec exists for the area you're touching, update it rather than creating a new one.
2. **Write or update the spec** — Use `/write-spec`. Include acceptance criteria, edge cases, and out-of-scope boundaries. For modifications, clearly state what changes and what stays the same.
3. **Architecture review** — For non-trivial changes, use `@architect` to validate the approach. Skip for small changes or bug fixes.
4. **Get user approval** — Present the spec for review. Iterate until approved. Set status to `approved`.
5. **Commit the spec** — Commit the approved spec (and any updated docs) BEFORE starting implementation:
   ```
   spec: add user registration spec
   spec: update payment flow — add retry logic
   ```

### Phase 2: Test (TDD — plan, then write tests)

6. **Plan the tests** — Use `/write-tests`. The agent reads the spec and its diff, maps each AC and edge case to a test, and presents the **test plan** (AC → test mapping) for your approval. No tests are written yet.
7. **Approve the test plan** — Review the mapping. Are all ACs covered? Are edge cases included? Iterate until satisfied.
8. **Write the tests** — After approval, the agent writes the tests following the plan.
9. **Run tests — they should all fail** — This confirms the tests are meaningful. A test that passes before implementation is either testing the wrong thing or testing something that already exists.
10. **Commit the tests** — Use `/commit` with the `test:` prefix:
    ```
    test: add registration flow tests (red — pending implementation)
    test: add retry logic tests for payment flow (red — pending implementation)
    ```

### Phase 3: Implement (plan, then make the tests pass)

11. **Plan the implementation** — Use `/implement`. The agent reads the spec diff, test diff, and existing code, then presents an **implementation plan** (which files to change, what each change does, in what order) for your approval. No code is written yet.
12. **Approve the implementation plan** — Review the plan. Does it address all failing tests? Is the approach sound? Iterate until satisfied.
13. **Implement** — After approval, the agent writes code following the plan until all tests pass.
14. **Run tests — they should all pass** — If any test fails, fix the implementation (not the test, unless the test has a bug).
15. **Review** — Use `/review`. Address findings.

### Phase 4: Ship

16. **Commit implementation** — Use `/commit`. Reference the spec in the commit message:
    ```
    feat: implement user registration
    fix: add retry logic to payment flow
    ```
17. **Verify** — For UI changes, run the app and confirm the result matches the spec.
18. **Deploy** — Follow the project's deployment process.

### Why commit specs and tests before implementing?

- **Spec commit** captures **intent** — the implementation agent reads its `git diff` to know the exact scope
- **Test commit** captures the **verification contract** — failing tests define exactly what "done" means
- **Implementation commit** captures **execution** — code that makes the tests pass
- For modifications, the diffs show precisely which ACs and tests were added or changed — the agent doesn't re-implement or re-test what's unchanged
- Each commit type is separate in history — easy to review intent, contract, and execution independently
- If implementation goes wrong, the spec and test commits are preserved and you can retry cleanly

## Workflow 3: Hotfix (production-breaking bugs only)

Use this ONLY for critical production issues that need immediate resolution.

1. **Fix the issue** — Use `/debug` to find the root cause, then fix it directly
2. **Write a regression test** — Ensure the bug can't recur
3. **Commit and deploy** — Use `/commit` with the `fix:` prefix
4. **Backfill the spec** — After the fix is deployed, update or create a spec if the fix changes behavior. Commit the spec update separately.

Hotfixes skip the spec-first process because speed matters. But always backfill — undocumented behavior changes create confusion later.
