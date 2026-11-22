---
name: e2e
description: Set up, audit, or extend this project's end-to-end tests to the specification this skill carries — Playwright in e2e/, make e2e and make smoke against the checkout's own stack, one @smoke test per critical flow, tests that own their data and never reach a real third party — and diagnose a failing or flaky one. Use when a project has no end-to-end suite, when a suite should meet the specification, when a feature adds a critical flow, or when an end-to-end test fails or flakes. A change's own tests come from /adf:write-tests.
argument-hint: "[set up | audit | smoke | diagnose <test>]"
---

> **Step 0 — which copy.** This is the packaged copy, from the `e2e` module, carried by `adf-dev` ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/e2e/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# End-to-end tests

End-to-end tests drive the app the way a person does — a browser, the pages, the server behind them
— against the checkout's own stack. They prove the flows nothing smaller can: that a reader can
subscribe, not just that the validator rejects `reader@`. They're the slowest tests, so there are
few of them: one smoke test per critical flow, and an end-to-end test where an acceptance criterion
needs the whole stack to show it.

This skill sets the suite up and keeps it to the specification. It doesn't write a change's tests:
those come first, from the spec, with `/adf:write-tests` and `/adf:implement`, and the project's
`.claude/rules/testing.md` § End-to-end tells them how an end-to-end test is written here.

## The specification

**`<this skill's base directory>/SPECIFICATION.md` is what an end-to-end suite must be** — the engine,
its layout in `e2e/`, how it runs (`make e2e`, `make smoke`, defined in each local mode), its boundaries
(data, third parties, sign-in), how tests are written, the smoke suite, and the test-first flow —
each requirement with an ID. The modes that write or check a suite against it read it — set up,
audit, and smoke (§ Modes); diagnose doesn't need it. It also says where each fact lives.

**There are no templates.** Write the project's suite to the specification, fitted to the project:
its flows, its sign-in, its local environment. For Playwright's own API, its documentation
(playwright.dev) is the reference. A suite is done when its runs prove it, not when its files look
right. Name the requirement's ID whenever you report a gap or propose a change.

## Safety (always)

- **The checkout's own stack only.** The suite runs against the stack `make up` starts here — or,
  for a red run on the base branch's code, a second local worktree's own (F1) — never a shared
  environment, a preview, staging, or production. Never point `E2E_BASE_URL` anywhere else.
- **No real third party.** No test sends anything a real person or account receives (B2). A flow
  that can't be kept local is named for the human check, not tested against the real service.
- **No secrets in the conversation.** Never read `.env`. Test accounts' credentials are variables
  `.env.example` names, and the developer fills them in.
- **No weakened tests.** Never add a sleep, a retry, or a `skip` to get to green, and never loosen an
  assertion. A failing test is diagnosed; a flaky one is fixed or marked `fixme` with the developer's
  yes.
