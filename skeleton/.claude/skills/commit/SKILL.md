---
name: commit
description: Review changes and create a well-structured git commit. Use when ready to commit your work.
user_invocable: true
---

# Commit Code

Review all changes and create a clean, meaningful commit.

## Steps

1. **Check what changed** — Run `git status` and `git diff` to see all staged and unstaged changes. Understand every file that will be committed.

2. **Determine the commit type** — What kind of change is this?

   **Spec commits** (specs, docs, architecture decisions — before tests and implementation):
   ```
   spec: add user registration spec
   spec: update payment flow — add retry logic
   docs: add initial architecture overview
   docs: record ADR-001 — choose PostgreSQL over MongoDB
   ```

   **Test commits** (tests from spec ACs — before implementation, tests should fail):
   ```
   test: add registration flow tests (red — pending implementation)
   test: add retry logic tests for payment flow (red — pending implementation)
   ```

   **Implementation commits** (code that makes the tests pass — after spec and tests are committed):
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
   - **For spec commits**: is the spec approved? Are doc changes accurate?
   - **For test commits**: do tests fail? (They should — no implementation yet.) Do they map to spec ACs?
   - **For implementation commits**: do all tests pass? Does the implementation match the spec?

4. **Stage the right files** — Add files by name, not with `git add .` or `git add -A`. This prevents accidentally committing sensitive or unrelated files.

5. **Write the commit message**:
   - First line: concise imperative summary (what and why, not how)
   - Keep under 72 characters
   - If more context is needed, add a blank line then a body paragraph
   - Reference the spec or issue if applicable

6. **Create the commit** — Stage files and commit. Don't skip hooks (`--no-verify`) or amend previous commits unless explicitly asked.

7. **Verify** — Run `git log -1` and `git status` to confirm the commit looks correct and no files were missed or accidentally included.

## Principles

- One logical change per commit. Don't bundle unrelated work.
- Spec changes and implementation changes are separate commits — never mix intent with execution.
- Commit message explains WHY, the diff shows WHAT.
- Never commit secrets, credentials, or sensitive data.
- Prefer creating a new commit over amending, unless asked otherwise.
