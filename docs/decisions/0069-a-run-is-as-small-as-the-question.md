# 0069: A test run is as small as its question, and each behavior is tested once at its cheapest layer

- **Status:** accepted
- **Date:** 2026-11-07
- **Amends:** [0058](0058-test-tiers-and-feature-suites-with-vitest.md) — when `@smoke` runs, and the
  order of runs while iterating

## Context

- **On an adopting project, the implementation loop spent a third of its time rerunning one file.**
  A full-lane feature of 14 tasks, on a project whose only tests are end to end, put its 60-odd tests
  in one file. Eight times, after a task, the agent ran that whole file — 70 to 150 seconds each,
  about 10 of the loop's 32 minutes. A run of the task's own 2–7 tests took 15–30 seconds.
- **It followed the framework's text.** `.claude/rules/testing.md` said "While iterating, run the
  file, then its feature suite". With one test file per feature, "the file" is the feature's every
  test. `/adf:implement` step 8 said "plus the neighboring tests", which nothing defined, and the
  plan's verification checklist — under a heading that read "each checkpoint" — named the whole file
  as "the task's tests".
- **The budget counted tokens, not time.** Output was already trimmed to a few lines; waiting for a
  slow run costs no tokens, so nothing in the text weighed it.
- **The layer had no weight at planning time.** `testing.md` § End-to-end says a rule is tested at
  the unit level, but `/adf:write-plan`'s Test strategy only asked for a named test per requirement,
  and `testing.md` loads only when a test file is read. The builder's pure logic was tested end to
  end because the project had no other layer, and nothing put that in front of the developer.
- **A test passed before any code, and the agent took its red from the typecheck.** An earlier task
  already did what the test checked. The agent narrowed a type so five files failed to compile, and
  called that the red. `/adf:implement` already rejected an import error as a red; a type error is
  the same kind of failure.

## Decision

- **`testing.md` opens with a strategy:** test what a requirement needs, once — not again in
  another test or layer; at the cheapest layer that proves it; repeat a check across variants
  (screens, locales, roles, inputs) only where each runs code of its own; a slow test pays its setup
  once; run only what the question needs, by tag, path, or name. It names no engine, language, or
  architecture.
- **Each run waits for its point** (`testing.md` § Verification budget):
  - **each red and green:** the tests written or changed, by name — or their file, when it runs in
    seconds — and static checks on the changed files;
  - **a phase's end** (in the fast and careful lanes, the change green): the touched feature suite
    once, a sanity check of that area, plus `@smoke` when the phase changed shared code,
    configuration, or the stack;
  - **before the local check:** `@critical`; **before delivery:** the full gate, once.
  A slow run never follows every task; a failure at a phase's end is traced through its task
  commits.
- **`@smoke` no longer runs "while iterating".** It runs after a phase that changed shared code,
  configuration, or the stack, and inside every wider tier. **Sanity** is a name for the phase-end
  feature-suite run, not a fourth tier; `@critical` holds the critical paths.
- **`/adf:write-plan`** maps each requirement to the cheapest layer that proves it, tested once, and
  lists a layer the project lacks as a risk at the gate. Adding it is the developer's call. The
  verification checklist names the commands for one test by name, a feature suite, and the full
  gate; its heading reads "the full gate, once before delivery".
- **A test that passes first** (`/adf:implement` step 6): a wrong test is fixed until it fails for
  the right reason; behavior that already exists is said in one line, and the test becomes a pin —
  break the behavior on purpose, watch it fail, restore it — with the rest of the task in the same
  commit, prefixed for what it does (`refactor:` when no behavior changes). When the agent can't tell
  which, it stops and asks. A type or compile error is never the red.

## Consequences

- **Positive:**
  - In the measured loop, the eight whole-file runs become one, at the phase's end: about nine
    minutes less, with the same tests.
  - Plans weigh layers before the gate, and a missing unit layer reaches the developer as a risk
    instead of staying an unspoken constraint.
  - One task stays one commit when its test passes first.
- **Negative / cost:**
  - **A regression surfaces later:** a break in a phase's third task shows at the phase's end. The
    task commits, one per task, bound the search.
  - **The vocabulary moves:** projects whose `testing.md` or commands say `@smoke` runs while
    iterating merge the new line.

## Alternatives considered

- **Define "neighboring tests" as the task's tests plus the tests of the files it changed.** Declined:
  when a feature's tests all exercise the same shared module, that selects the whole file again.
- **Widen whenever a task changes behavior other tests check.** Declined: an agent can argue every
  change to shared code qualifies, which is how the eight runs happened.
- **A run-cost column in the plan's test strategy.** Declined: every row of an end-to-end-only
  project would read the same. One sentence on the cheapest layer does the work.
- **A fourth tier, `@sanity`.** Declined: a sanity check is the touched feature suite, which a path
  already selects; a tag would be one more to keep current.
