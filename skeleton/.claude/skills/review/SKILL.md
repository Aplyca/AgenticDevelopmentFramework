---
name: review
description: Multi-perspective review of a change against its spec folder — acceptance criteria and every filled spec section, the approved change surface, the constitution, conventions (including the comments rule), security, UX, test evidence, and doc accuracy. Use before delivering a change; escalate to the /deep-review workflow for high-stakes diffs.
argument-hint: "[spec folder, branch, or files to review]"
---

# Review

Review a change before it's delivered, in this conversation. Review against the spec folder and the
project's rules — not personal preference. For high-stakes or large diffs (auth, payments, personal
data, migrations, more than a few hundred lines), the user can run the `/deep-review` workflow
instead: separate reviewers per dimension, each finding independently verified.

## Steps

1. **Read the context:** the spec folder (`spec.md` every filled section, `plan.md` change surface and
   test strategy, `tasks.md` and its gate results), `docs/CONSTITUTION.md`, and — when the change
   touches them — `docs/ARCHITECTURE.md` and `docs/security/SECURITY.md`.

2. **See what changed:** `git diff <base>...HEAD` and `git log --oneline <base>..HEAD`.

3. **Scope and traceability:**
   - Every changed file is inside the approved change surface — or the extension is recorded in
     `plan.md` with a re-confirmation in `approvals:`.
   - Commits map to tasks (one task, one commit); nothing unrelated is bundled in.
   - The spec folder and tracker task are linked; for a change request, the `CR N` section exists.

4. **Spec compliance:** each AC — and each requirement from every filled section (Security,
   Accessibility, Privacy, Performance, Analytics, Localization, Observability, Deployment) — is
   implemented. Nothing beyond the spec was built.

5. **Constitution gates:** walk every principle in `docs/CONSTITUTION.md` against the diff — e.g.
   authorization never loosened without justification, no edits to existing migrations, no silenced
   types or disabled linters, no unjustified dependency.

6. **Code quality** (per `.claude/rules/`): types, naming, error handling, existing patterns, no
   premature abstraction or speculative code — and **the comments rule**: flag comments that restate
   the code, repeat signatures, narrate steps, label sections, or record history; keep only the ones
   that state an invisible *why*.

7. **Security:** user input reaching HTML, SQL, shell, headers, or paths; secrets in code or client
   bundles; validation at boundaries; error details hidden from clients.

8. **UX** (UI changes): matches the spec's stories, design, and committed docs; loading, empty, and
   error states; consistent language; accessible interaction (semantic HTML, keyboard, labels).

9. **Test evidence:** every AC and testable requirement has a test; `tasks.md` § Gate results shows
   red-then-green per task, the commands that ran, and what didn't run and why. Claims without
   evidence are findings.

10. **Doc accuracy:** committed docs match what was built; divergences were reconciled in `docs:`
    commits or called out in a task commit's body.

11. **Pull request description** (if one exists): it matches the diff — no phantom changes, no
    omissions, "not verified" items stated honestly.

12. **Report** findings by severity, each with `file:line` and a suggested fix:
    - **Critical** — must fix before delivery (security, spec violation, constitution breach, crash)
    - **Warning** — should fix (likely bug, convention violation, missing evidence)
    - **Nit** — minor (style, naming)
    End with: **approve**, **approve with nits**, or **request changes** — and what you did not review.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The code looks fine, no issues found" | Every change has something worth noting. At minimum, state spec compliance, change-surface compliance, and what you checked. |
| "It's a small change, a quick look is enough" | Small changes cause big bugs. An injection is one line. Review every changed line. |
| "It doesn't touch user input, so I'll skip security" | Data flows through layers; trace it. A component that renders data can be the injection point. |
| "The tests pass, so it's correct" | Tests verify behavior, not conventions, security, scope, or missing edge cases. Green is necessary, not sufficient. |
| "These extra files are harmless" | Files outside the approved change surface are a finding until the plan records them and the developer re-confirms. |
| "The comments are helpful, leave them" | Comments that restate code drift from it. Keep only the invisible *why*. |

## Red flags (stop and reassess)

- The change touches authentication, authorization, payments, or personal data — escalate (`/deep-review`, `@security-reviewer`).
- A new dependency appeared that the plan didn't approve.
- Errors are caught and silenced.
- The diff is far larger than the plan's change surface suggested.
- Gate results claim tests ran, but there's no output or counts.

## Verification

- [ ] Every finding has `file:line`, severity, and a suggested fix
- [ ] Change-surface compliance stated explicitly
- [ ] Each AC and each filled-section requirement checked against the code
- [ ] Constitution principles walked against the diff
- [ ] Security reviewed for every file that handles data or external input
- [ ] Test evidence checked in `tasks.md` § Gate results
- [ ] Doc accuracy confirmed, and the pull request description compared with the diff (if one exists)

## Principles

- Review against the spec, the plan, and the constitution — not preference.
- Flag real issues, with fixes; theoretical ones only when the scenario is realistic.
- Evidence over claims; scope over enthusiasm.
