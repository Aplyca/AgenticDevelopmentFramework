# AI-Assisted Development Onboarding

This guide helps developers adopt the **multi-perspective spec-driven, test-driven, docs-first AI-assisted** workflow used in this project.

## The methodology

We use four reinforcing practices:

1. **Multi-perspective spec-driven development (SDD)** — write the spec across all relevant role perspectives (business, functional, security, accessibility, privacy, design, performance, testing, documentation, deployment) before code, with required sections enforced by the AI before approval
2. **Test-driven development (TDD)** — write tests from spec acceptance criteria
3. **Docs-first delivery (DDD)** — write user-facing docs (admin guides, API contracts, end-user copy) from the spec and tests, before code, to drive implementation thinking. Update docs deliberately when implementation reveals reality differs — they're living artifacts, not frozen contracts.
4. **AI-assisted development** — specialized AI agents handle specific tasks under all three disciplines

Why all four? Each one prevents a different class of mistakes:
- **Specs** prevent building the wrong thing (scope creep, misunderstood requirements, forgotten role perspectives)
- **Tests** prevent breaking what already works (regressions)
- **Docs** prevent shipping features nobody can use or operate (and force the team to articulate behavior cleanly enough that admins/integrators can act on it)
- **AI agents** accelerate the work while maintaining the standards above

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
Phase 1: Spec        Phase 2: Test       Phase 3: Docs        Phase 4: Implement     Phase 5: Ship
─────────────        ────────────        ─────────────        ──────────────────     ─────────────
1. Check specs        6. Plan tests       11. Plan docs        16. Plan impl.         21. Commit code
2. Write/update       7. Approve plan         (skip if none)   17. Approve plan       22. Verify
3. Architecture (o)   8. Write tests      12. Approve plan     18. Implement          23. Backfill
4. Get approval       9. Run (all fail)   13. Write docs       19. Tests pass             post-impl docs
5. Commit spec       10. Commit tests     14. Validate vs      20. Verify vs docs     24. Deploy
                                              spec + tests         + Review
                                          15. Commit docs
       ↑                  ↑                       ↑                    ↑
  Spec = intent      Test = verification    Docs = user-facing    Code = execution
  Plan: what          Plan: how to verify   contract              Plan: how to build
                                            Plan: what users see
