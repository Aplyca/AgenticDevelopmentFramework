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
Phase 1: Spec                    Phase 2: Implement              Phase 3: Ship
─────────────────                ──────────────────              ──────────────
1. Check existing specs          6. Read spec diff (git diff)    10. Commit code
2. Write/update spec             7. Implement changes            11. Verify
3. Architecture review (opt.)    8. Write tests                  12. Deploy
4. Get approval                  9. Review
5. Commit spec  ─────────────────────────────────────────────
                  ↑ This commit is the handoff point.
                  The implementation agent reads its diff
                  to know exactly what to build.
```

**The key pattern: commit the spec before implementing.** This creates a clean separation:
- The spec commit captures **intent** (what we decided to build)
- The implementation commit captures **execution** (how we built it)
- The `git diff` of the spec commit tells the AI agent the **exact scope** — especially valuable for modifications where only some acceptance criteria changed

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
3. Read the tool-specific config for your tool (see table below) (5 min)
4. Browse `.claude/agents/` — read 2-3 agent definitions to understand their roles (10 min)
5. Browse `.claude/skills/` — read 2-3 skill definitions to understand the workflow playbooks (10 min)
6. Browse `.claude/rules/` — read 2-3 rules to understand the engineering standards (10 min)
7. Read the development workflows above (10 min)

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

### Day 4-5: First implementation (3-4 hours)

1. With your committed spec, run: `/implement [spec name]`
2. Notice how the agent reads the spec diff to scope the work
3. Run: `/write-tests [spec name]`
4. Review the tests — do they cover each acceptance criterion?
5. Run: `/review`
6. Address any findings, then run: `/commit`

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
   This is the handoff between design and implementation.

5. IMPLEMENT (/implement)
   Agent reads git diff of the spec commit to know exact scope.
   Builds only what the spec says — no more, no less.

6. TESTS (/write-tests)
   AI writes tests from the spec's acceptance criteria.
   Verify all tests pass.

7. REVIEW (/review)
   Multi-perspective review: quality, security, UX.
   Address findings.

8. COMMIT (/commit)
   Commit implementation with feat: or fix: prefix.
   One logical change per commit.
```

### Modifying an existing feature

Same workflow as above, but:
1. Update the existing spec (don't create a new one)
2. Commit the spec update — the diff shows exactly what changed
3. Run `/implement` — the agent reads the diff and only modifies code for changed acceptance criteria
4. Existing behavior (unchanged ACs) is preserved automatically

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

## Common mistakes

### 1. "Vibe coding" — prompting without a spec
**Problem**: AI guesses your intention, adds features you didn't ask for, misses edge cases.
**Fix**: Always write a spec first, even for small changes. The spec is the contract.

### 2. Skipping the spec commit
**Problem**: Implementation agent doesn't know the precise scope, may over- or under-build.
**Fix**: Always commit the spec before running `/implement`. The git diff is the scope contract.

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
| `spec:` | Spec changes (new or updated) — committed before implementation |
| `docs:` | Documentation changes (architecture, security, ADRs) |
| `feat:` | New feature implementation |
| `fix:` | Bug fix implementation |
| `refactor:` | Code restructuring without behavior change |
| `test:` | Test additions or updates |

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
