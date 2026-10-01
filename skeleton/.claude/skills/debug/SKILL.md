---
name: debug
description: Investigate an error or unexpected behavior to find the root cause. Use when something breaks.
argument-hint: "[error message or description of the problem]"
---

# Debug

Systematically investigate an error or unexpected behavior to identify the root cause.

## Steps

1. **Understand the symptom** — What exactly is happening? Get the full error message, stack trace, or description of the unexpected behavior. Clarify:
   - Where does it happen? (which page, endpoint, command)
   - Is it consistent or intermittent?
   - When did it start? (after which change)

2. **Check the simple things first** — Before deep investigation:
   - Is there a typo in the code?
   - Is the right file being edited? (stale cache, wrong branch)
   - Are environment variables set correctly?
   - Is the dev server running / has it been restarted after changes?
   - Are dependencies installed? (`npm install`, etc.)

3. **Trace the execution path** — Start from the symptom and work backwards:
   - Which function produced the error?
   - What called that function, with what arguments?
   - Where does the actual behavior diverge from the expected behavior?

4. **Isolate the root cause** — The root cause is the FIRST point where behavior diverges from intent. It is NOT:
   - The error message (that's a symptom)
   - A downstream failure (that's a consequence)
   - "It doesn't work" (that's a description, not a cause)

5. **Verify the hypothesis** — Confirm the root cause explains ALL observed symptoms. If it doesn't explain everything, keep investigating.

6. **Report** — Present findings:
   - **Symptom**: what was observed
   - **Root cause**: the specific line/condition/state that causes it
   - **Explanation**: how the root cause produces the symptom
   - **Suggested fix**: what needs to change (conceptual)
   - **How to verify**: how to confirm the fix works

## After the diagnosis

- **Behavior restored as documented** — write a regression test that reproduces the bug and watch it
  fail, then fix the root cause and watch it pass; commit both together (`fix:`). No spec needed.
- **The fix changes documented behavior** — it's a change request: amend the feature's spec folder
  (`/write-spec`) before fixing.
- **Production is broken now** — hotfix path in `CONTRIBUTING.md`; backfill the spec and docs after.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I think I know what's wrong, let me just fix it" | Guessing causes whack-a-mole debugging. Diagnose first, fix second. A wrong fix hides the real cause. |
| "Let me add a try/catch to handle this error" | Catching an error is not fixing it. The root cause still exists and will surface elsewhere. |
| "It works now after my change, so the bug is fixed" | Coincidental fixes are dangerous. Verify that your explanation accounts for ALL symptoms, not just the one you noticed. |
| "This is probably a library bug" | It almost never is. Read your own code first. If it truly is a library bug, show the evidence. |
| "I can't reproduce it, so it's probably resolved" | Intermittent bugs are the most dangerous. Identify the conditions that trigger it, even if you can't reproduce consistently. |

## Red flags (stop and reassess)

- You've been investigating for more than 10 minutes without narrowing down — step back and re-read the error message literally
- The fix involves adding code but you haven't identified what's wrong — you're patching symptoms, not fixing causes
- Multiple unrelated things seem broken — you may be on the wrong branch, missing dependencies, or have a stale cache
- The error message doesn't match the code you're reading — check you're looking at the right file/version

## Verification

- [ ] Root cause identified — specific file, line, and condition
- [ ] Explanation accounts for ALL observed symptoms
- [ ] Suggested fix addresses the root cause, not a symptom
- [ ] "How to verify" step is concrete and actionable

## Principles

- Never guess. If you can't determine the root cause, say what you've ruled out.
- Read the actual code. Don't assume what a function does based on its name.
- Fix root causes, not symptoms. A try/catch that hides an error is not a fix.
