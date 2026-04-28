---
name: commit
description: Review changes and create a well-structured git commit. Use when ready to commit your work.
user_invocable: true
---

# Commit Code

Review all changes and create a clean, meaningful commit.

## Steps

1. **Check what changed** — Run `git status` and `git diff` to see all staged and unstaged changes. Understand every file that will be committed.

2. **Determine the commit type** — What kind of change is this? The full feature workflow is: spec → tests → docs → implement.

   **Spec commits** (Phase 1 — multi-perspective spec, before everything else):
   ```
   spec: add user registration spec
   spec: update payment flow — add retry logic
   ```

   **Test commits** (Phase 2 — tests from spec ACs and testable requirements, before docs and implementation, tests should fail):
   ```
   test: add registration flow tests (red — pending implementation)
   test: add retry logic tests for payment flow (red — pending implementation)
   ```

   **Doc commits** (Phase 3 — pre-implementable user-facing docs, before implementation):
   ```
   docs: add admin guide and end-user copy defaults for newsletter signup
   docs: add OpenAPI schema for /api/users endpoint
   ```
   Also used for Phase 4 doc reconciliation (when implementation surfaces meaningful divergence) and standalone updates (architecture, security, ADRs):
   ```
   docs: update admin guide for first-name field (post-impl reconciliation)
   docs: add initial architecture overview
   docs: record ADR-001 — choose PostgreSQL over MongoDB
   ```

   **Implementation commits** (Phase 4 — code that makes the tests pass; small doc fixes can fold in here, called out in the body):
   ```
   feat: implement user registration
   fix: add retry logic to payment flow
   refactor: extract shared validation into lib/validate
   ```

3. **Verify before committing**:
   - Are all changes related to one logical task? If not, split into separate commits.
   - Are there any files that should NOT be committed?
     - Generated files (build output, cache directories)
     - Environment files (`.env`, `.env.local`, credentials)
     - Test artifacts (screenshots, reports, coverage)
     - Debug code (console.log, temporary hacks)
   - **For spec commits**: is the spec approved? Are required sections filled? Are doc changes accurate?
   - **For test commits**: do tests fail? (They should — no implementation yet.) Do they map to spec ACs and testable requirements?
   - **For doc commits**: are claims sourced from the spec and tests? Do they match committed behavior (or describe intended pre-impl behavior)?
   - **For implementation commits**: do all tests pass? Does the implementation match the spec? Are committed docs still accurate, or are doc updates included/called out?

4. **Stage the right files** — Add files by name, not with `git add .` or `git add -A`. This prevents accidentally committing sensitive or unrelated files.

5. **Write the commit message**:
   - First line: concise imperative summary (what and why, not how)
   - Keep under 72 characters
   - If more context is needed, add a blank line then a body paragraph
   - Reference the spec or issue if applicable

6. **Create the commit** — Stage files and commit. Don't skip hooks (`--no-verify`) or amend previous commits unless explicitly asked.

7. **Verify** — Run `git log -1` and `git status` to confirm the commit looks correct and no files were missed or accidentally included.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll use `git add .` to save time" | This stages everything, including secrets, build artifacts, and unrelated changes. Always stage by name. |
| "I'll combine the spec and implementation in one commit" | Spec, tests, docs, and code are separate commits — intent, verification contract, design intent for usage, and execution must be reviewable independently. |
| "I'll skip the docs commit since the docs are small" | If pre-implementable docs are listed in the spec, they get a `docs:` commit before implementation. Small docs are still docs. |
| "I'll skip the hooks, they're slow" | Hooks exist to catch mistakes. `--no-verify` bypasses safety checks. Fix the hook issue, don't skip it. |
| "I'll amend the previous commit to keep history clean" | Amending rewrites history and can destroy work. Create a new commit unless the user explicitly asks to amend. |
| "This debug code is fine to commit, I'll clean it up later" | Console.logs, commented-out code, and temporary hacks don't belong in commits. Clean up now. |

## Red flags (stop and reassess)

- `.env`, credentials, or API keys in the staged files — never commit secrets
- More than 10 files in a single commit — is this really one logical change?
- Spec files and implementation files in the same commit — these should be separate
- Test files and implementation files in the same commit (for new features) — tests come first
- Pre-implementable docs (admin guides, API specs) and implementation in the same commit — docs come first; only small doc reconciliations may fold into the `feat:` commit (called out in the body)
- Untracked files that weren't part of the task — investigate before including them

## Verification

- [ ] `git status` shows only the intended files staged
- [ ] Commit message follows the project's prefix convention
- [ ] No secrets, credentials, or debug code in staged files
- [ ] `git log -1` confirms the commit looks correct
- [ ] `git status` after commit shows a clean working tree (or only unrelated changes)

## Principles

- One logical change per commit. Don't bundle unrelated work.
- Spec changes and implementation changes are separate commits — never mix intent with execution.
- Commit message explains WHY, the diff shows WHAT.
- Never commit secrets, credentials, or sensitive data.
- Prefer creating a new commit over amending, unless asked otherwise.
