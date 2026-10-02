---
name: write-tests
description: Write tests from a spec folder's acceptance criteria and testable requirements, and watch them fail before any implementation (TDD red). Three modes — the test for one task inside the /aplyca-adf:implement loop, contract-first acceptance tests committed ahead of the code, or standalone coverage for existing code and bugs. Use whenever tests come before code.
argument-hint: "[spec folder and task ID, 'acceptance' for contract-first, or an area to cover]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/write-tests/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Write Tests (TDD — red before green)

Tests are written from the spec, before the code that satisfies them, and they must fail first. A
test that never failed proves nothing: it may test something that already exists, or nothing at all.

## Modes

| Mode | When | Plan approval | Commit |
|---|---|---|---|
| **Task** | Inside `/aplyca-adf:implement`, for the next task in `tasks.md` | Already approved — the task names its test | With the task's code, after green |
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
   organization) — and the existing tests in the area. Don't duplicate; extend.

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

6. **Hand off:**
   - **Task mode** — back to `/aplyca-adf:implement` to write the code, reach green, and commit both together.
   - **Acceptance mode** — commit the red tests: `test: add <slug> acceptance tests (red — pending implementation)`. `/aplyca-adf:implement` turns them green task by task.
   - **Standalone** — commit `test:`; for a bug, the fix follows in its own commit.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll write the tests after the code — it's faster" | Tests written after code confirm what was built, not what should be. They miss edge cases and encode implementation accidents. |
| "It failed with a module-not-found error — that's red" | Red means the behavior is missing, not that the test can't load. Fix the scaffolding until the assertion is what fails. |
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
