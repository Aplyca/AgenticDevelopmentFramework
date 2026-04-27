# AI-Assisted Development Onboarding

This guide helps developers adopt the spec-driven, test-driven, AI-assisted workflow used in this project.

## The methodology

We use three practices together:

1. **Spec-driven development (SDD)** — write business requirements before code
2. **Test-driven development (TDD)** — write tests from spec acceptance criteria
3. **AI-assisted development** — specialized AI agents handle specific tasks

Why all three? Each one prevents a different class of mistakes:
- **Specs** prevent building the wrong thing (scope creep, misunderstood requirements)
- **Tests** prevent breaking what already works (regressions)
- **AI agents** accelerate the work while maintaining standards

## The three workflows

### Workflow 1: Project Setup (one-time)

Run `/init-project` when starting a new project. This configures AI tools and creates technical documentation that serves as persistent context for AI agents:

1. Customize `CLAUDE.md` with project identity, stack, and critical rules
2. Customize `.claude/rules/` (files with `<!-- CUSTOMIZE -->` markers)
3. Write initial technical docs (architecture, security, infrastructure, glossary)
4. Commit all configuration and documentation

**Why documentation matters:** AI agents read `docs/ARCHITECTURE.md` before every design review, `docs/security/SECURITY.md` before every security audit, and `docs/GLOSSARY.md` when writing specs and user-facing text. Good initial docs = better AI output on every task.

### Workflow 2: Feature Development (new features, modifications, bug fixes)

This is the workflow for any planned change. New features and modifications to existing features follow the same process.

```
Phase 1: Spec            Phase 2: Test (TDD)          Phase 3: Implement          Phase 4: Ship
─────────────────        ────────────────────         ──────────────────          ──────────────
1. Check existing specs   6. Plan tests (AC → test)   11. Plan implementation     16. Commit code
2. Write/update spec      7. Approve test plan        12. Approve impl. plan      17. Verify
3. Architecture (opt.)    8. Write tests              13. Implement (pass tests)  18. Deploy
4. Get approval           9. Run tests (all fail)     14. Run tests (all pass)
5. Commit spec           10. Commit tests             15. Review
       ↑                        ↑                            ↑
  Spec commit = intent    Test commit = contract    Code commit = execution
  Plan: what to build     Plan: how to verify it    Plan: how to build it
```

**Two key patterns:**