```

**Three key patterns:**

**1. Commit specs, tests, AND docs before implementing.** This creates four clean layers:
- The **spec commit** captures **intent** (what we decided to build, across all role perspectives)
- The **test commit** captures the **verification contract** (how we'll know it works — tests fail because no code exists yet)
- The **docs commit** captures the **initial design intent for usage** (admins, API consumers, integrators see the agreed behavior before code starts; docs evolve as implementation surfaces new reality)
- The **implementation commit** captures **execution** (code that makes the tests pass; doc revisions surfaced during implementation either land in a preceding `docs:` commit or are folded in and called out in the `feat:` commit body)
- The `git diff` of each commit tells the AI agent the **exact scope** — especially valuable for modifications where only some requirements changed

**2. Docs-first is conditional.** The docs phase only fires when the spec lists pre-implementable docs (admin guides, API contracts, end-user copy defaults, SDK READMEs). For features with only post-implementable docs (JSDoc, runbooks needing real data) or no user-facing docs, `/write-docs` skips cleanly with a note and the workflow proceeds to `/implement`.

**3. Plan then execute.** Before writing tests, docs, or code, the AI presents a plan for your approval:
- **Test plan**: maps each AC and testable requirement to specific tests
- **Doc plan**: maps each pre-implementable doc entry to a file + audience
- **Implementation plan**: outlines which files change, what each change does, which tests + docs it addresses
- This is compatible with plan-then-execute workflows in tools like Cursor and Antigravity

### Workflow 3: Hotfix (production-breaking bugs only)

For critical production issues that need immediate resolution:

1. Fix the issue — use `/debug` for root cause analysis
2. Write a regression test
3. Commit and deploy
4. Backfill the spec AND any user-facing docs afterward if the fix changes behavior

Hotfixes skip the spec-first and docs-first process because speed matters. Always backfill afterward — undocumented behavior changes erode trust in the spec and docs.

## Week 1: Fundamentals

### Day 1: Setup and orientation (1 hour)

1. Install your AI coding tool (Claude Code, Cursor, Antigravity, VS Code + Copilot, etc.)
2. Read `AGENTS.md` — understand the project, stack, workflows, and critical rules (10 min)
3. **Read `docs/SPEC-MODEL.md`** — understand the multi-perspective spec model. This is the most important concept in this workflow; every feature spec uses it. (10 min)
4. **Read `docs/COST-MODEL.md`** — model tiering and prompt-cache discipline. Most teams overspend by 3-5× by defaulting everything to the most capable model and editing CLAUDE.md continuously. 5 min here saves real money. (5 min)
5. **Read `docs/MEMORY-STRATEGY.md`** — where a given fact belongs (AGENTS.md vs rules vs memory vs spec vs ADR). Skipping this means recurring gotchas get re-derived every session, AGENTS.md bloats with feature-specific noise, and the prompt cache stays cold. (5 min)
6. Read the tool-specific config for your tool (see table below) (5 min)
7. Browse `.claude/agents/` — read 2-3 agent definitions to understand their roles (10 min)
8. Browse `.claude/skills/` — read 2-3 skill definitions to understand the workflow playbooks (10 min)
9. Browse `.claude/rules/` — read 2-3 rules to understand the engineering standards (10 min)
10. Read the development workflows above (10 min)
11. Optional — `docs/MCP-INTEGRATION.md` if your project will run an MCP server for cross-tool spec queries (skip otherwise; not a hard dependency)

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

> **Read a worked example first.** Before doing your own, walk through [docs/examples/newsletter-signup/](../docs/examples/newsletter-signup/) — a complete cycle (spec → tests → docs → implement → review → commit) on a Next.js + Contentful + Vercel feature. ~15 minutes; saves hours of trial and error.

### Day 4-5: First tests, docs, and implementation (3-4 hours)

1. With your committed spec, run: `/write-tests [spec name]`
2. The agent presents a **test plan** (AC → test mapping, plus testable requirements from Security/A11y/Perf) — review it and approve
3. After approval, the agent writes the tests
4. Run the tests — they should all fail (this is correct, no code exists yet)
5. Commit the tests: `git add e2e/ && git commit -m "test: add [feature] tests (red — pending implementation)"`
6. Run: `/write-docs [spec name]`
7. **If the spec has pre-implementable docs**: the agent presents a **doc plan** (which doc files, audience, length). Review and approve. The agent writes the docs. Commit: `git commit -m "docs: add [feature] docs"`
8. **If the spec has no pre-implementable docs**: the agent skips cleanly with a note. Proceed.
9. Now run: `/implement [spec name]`
10. The agent presents an **implementation plan** (files to change, what each change does, which tests + docs claims each addresses) — review and approve
11. After approval, the agent writes code until all tests pass; if the chosen approach diverged from doc claims, the agent flags doc updates and you decide whether to commit them separately as `docs:` or fold into the `feat:` commit
12. Run: `/review`
13. Address any findings, then run: `/commit`

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
    This is the handoff between testing and docs.

 8. PLAN DOCS (/write-docs)
    AI reads the spec's Documentation Pre-implementable section + tests
    and presents a doc plan (which doc files, audience, length).
    Skips cleanly if no pre-implementable docs in the spec.
    You review and approve before any docs are written.

 9. WRITE DOCS — docs-first phase
    AI writes user-facing docs (admin guides, API contracts,
    end-user copy defaults). Sources every claim from spec + tests.

10. COMMIT THE DOCS (/commit)
    Commit docs with docs: prefix.
    This is the handoff between docs and implementation.

11. PLAN IMPLEMENTATION (/implement)
    AI reads spec + test + docs diffs, outlines which files to change
    and which doc claims each change satisfies.
    You review and approve before any code is written.

12. IMPLEMENT — TDD green phase + reconcile docs
    AI writes code following the approved plan.
    Runs tests until all pass.
    Reconciles docs with reality: small fixes folded into the feat:
    commit (called out in the body), meaningful revisions land as a
    separate docs: commit before the feat: commit.
    This is normal — most features need at least minor doc updates here.

13. REVIEW (/review)
    Multi-perspective review: quality, security, UX, doc accuracy.
    Address findings.

14. COMMIT (/commit)
    Commit implementation with feat: or fix: prefix.
    One logical change per commit.

15. (optional) BACKFILL POST-IMPLEMENTABLE DOCS
    JSDoc, runbooks with real metrics, troubleshooting from real
    failure modes — written after code, in a follow-up docs: commit.
```

