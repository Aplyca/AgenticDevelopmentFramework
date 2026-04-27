---
name: review
description: Review code for quality, security, and spec compliance. Use before committing changes.
user_invocable: true
argument-hint: "[file or feature to review]"
---

# Review Code

Run a multi-perspective review of code changes before committing.

## Steps

1. **Read project context** — Read `docs/ARCHITECTURE.md` (if it exists) for system design and data flow. Read `docs/security/SECURITY.md` (if it exists) for security requirements. These inform what to look for during review.

2. **Identify what changed** — Check `git diff` and `git status` to see all modified and new files.

3. **Code quality review** — For each changed file, check:
   - Does it match the spec's acceptance criteria?
   - Does it follow project conventions in `.claude/rules/`?
   - Are there type safety issues, missing error handling, or naming inconsistencies?
   - Is there unnecessary complexity, premature abstraction, or speculative code?

4. **Security review** — For files that handle data or external input:
   - Any injection vulnerabilities (user input in HTML, SQL, shell, headers)?
   - Any credentials or secrets exposed in client code or committed files?
   - Is input validated at system boundaries?
   - Are error details hidden from client responses?

5. **UX review** — For UI changes:
   - Does the UI match the spec's user stories?
   - Are loading, empty, and error states handled?
   - Is the language consistent with the rest of the app?
   - Are interactive elements accessible (semantic HTML, keyboard support)?

6. **Test coverage** — Are there tests for each acceptance criterion? Do existing tests still pass after the changes?

7. **Report findings** — Present issues grouped by severity:
   - **Critical**: must fix before commit (security issues, spec violations, crashes)
   - **Warning**: should fix (potential bugs, convention violations)
   - **Nit**: minor suggestions (style, naming preferences)

## Principles

- Review against the spec, not personal preference.
- Flag real issues, not theoretical ones. "This could be a problem if..." is only worth raising if the scenario is realistic.
- Suggest fixes, not just problems.
