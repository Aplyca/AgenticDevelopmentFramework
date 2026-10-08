---
name: debug
description: Investigate an error or unexpected behavior to find the root cause — a command that fails on the bug first, then ranked hypotheses tested one at a time. Use when something breaks.
argument-hint: "[error message or description of the problem]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/debug/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Debug

Find the root cause of an error or unexpected behavior before anything is fixed. The order is the
discipline: a **signal** that fails on this bug, then hypotheses, then the cause. Match the effort to
the bug — when the cause is plain from the code, its regression test is the signal: write it, watch
it fail, and go on to the fix.

## Steps

1. **Understand the symptom** — the exact error, stack trace, or wrong output, pasted rather than
   paraphrased. Where it happens (page, endpoint, command), how reliably, and since when (which
   change, deploy, or content edit). Use the terms in `docs/GLOSSARY.md`, and check the decision
   records for the area.

2. **Check the simple things** — a typo, the wrong file or branch, a stale build or cache, a missing
   environment variable, a server not restarted, dependencies not installed.

3. **Get a failing signal** — one command that fails on *this* bug: it reproduces the reported
   symptom, gives the same verdict on every run, finishes in seconds, and runs without a person.
   Run it, and show the command and its output with secrets replaced by `<REDACTED>`. Roughly in
   order of preference:
   - a failing test at the closest level that reaches the bug — unit, integration, end-to-end;
   - an HTTP request or a short script against the running app;
   - the CLI with a fixture input, compared with known-good output;
   - a headless browser script that asserts on the page, the console, or the network;
   - a captured request, payload, or log, replayed through the code path;
   - a throwaway harness that calls the failing path directly;
   - for "sometimes": the trigger in a loop, in parallel, or with random inputs, until it fails
     often enough to debug against;
   - for "it used to work": `git bisect run` with the command.

   If you can't build one, stop and say what you tried. Ask for access to where it reproduces, a
   captured artifact (logs, a HAR file, a request — redacted), or permission to add temporary
   instrumentation.

4. **Shrink it.** Remove inputs, steps, and configuration one at a time, re-running the signal after
   each cut, until every remaining piece is needed for the failure. A smaller reproduction leaves
   fewer suspects, and it becomes the regression test.

5. **Rank 3–5 hypotheses before testing any.** Trace from the symptom backwards to find candidates,
   and write each as a prediction that could prove it wrong: "if X is the cause, changing Y makes the
   signal pass." Show the ranked list to the developer — they may know which to rule out — and carry
   on without waiting for an answer.

6. **Test one hypothesis at a time.** Each probe answers one prediction; change one thing per run.
   Prefer a debugger or a REPL; otherwise log at the boundary that separates two hypotheses, each
   line tagged with one prefix (`[DEBUG-7f3a]`) so a single search removes them all. For a
   performance problem, measure a baseline first, then bisect. When two hypotheses have been
   disproven, or the bug involves concurrency, caching, or distributed state, suggest `opus` (and a
   higher effort) for the rest of the diagnosis — `sonnet` is the right default before that.

7. **Name the root cause** — the first point where behavior diverges from intent: a line, a
   condition, a state. Not the error message (a symptom) and not a downstream failure (a
   consequence). It explains every observed symptom; if it doesn't, keep going.

8. **Report:**
   - **Symptom** — what was observed
   - **Signal** — the command that fails, and its output
   - **Root cause** — the line, condition, or state, and how it produces the symptom
   - **Ruled out** — the hypotheses disproven, and the evidence
   - **Suggested fix** — what needs to change (conceptual)
   - **How to verify** — the signal passes, and the regression test with it

## After the diagnosis

- **Behavior restored as documented** — the fast lane, or careful when the fix touches a risk area
  (a migration, authorization, personal data, shared code — `specs/README.md` § Lanes): write a
  regression test that reproduces the bug and watch it fail, then fix the root cause and watch it
  pass; commit both together (`fix:`). No spec folder. The regression test is the shrunk
  reproduction, at a level that exercises the bug the way callers hit it. If no such level exists —
  any test you can write would have passed despite this bug — say so in the pull request: the
  code's structure is keeping the bug from being pinned down.
- **The fix changes documented behavior** — it's a change request: light when the requester has
  decided the new behavior, full (`/adf:write-spec`, `/adf:write-plan`, the gate) when there's something to
  decide.
- **Production is broken now** — the careful lane, without delay: the hotfix path in
  `CONTRIBUTING.md`; backfill the spec and docs after.
- **Before committing, clean up:** remove every `[DEBUG-…]` line (search the prefix), delete
  throwaway harnesses and scripts, and state the confirmed cause in the commit body so the next
  person debugging this area learns from it.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I think I know what's wrong, let me just fix it" | Guessing causes whack-a-mole debugging. Diagnose first, fix second. A wrong fix hides the real cause. |
| "I'll read the code until I spot it" | Without a failing signal you can't tell a fix from a coincidence. Get the signal first — when the cause is plain, the regression test is the signal. |
| "My first hypothesis is good enough" | The first plausible idea anchors you. Ranking three to five makes you name what would prove each one wrong. |
| "I'll log everything and search the output" | Everything printed stays in the conversation and is paid for on every later call. Log at the boundary between two hypotheses, tagged. |
| "Let me add a try/catch to handle this error" | Catching an error is not fixing it. The root cause still exists and will surface elsewhere. |
| "It works now after my change, so the bug is fixed" | Coincidental fixes are dangerous. Verify that your explanation accounts for ALL symptoms, not just the one you noticed. |
| "This is probably a library bug" | It almost never is. Read your own code first. If it truly is a library bug, show the evidence. |
| "I can't reproduce it, so it's probably resolved" | Intermittent bugs are the most dangerous. Raise the failure rate — loop it, add load, vary inputs — or ask for a captured artifact. |

## Red flags (stop and reassess)

- You have a theory and no command that fails on this bug
- Your signal fails for a reason other than the reported symptom — that's a different bug
- You've been investigating for more than 10 minutes without narrowing down — step back and re-read the error message literally
- The fix involves adding code but you haven't identified what's wrong — you're patching symptoms, not fixing causes
- Multiple unrelated things seem broken — you may be on the wrong branch, missing dependencies, or have a stale cache
- The error message doesn't match the code you're reading — check you're looking at the right file/version

## Verification

- [ ] A command that fails on this bug was run and shown — or the developer was told why none could be built, and what would help
- [ ] Hypotheses were ranked; each disproven one is reported with its evidence
- [ ] Root cause identified — specific file, line, and condition — and it explains ALL observed symptoms
- [ ] Suggested fix addresses the root cause, not a symptom
- [ ] "How to verify" names the signal and the regression test
- [ ] No `[DEBUG-…]` lines or throwaway scripts are left behind

## Principles

- Signal first, theory second. A command that fails on the bug turns guessing into checking.
- Never guess. If you can't determine the root cause, say what you've ruled out.
- Read the actual code. Don't assume what a function does based on its name.
- Fix root causes, not symptoms. A try/catch that hides an error is not a fix.
