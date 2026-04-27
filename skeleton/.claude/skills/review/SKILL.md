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

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The code looks fine, no issues found" | Every change has something worth noting. If you found zero issues, you didn't look hard enough. At minimum, confirm spec compliance explicitly. |
| "This is a small change, a quick review is enough" | Small changes cause big bugs. SQL injection is one line. Review every changed line regardless of size. |
| "I'll skip the security review, this doesn't touch user input" | Data flows through layers. A component that doesn't directly handle input may render unsanitized data passed from one that does. Trace the data flow. |
| "The tests pass, so the code is correct" | Tests verify behavior, not quality. Passing tests don't catch: convention violations, security issues, unnecessary complexity, or missing edge cases not yet tested. |

## Red flags (stop and reassess)

- Change touches authentication, authorization, or payment code — escalate to a thorough security review
- New dependency added — does it earn its place? Could the problem be solved without it?
- Error handling catches and silences exceptions — the root cause may be hidden
- Code duplicated instead of reusing existing patterns — check if a shared utility already exists
- Git diff is larger than expected for the spec scope — is unrelated work mixed in?

## Verification

- [ ] Every finding includes: file path, line number, severity, and suggested fix
- [ ] Spec compliance confirmed — each AC from the spec is addressed in code
- [ ] Security review completed for any file handling data or external input
- [ ] Test coverage confirmed — each AC has a corresponding test

## Principles

- Review against the spec, not personal preference.
- Flag real issues, not theoretical ones. "This could be a problem if..." is only worth raising if the scenario is realistic.
- Suggest fixes, not just problems.
