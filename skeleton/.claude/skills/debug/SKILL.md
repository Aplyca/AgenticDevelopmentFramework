---
name: debug
description: Investigate an error or unexpected behavior to find the root cause. Use when something breaks.
user_invocable: true
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

## Principles

- Never guess. If you can't determine the root cause, say what you've ruled out.
- Read the actual code. Don't assume what a function does based on its name.
- Fix root causes, not symptoms. A try/catch that hides an error is not a fix.