### Modifying an existing feature

Same workflow as above, but scoped by diffs:
1. Update the existing spec (don't create a new one)
2. Commit the spec update — the diff shows exactly what changed
3. Write/update tests for the new or changed requirements only. Run them — new tests fail, existing tests still pass.
4. Commit the tests
5. Run `/write-docs` — the agent updates user-facing docs (admin guides, etc.) for the changed behavior. Skips cleanly if the spec update didn't touch the Documentation section.
6. Commit the docs (if any were written)
7. Run `/implement` — the agent reads all three diffs (spec, tests, docs) and only modifies code for changed requirements
8. Existing behavior (unchanged ACs, passing tests, untouched docs) is preserved automatically

See [docs/scenarios/modifying-existing-feature.md](../docs/scenarios/modifying-existing-feature.md) for the full playbook with a concrete example.

### When something breaks

```
1. Don't guess. Run: /debug [paste the error]
2. Read the diagnosis — root cause, not symptoms
3. Write a test that reproduces the bug
4. Fix the root cause
5. Verify the test passes
6. If the fix changes documented behavior, backfill the spec and any
   affected user-facing docs (admin guides, API contracts, copy defaults).
```

### When refactoring

```
1. Verify tests exist for the code you'll change
2. Run: /refactor [file or area]
3. Tests must pass after every change
4. Run: /review before committing
```

## How the framework verifies itself

The AI-Assisted Development Framework that produced this project skeleton has its own eval suite — structural checks of every skill, agent, rule, and the spec template, plus dynamic AI-invocation fixtures. It currently passes 48/48 static checks and is run in the framework's CI on every change. **This is why you can trust that `/write-spec` still enforces required sections, `/write-tests` still reads from all spec sections, and `/implement` still refuses to run without committed docs** — the framework eats its own dogfood.

What this means for your project:

- Your project does NOT have the framework's eval suite copied in. Adopting projects don't inherit fixtures (see `evals/README.md` in your project root for why).
- Your project's `.claude/` rules, skills, and agents are guaranteed to behave per the framework's contract because the framework itself is eval-tested.
- If your team adds custom skills, custom rules, or project-specific spec patterns and wants automated checks against them, you can adopt the eval pattern. The framework's `evals/STRATEGY.md` documents how — start with static structural checks (bash + grep), add dynamic fixtures only when real regressions surface.

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

### 2. Skipping the spec, test, or docs commit
**Problem**: Implementation agent doesn't know the precise scope, may over- or under-build. Without committed tests, there's no objective "done" criteria. Without committed pre-implementable docs (when the spec lists them), the implementation has no user-facing contract to honor and the docs end up either skipped entirely or written too late.
**Fix**: Always commit in order — spec, then failing tests, then docs (or skip cleanly), THEN run `/implement`. The spec diff defines scope, the test diff defines "done", the docs diff defines what users were promised.

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
| Write tests (TDD red) | `/write-tests [spec name]` |
| Write user-facing docs (DDD) | `/write-docs [spec name]` |
| Implement from a spec | `/implement [spec name]` |
| Audit a spec for drift vs current code | `/spec-drift [spec name]` |
| Review before commit (small diffs) | `/review` |
| Thorough multi-agent review (high-stakes diffs) | `/orchestrate review` |
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
| `spec:` | Spec changes — committed before tests, docs, and implementation |
| `test:` | Tests from spec ACs — committed before docs and implementation (should fail until code exists) |
| `docs:` | Pre-implementable user-facing docs — committed before implementation (admin guides, API contracts, end-user copy). Also used for post-implementable backfill (JSDoc, runbooks) and standalone doc updates (architecture, security, ADRs) |
| `feat:` | New feature implementation (makes the tests pass; small doc fixes can fold in, called out in the message; meaningful doc revisions land in a separate `docs:` commit before the `feat:`) |
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