- **The configured mode only.** Run the suite in the mode this checkout is configured for, the one
  `make help` names. Never set `DEV_MODE` or `SERVICES`, or edit `.env`, to try the other mode
  (`dev-env`'s M10): the developer runs it there when they work in that mode.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`).
   Unless its `modules:` list names `e2e`, say "the e2e module isn't installed in this project —
   `/adf:upgrade` offers it" and stop.

2. **Check where you are.** If `ops/agent/worktree.conf` (or `scripts/agent/worktree.conf`) exists
   and `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`, this is the main checkout,
   which takes no edits. Say so in a line, read nothing more, and run `/adf:dispatch` now with
   `chore/e2e` as the branch, without asking first: it moves this session to the task's worktree,
   where this command runs as the developer typed it.

3. **Read the facts, running nothing yet:**
   - any end-to-end suite already there: `e2e/`, a `playwright.config.*`, `cypress/` or
     `cypress.config.*`, a `tests/e2e/`;
   - the local environment: the stamp's `docker` module, the `Makefile` and `ops/`, `compose.yaml`,
     `.env.example`, and `AGENTS.md` § Quick reference;
   - `.claude/rules/testing.md`, the app's package manifest, and its README;
   - what the app does, for its critical flows: `specs/` (the delivered features), its routes or
     pages, and `AGENTS.md`;
   - when the argument names the mode, what § Modes lists for it.

4. **Name the mode** in one line — from the argument, or from the situation: no suite → set up; a
   suite that doesn't meet the specification → audit; a feature that created a critical flow →
   smoke; a test that fails or flakes → diagnose. Then follow it, as § Modes says.

## Modes

Set up, audit, and diagnose have their steps in a file beside this one. Read the mode's file — and
the specification where the table says so — with step 3's reads when the argument names the mode,
or as soon as step 4 names it, and follow it.

| Mode | What it does | Read |
|---|---|---|
| set up | Through `/adf:triage`: agrees on the critical flows, writes the suite and its commands and a smoke test per flow, runs it in the configured mode until it passes, and writes down what it verified | `<this skill's base directory>/set-up.md`, and the specification |
| audit | Checks a suite in the order the specification's § Conformance gives, and proposes the changes through `/adf:triage` | `<this skill's base directory>/audit.md`, and the specification |
| smoke | Adds a critical flow's smoke test | § Mode: smoke, below, and the specification |
| diagnose | `/adf:debug`'s order, applied to an end-to-end test, from what the failure kept | `<this skill's base directory>/diagnose.md` |

## Writing a smoke test

Set up and smoke write one smoke test per critical flow (K2), this way:

- **What it asserts:** each flow's happy path, in the words a person sees. Find elements by role
  and name (A1), and wait with assertions (A2). Expected values come from the spec or the page as
  a person reads it — never from the code.
- **When a test fails on a name:** read `error-context.md` beside its trace. It shows the page's
  roles and names as Playwright sees them.
- **Prove each test can fail (K5):** break its assertion, run it, see it fail for that reason,
  and restore it.

## Mode: smoke

A delivered feature that created a critical flow, or a change to the list (K4):

1. Agree on the flow with the developer, and add its row to `e2e/README.md`.
2. Write its smoke test as § Writing a smoke test says, proving it can fail.
3. `make smoke` passes. Commit with `test:`.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll add `waitForTimeout(2000)` so it stops flaking" | A sleep is too short on a slow run and wasted on a fast one. Wait for what a person sees: `await expect(...).toBeVisible()`. |
| "It passed on the second run, so it's fine" | A test that fails now and then is broken, and it hides a race in the app or the test. Find it. |
| "`.btn-primary` is the quickest way to find the button" | It breaks on a restyle and says nothing about what a person sees. `getByRole('button', { name: 'Subscribe' })` survives one and checks the name. |
| "Staging has real data, so I'll point the tests there" | The suite tests the checkout's own stack. Staging is shared, and tests there change what others see. |
| "I'll test every validation rule end to end" | Each one costs seconds a unit test does in milliseconds. Test the rule at the unit level, and show it once in the flow. |
| "The signup test can reuse the address the last run left" | The next run, another test, or a person changes it. Each test creates its own data with a unique value. |
| "I'll make the suite serial so the tests don't interfere" | Then they depend on order, and one failure cascades. Make them independent. |
| "`^1.63.0` keeps Playwright current" | The engine and its Docker image must be the same version. A minor bump in the lockfile breaks Docker mode. Pin it exactly, and upgrade both together. |
| "The smoke test is failing; I'll skip it to get the pull request out" | A failing smoke test means a critical flow is broken. Diagnose it. |
| "The new smoke test passed the first time, so it works" | A test you never saw fail may test nothing. Break its assertion once, and watch it fail. |

## Red flags (stop and reassess)

- You're in the main checkout of a hub
- `E2E_BASE_URL` names anything but the checkout's own stack
- A test is about to send an email, a payment, or a message through a real service
- You're adding a sleep, a retry, a `skip`, or a looser assertion to reach green
- `@playwright/test`'s version and the image's tag differ
- You're about to read `.env`

## Verification

- [ ] The module check and the hub check ran before anything else
- [ ] The suite meets the specification, or its gaps — each by requirement ID — went to the developer as a careful-lane change
- [ ] The developer chose the critical flows, and `e2e/README.md` lists each with its smoke test
- [ ] Each smoke test was seen failing for its assertion before it was committed green
- [ ] `make smoke` and `make e2e` pass in the configured mode, and the smoke suite takes about a minute
- [ ] No run switched modes: the other mode's tasks were read against R3 or R4, and reported as not run
- [ ] No test reaches a real third party or a shared environment, and no secret was read
- [ ] `.claude/rules/testing.md` § End-to-end and `AGENTS.md` § Quick reference name the commands

## Principles

- Few, and only where only the whole stack can show it: one smoke test per critical flow, and an end-to-end test where an acceptance criterion needs one.
- Red before green, for the right reason.
- Find elements the way a person does, and wait for what a person sees.
- Each test owns its data; the stack is the developer's own.
- Flaky is broken.
