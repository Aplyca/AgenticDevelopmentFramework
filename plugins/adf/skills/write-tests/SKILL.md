---
name: write-tests
description: Write tests from a spec folder's acceptance criteria and testable requirements, and watch them fail before any implementation (TDD red). Three modes — the test for one task inside the /adf:implement loop, contract-first acceptance tests committed ahead of the code, or standalone coverage for existing code and bugs. Use whenever tests come before code.
argument-hint: "[spec folder and task ID, 'acceptance' for contract-first, or an area to cover]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/write-tests/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Write Tests (TDD — red before green)

Tests are written from the spec, before the code that satisfies them, and they must fail first. A
test that never failed proves nothing: it may test something that already exists, or nothing at all.

## Modes

| Mode | When | Plan approval | Commit |
|---|---|---|---|
| **Task** | Inside `/adf:implement`, for the next task in `tasks.md` | Already approved — the task names its test | With the task's code, after green |
| **Acceptance (contract-first)** | `plan.md` asks for end-to-end tests encoding the ACs before implementation | Already approved in `plan.md` § Test strategy | `test:` — committed red, ahead of the code |
| **Standalone** | Covering existing untested code, reproducing a bug, or a test-only change | Present a test plan and wait (Phase 1 below) | `test:` (or with the fix, for a bug) |

## Phase 1: Plan (standalone mode — the other modes take their plan from `plan.md`)

1. **Read the source of truth.** For a feature: the spec — every filled section, not just Functional:
   - **Functional** — every AC and edge case
   - **Testing** — explicit asks (accessibility scans, visual regression, manual passes)
   - **Security, Accessibility, Performance, Privacy, Analytics, Localization** — every testable
     requirement (skip sections marked Not applicable or Standard applies)
   For a bug: the reproduction steps and the expected behavior.

2. **Read the test conventions** — `.claude/rules/testing.md` (framework, ports, mocking,
   organization, and § End-to-end for a test that needs the whole stack) — and the existing tests
   in the area. Don't duplicate; extend. With the `e2e` module, an end-to-end test goes in `e2e/`,
   uses its fixtures, and runs with `make e2e t=<file>`.

3. **Present the test plan** — requirement → test, grouped by source section:
   ```
   FROM Functional:
     AC1 "user sees a confirmation after a valid signup" → 'shows confirmation after valid email'
     Edge "empty list shows a message"                  → 'shows empty state when there are no topics'
   FROM Security:
     "10 requests/IP/minute, 429 + Retry-After"         → 'returns 429 with Retry-After when rate-limited'
   FROM Accessibility:
     "inline errors use role=alert"                      → 'announces the inline error with role=alert'
   ```
   Name the files to create or modify and the mocks needed. **Wait for approval.**

## Phase 2: Write and watch them fail (all modes)

4. **Write the tests** following the plan and the project's patterns: one file per feature area,
   names that read as behavior, Arrange → Act → Assert, every external service mocked, realistic but
   fake data.

5. **Run them — every new test must fail, for the right reason**: the assertion about the missing
   behavior, not an import error, a typo, or a broken fixture. Keep the failure output — it's the
   red half of the evidence in `tasks.md` § Gate results.
   A test that **passes** now is testing something that already exists (fine in a change request,
   if intended — say so) or testing the wrong thing (fix it).

   **An end-to-end test is red first too, and only on a local stack.** It never runs against a
   preview, staging, or production: a preview can share real backends, and the tests write data.
   Get its red one of two ways:
   - **Before the code** — the usual way. Write or update the test, run it on this checkout's stack
     (`make e2e t=<file>` with the `e2e` module), and watch it fail on the missing behavior.
   - **Against the base branch's code,** when the code came first — a test added after the change,
     or one the review asked for. Put the base branch in a second worktree with a stack of its own:
     with the parallel-agents module, `adf-worktree-new chore/<slug>-red --no-start`, which seeds its
     env file and its ports; otherwise `git worktree add --detach ../<repo>-red origin/<base>`, with
     `.env` copied in. Start it (`make up`), copy the test in, and run it there: it fails for the
     right reason. Commands there run outside this checkout, so Claude Code asks for them. Then run
     it green here, on the new code. Stop that stack (`make down`) and remove the worktree
     (`adf-worktree-rm`, or `git worktree remove`).

   Record both runs in `tasks.md` § Gate results: where the red ran, the assertion that failed, and
   the green.

6. **Hand off:**
   - **Task mode** — back to `/adf:implement` to write the code, reach green, and commit both together.
   - **Acceptance mode** — commit the red tests: `test: add <slug> acceptance tests (red — pending implementation)`. `/adf:implement` turns them green task by task.
   - **Standalone** — commit `test:`; for a bug, the fix follows in its own commit.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll write the tests after the code — it's faster" | Tests written after code confirm what was built, not what should be. They miss edge cases and encode implementation accidents. |
| "It failed with a module-not-found error — that's red" | Red means the behavior is missing, not that the test can't load. Fix the scaffolding until the assertion is what fails. |
| "The code's already done, so I'll check the end-to-end test red on the preview of the base branch" | The suite runs only against a local stack: a preview can share real backends, and the tests write data. Run it red on the base branch's code in a second local worktree, then green here. |
| "The code's already done, so this end-to-end test can't be red" | It can: run it on the base branch's code, in a second worktree with its own stack. A test you never saw fail may test nothing. |
| "This AC is too simple to test" | Simple ACs break too. If it's in the spec, it gets a test. |
| "I'll combine several ACs in one test" | Each AC needs its own test so a failure names the broken requirement. |
| "This service is reliable — no need to mock it" | Tests must not depend on external services. A flaky suite is worse than none. |
| "The test plan is obvious, skip approval" | In standalone mode the plan is the contract; skipping approval means missing coverage is found later. |

## Red flags (stop and reassess)

- A new test passes before any implementation exists.
- A single test needs more than three mocks — the design may have too many dependencies; flag it for the plan.
- You can't work out how to test an AC — the AC is probably ambiguous; take it back to the spec.
- Test names don't read as behavior.

## Verification

- [ ] Every AC and edge case in scope has at least one test
- [ ] Every testable requirement in the filled non-functional sections is covered
- [ ] Every explicit ask in the spec's Testing section is covered
- [ ] Every new test was run and failed for the right reason — the output is kept for the gate results
- [ ] All external services are mocked; test data is fake
- [ ] Test names read as behavior; organization follows the project's conventions

## Principles

- Tests come before the code they verify — and fail first.
- Test behavior, not implementation; assert on what users and callers observe.
- If an AC can't be tested, the AC needs rewriting.
- For change requests, test what changed; existing passing tests for unchanged behavior stay.
