---
name: vitest
description: Set up or audit this project's unit and integration tests to the specification this skill carries — Vitest, three cumulative tiers (@smoke, @critical, regression) and feature suites (a folder per feature, listed in docs/TEST-SUITES.md), run with npm test and its tier scripts or make test tier= suite=. Use when a project has no unit or integration suite, when tests should be runnable by tier or by feature, or when a feature adds a critical behavior. A change's own tests come from /adf:write-tests.
argument-hint: "[set up | audit | tag | feature suites]"
---

> **Step 0 — which copy.** This is the packaged copy, from the `vitest` module, carried by `adf-dev` ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/vitest/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Unit and integration tests, by tier and by feature suite

Most tests are unit and integration tests, and most runs should be small. This skill sets a suite up
so a developer or an agent can run the smoke tests in seconds, the critical ones on every pull
request, everything before a release — and any of them for one feature. It doesn't write a change's
tests: those come first, from the spec, with `/adf:write-tests` and `/adf:implement`, tagged and
placed as `.claude/rules/testing.md` § Tiers and feature suites says.

## The specification

**`<this skill's base directory>/SPECIFICATION.md` is what the suite must be** — the engine, its
layout, the tiers (T), the feature suites (U), and the test-first flow, each requirement with an ID. Read it
before any mode below. **There are no templates:** write the project's configuration to it. A suite
is done when its runs prove it. Name the requirement's ID whenever you report a gap.

## Safety (always)

- **No real third party, and the developer's own database never.** Integration tests use a test
  database or an in-memory store (S5).
- **No weakened tests.** Never add a skip, a retry, or a loosened assertion to get to green, and
  never retag a failing test to a later tier to hide it.
- **Packages are pinned and installed deliberately.** Choose the newest Vitest release at least two
  weeks old; ask before adding any dependency beyond `vitest` and `@vitest/coverage-v8`.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`).
   Unless its `modules:` list names `vitest`, say "the vitest module isn't installed in this
   project — `/adf:upgrade` offers it" and stop.
2. **Check where you are.** If `ops/agent/worktree.conf` (or `scripts/agent/worktree.conf`) exists
   and `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`, this is the main checkout,
   which takes no edits. Say so in a line, read nothing more, and run `/adf:dispatch` now with
   `test/vitest` as the branch, without asking first.
3. **Read the facts, running nothing yet:** the app's `package.json`, any test runner already
   there (`jest.config.*`, `vitest.config.*`, `mocha`), where tests live now, the `Makefile` and
   `ops/` when the stamp names `docker`, `.claude/rules/testing.md`, and `AGENTS.md`. A project
   that isn't a JavaScript or TypeScript app: say the module doesn't apply and stop (§ The engine).
4. **Name the mode** in one line, from the argument or the situation: no Vitest → set up; Vitest
   there that doesn't meet the specification → audit; a feature that needs tier tags → tag; test
   folders not in the list → feature suites.

## Mode: set up

1. **Triage it.** `/adf:triage`, the careful lane at least, done when "`test:smoke`,
   `test:critical`, and `test` pass, and one test per tier was seen failing".
2. **Agree on the feature suites.** From the folders and the delivered features, propose the feature suite list — name,
   folders, what it covers — and the developer decides (U1). Wait.
3. **Write the configuration (S1–S5, T3).** Add Vitest at the chosen version to `devDependencies`,
   pinned exactly; `vitest.config.ts` with the `unit` and `integration` projects; the five scripts;
   and `docs/TEST-SUITES.md`. With the `docker` module, add `make test tier= suite=` to each mode's
   `Makefile`, running the scripts in that mode, and `make help` lists it. Never over a file that's
   there: when another runner exists, say what moving to Vitest changes and ask first.
4. **Tag what exists.** For each feature suite, pick one test per critical behavior as `@smoke` and each
   delivered feature's main criterion as `@critical` — a title change, never a body change.
5. **Prove it.** Run `test:smoke`, `test:critical`, `test`, and a feature suite run. For one test per tier,
   break its assertion, watch it fail, restore it.
6. **Fill the project's copies:** `.claude/rules/testing.md` § Tiers and feature suites (its commands and any
   departure, with why), `AGENTS.md` § Quick reference (the tier and feature suite commands), and
   `docs/getting-started/DEV-SETUP.md`.

## Mode: audit

Check the suite against the specification in the order its Conformance section gives. Report each
gap as the requirement's ID, what the project has, and the change; a recorded exception isn't a gap.
Change nothing without the developer's yes.

## Mode: tag

For a feature or a feature suite: list its tests, propose which are `@smoke` and which `@critical` (T1–T5),
and apply the title changes the developer approves. Never retag to move a failure.

## Mode: feature suites

Compare the folders under the test roots with `docs/TEST-SUITES.md` (U1): list the folders with no
feature suite and the feature suites with no folder, and propose the edit.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll tag everything `@smoke` so it always runs" | The smoke tier is seconds. A tier everything is in tells nobody anything, and the fast run stops being fast. Smoke is one test per critical behavior. |
| "The test fails on CI only, so I'll move it to regression" | Retagging hides a failure from the run that would catch it. Diagnose it; a flaky test is fixed or skipped with a reason and a tracker link. |
| "A `unit/` folder is simpler than one per feature" | Then no one can run billing's tests without the rest. The folder is the feature suite. |
| "I'll invent a feature suite name for this feature" | Feature suites are in `docs/TEST-SUITES.md`; a new one goes there first, or two names will mean one feature. |
| "Coverage is 90%, so the suite is done" | Coverage counts lines that ran, not behavior asserted. Done is every requirement held and each tier seen failing. |

## Verification

- [ ] The module check and the hub check ran before anything else
- [ ] The developer chose the feature suites, and `docs/TEST-SUITES.md` lists each with its folders
- [ ] `test:smoke`, `test:critical`, and `test` pass, and `test:smoke` takes seconds
- [ ] One test per tier was seen failing for its assertion before it was committed green
- [ ] No test was retagged, skipped, or loosened to get to green
- [ ] A feature suite run (`npm test -- tests/<suite>`) ran only that feature suite's tests
