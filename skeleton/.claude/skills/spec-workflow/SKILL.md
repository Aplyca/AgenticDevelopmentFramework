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

### Phase 2: Implement

6. **Identify scope from diff** — Run `git diff HEAD~1` (or diff against the spec commit) to see exactly what changed. This tells you the precise scope: new acceptance criteria added, existing criteria modified, edge cases added, etc.
7. **Implement** — Use `/implement`. Build exactly what the spec diff shows — no more, no less.
8. **Write tests** — Use `/write-tests`. Every acceptance criterion becomes at least one test.
9. **Review** — Use `/review`. Address findings.

### Phase 3: Ship

10. **Commit implementation** — Use `/commit`. Reference the spec in the commit message:
    ```
    feat: implement user registration
    fix: add retry logic to payment flow
    ```
11. **Verify** — For UI changes, run the app and confirm the result matches the spec.
12. **Deploy** — Follow the project's deployment process.

### Why commit the spec first?

- The implementation agent reads `git diff` to know the **exact scope** of what changed
- For modifications, the diff shows precisely which acceptance criteria were added, changed, or removed — the agent doesn't need to guess what's new vs existing
- Spec and code changes are separate commits in history — easy to review intent separately from execution
- If implementation goes wrong, the spec commit is preserved and you can retry cleanly

## Workflow 3: Hotfix (production-breaking bugs only)

Use this ONLY for critical production issues that need immediate resolution.

1. **Fix the issue** — Use `/debug` to find the root cause, then fix it directly
2. **Write a regression test** — Ensure the bug can't recur
3. **Commit and deploy** — Use `/commit` with the `fix:` prefix
4. **Backfill the spec** — After the fix is deployed, update or create a spec if the fix changes behavior. Commit the spec update separately.

Hotfixes skip the spec-first process because speed matters. But always backfill — undocumented behavior changes create confusion later.