**1. Commit specs and tests before implementing.** This creates three clean layers:
- The **spec commit** captures **intent** (what we decided to build)
- The **test commit** captures the **verification contract** (how we'll know it works — tests fail because no code exists yet)
- The **implementation commit** captures **execution** (code that makes the tests pass)
- The `git diff` of each commit tells the AI agent the **exact scope** — especially valuable for modifications where only some ACs changed

**2. Plan then execute.** Before writing tests or code, the AI presents a plan for your approval:
- **Test plan**: maps each AC to specific tests — you approve before tests are written
- **Implementation plan**: outlines which files change, what each change does, which tests it addresses — you approve before code is written
- This is compatible with plan-then-execute workflows in tools like Cursor and Antigravity

### Workflow 3: Hotfix (production-breaking bugs only)

For critical production issues that need immediate resolution:

1. Fix the issue — use `/debug` for root cause analysis
2. Write a regression test
3. Commit and deploy
4. Backfill the spec afterward if the fix changes behavior

Hotfixes skip the spec-first process because speed matters. Always backfill afterward.

## Week 1: Fundamentals

### Day 1: Setup and orientation (1 hour)

1. Install your AI coding tool (Claude Code, Cursor, Antigravity, VS Code + Copilot, etc.)
2. Read `AGENTS.md` — understand the project, stack, workflows, and critical rules (10 min)
3. **Read `docs/SPEC-MODEL.md`** — understand the multi-perspective spec model. This is the most important concept in this workflow; every feature spec uses it. (10 min)
4. Read the tool-specific config for your tool (see table below) (5 min)
5. Browse `.claude/agents/` — read 2-3 agent definitions to understand their roles (10 min)
6. Browse `.claude/skills/` — read 2-3 skill definitions to understand the workflow playbooks (10 min)
7. Browse `.claude/rules/` — read 2-3 rules to understand the engineering standards (10 min)
8. Read the development workflows above (10 min)

> **Why the spec model matters before everything else.** Specs in this project aren't just "what the business wants" — they capture input from every relevant role (security, accessibility, testing, deployment, etc.) in one document. The AI enforces required sections before a spec can be approved. If you skim the rest but skip `SPEC-MODEL.md`, you'll write specs that get rejected by the `/write-spec` skill. 10 minutes here saves an hour of confusion later.

**Tool-specific configuration:**

| Tool | Config read | Agents | Skills | Rules |
|---|---|---|---|---|
| **Claude Code** | `AGENTS.md` + `CLAUDE.md` | `.claude/agents/` (`@name`) | `.claude/skills/` (`/name`) | `.claude/rules/` (auto-loaded by path) |
| **Cursor** | `AGENTS.md` | Not supported natively — read agent files manually | Not supported natively — read skill files manually | `.cursor/rules/` (auto-loaded by glob) |
| **Antigravity** | `AGENTS.md` + `GEMINI.md` | `.agents/` directory | `.agents/skills/` (symlink to `.claude/skills/`) | Reference `.claude/rules/` in prompts |
| **VS Code + Copilot** | `AGENTS.md` | Not supported natively | Not supported natively | Not supported natively |

All tools read `AGENTS.md` automatically. The project's workflows, conventions, and critical rules are defined there — so every team member gets consistent AI behavior regardless of their tool choice.

### Day 2-3: First spec (2-3 hours)

1. Pick a small feature or improvement
2. Run: `/write-spec [describe your feature]`
3. Review the output — does it capture the business requirement clearly?
4. Iterate until the spec has clear acceptance criteria
5. Get the spec approved by a teammate
6. **Commit the spec**: `git add specs/your-spec.md && git commit -m "spec: add [feature] spec"`

> **Read a worked example first.** Before doing your own, walk through [docs/examples/newsletter-signup/](../docs/examples/newsletter-signup/) — a complete cycle (spec → tests → implement → review → commit) on a Next.js + Contentful + Vercel feature. ~15 minutes; saves hours of trial and error.

### Day 4-5: First tests and implementation (3-4 hours)

1. With your committed spec, run: `/write-tests [spec name]`
2. The agent presents a **test plan** (AC → test mapping) — review it and approve
3. After approval, the agent writes the tests
4. Run the tests — they should all fail (this is correct, no code exists yet)
5. Commit the tests: `git add e2e/ && git commit -m "test: add [feature] tests (red — pending implementation)"`
6. Now run: `/implement [spec name]`
7. The agent presents an **implementation plan** (files to change, what each change does) — review it and approve
8. After approval, the agent writes code until all tests pass
9. Run: `/review`
10. Address any findings, then run: `/commit`

## Week 2: The full workflow in practice

### Feature development cycle

```
 1. REQUIREMENT
    You or a stakeholder describes what's needed

 2. SPEC (/write-spec)
    AI drafts the spec. You review and approve.
    Key: spec has testable acceptance criteria.

 3. ARCHITECTURE REVIEW (@architect)
    For non-trivial features, get a design review.
    Key: data flow, component boundaries, API design.

 4. COMMIT THE SPEC (/commit)
    Commit the approved spec with a spec: prefix.
    This is the handoff between design and testing.

 5. PLAN TESTS (/write-tests)
    AI maps each AC to tests and presents the test plan.
    You review and approve before any tests are written.

 6. WRITE TESTS — TDD red phase
    AI writes tests following the approved plan.
    Run them — they should ALL FAIL (no code exists yet).

 7. COMMIT THE TESTS (/commit)
    Commit failing tests with test: prefix.
    This is the handoff between testing and implementation.

 8. PLAN IMPLEMENTATION (/implement)
    AI reads spec + test diffs, outlines which files to change.
    You review and approve before any code is written.

 9. IMPLEMENT — TDD green phase
    AI writes code following the approved plan.
    Runs tests until all pass.

10. REVIEW (/review)
    Multi-perspective review: quality, security, UX.
    Address findings.

11. COMMIT (/commit)
    Commit implementation with feat: or fix: prefix.
    One logical change per commit.
```

### Modifying an existing feature

Same workflow as above, but:
1. Update the existing spec (don't create a new one)
2. Commit the spec update — the diff shows exactly what changed
3. Write/update tests for the new or changed ACs only. Run them — new tests fail, existing tests still pass.
4. Commit the tests
5. Run `/implement` — the agent reads both diffs and only modifies code for changed acceptance criteria and their failing tests
6. Existing behavior (unchanged ACs and their passing tests) is preserved automatically

### When something breaks

```
1. Don't guess. Run: /debug [paste the error]
2. Read the diagnosis — root cause, not symptoms
3. Write a test that reproduces the bug
4. Fix the root cause
5. Verify the test passes
```

### When refactoring

```
1. Verify tests exist for the code you'll change
2. Run: /refactor [file or area]
3. Tests must pass after every change
4. Run: /review before committing
```

## Situational playbooks

Not every change is a brand-new feature. The patterns differ for these common situations — each has a one-page playbook:

- **[Modifying an existing feature](../docs/scenarios/modifying-existing-feature.md)** — update the spec, let the diff scope the work
- **[Hotfix](../docs/scenarios/hotfix.md)** — fast path for production-breaking bugs, with the spec backfilled afterward
- **[Refactor](../docs/scenarios/refactor.md)** — restructure without changing behavior, tests stay green throughout
- **[Debugging](../docs/scenarios/debugging.md)** — diagnose root cause before patching the symptom

## Common mistakes

### 1. "Vibe coding" — prompting without a spec
**Problem**: AI guesses your intention, adds features you didn't ask for, misses edge cases.
**Fix**: Always write a spec first, even for small changes. The spec is the contract.

### 2. Skipping the spec or test commit
**Problem**: Implementation agent doesn't know the precise scope, may over- or under-build. Without committed tests, there's no objective "done" criteria.
**Fix**: Always commit the spec, then write and commit failing tests, before running `/implement`. The spec diff defines scope, the test diff defines "done".

### 3. Skipping code review
**Problem**: AI-generated code may look correct but violate project conventions or introduce subtle bugs.
**Fix**: Run `/review` before every commit. It takes 30 seconds and catches real issues.

### 4. Testing only the happy path
**Problem**: Edge cases break in production.
**Fix**: Specs include edge cases. Tests cover them. If your spec has no edge cases section, it's incomplete.

### 5. Accepting AI output without reading it
**Problem**: AI is fast but not infallible. It can introduce security issues, wrong assumptions, or unnecessary complexity.
**Fix**: Read every line of AI-generated code. If you don't understand it, ask the AI to explain it.

### 6. Over-engineering with AI
**Problem**: AI will happily build abstractions, config systems, and extension points you never asked for.
**Fix**: The spec defines the scope. If it's not in the spec, don't build it. Three simple lines > one clever abstraction.

## Quick reference

### Skills (workflow playbooks)

| When you need to... | Run |
|---|---|
| Set up a new project | `/init-project` |
| See the full workflow | `/spec-workflow` |
| Write a feature spec | `/write-spec [feature]` |
| Implement from a spec | `/implement [spec name]` |
| Write tests | `/write-tests [spec name]` |
| Review before commit | `/review` |
| Investigate a bug | `/debug [error message]` |
| Refactor safely | `/refactor [file or area]` |
| Commit changes | `/commit` |
| Deep analysis of a decision | `/evaluate [question or proposal]` |

### Agents (specialized roles)

| When you need to... | Use |
|---|---|
| Draft a spec collaboratively | `@spec-writer` |
| Deep code quality analysis | `@code-reviewer` |
| Security audit | `@security-reviewer` |
| Write or fix tests | `@test-runner` |
| Architecture review | `@architect` |
| Root cause analysis | `@debugger` |
| UI/UX validation | `@ux-reviewer` |

### Skills vs agents

- **Skills** (`/name`) are step-by-step workflows. They guide AI through a process. Use them for standard tasks.
- **Agents** (`@name`) are specialized personas with restricted tools. They bring deep expertise. Use them when you need focused analysis or when a skill references them.
- **Default to skills** for sequential work (implement, test, review, commit). Use agents for parallel execution or independent second opinions.

### Commit message prefixes

| Prefix | When to use |
|---|---|
| `spec:` | Spec changes (new or updated) — committed before tests and implementation |
| `test:` | Tests from spec ACs — committed before implementation (should fail until code exists) |
| `docs:` | Documentation changes (architecture, security, ADRs) |
| `feat:` | New feature implementation (makes the tests pass) |
| `fix:` | Bug fix implementation |
| `refactor:` | Code restructuring without behavior change |

## How to interact with AI effectively

### Match your prompt to the task

| Situation | What to say | Why |
|---|---|---|
| Simple fix | "Fix the typo in line 42 of users.ts" | No analysis needed, just execute |
| Clear implementation | "/implement user-login spec" | Spec defines the work, AI follows it |
| Design decision | "/evaluate should we use Redis or in-memory caching?" | Need options, trade-offs, and recommendation |
| Uncertainty | "I'm not sure how to approach this, what do you think?" | Let AI propose approaches for you to choose from |
| Deep research | "Deeply research how teams handle auth in Next.js" | Thorough investigation before deciding |

### Prompting principles

**Be specific, not vague:**
- Good: `@security-reviewer review app/api/users/route.ts for injection vulnerabilities`
- Bad: "check my code"

**Give context, not assumptions:**
- Good: "this endpoint handles user registration, validates email format, and creates a DB record"
- Bad: "review this endpoint"

**State what you want, not just the topic:**
- Good: "list findings with severity levels and suggested fixes"
- Bad: "tell me if it's ok"

**Reference the spec when applicable:**
- Good: "verify this matches spec AC #3: user sees error when email is empty"
- Bad: "does this look right?"

**Challenge AI, don't just accept:**
- Good: "you recommended Option A, but what about [concern]? does that change your recommendation?"
- Bad: accepting the first answer without questioning

**Ask AI to challenge you:**
- Good: "I'm planning to do X — what am I missing? what could go wrong?"
- Bad: "implement X" (without inviting critique)

### The collaboration mindset

AI is a capable colleague, not an oracle and not a typist:

- **Don't blindly accept** — read every line of AI output. If you don't understand it, ask for an explanation.
- **Don't blindly reject** — if AI flags a concern, consider it seriously even if it seems inconvenient.
- **Push back** — if AI's recommendation doesn't feel right, say why. The conversation often leads to a better answer than either of you had alone.
- **Provide feedback** — if AI does something well, say so. If it does something poorly, explain what you wanted instead. This improves future interactions.
- **Stay in control** — AI proposes, you decide. Never let AI make irreversible decisions without your explicit approval.
