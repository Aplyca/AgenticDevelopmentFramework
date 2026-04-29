# [PROJECT NAME] — Claude Code Instructions

<!-- Skeleton source: [SHA] ([YYYY-MM-DD]) — update on every framework upgrade. See docs/UPGRADING.md in ai-dev-starter-kit. -->

<!-- This file extends AGENTS.md with Claude Code-specific features. -->
<!-- AGENTS.md contains universal project context (read by all AI tools). -->
<!-- This file adds: path-scoped rules, specialized agents, workflow skills. -->

## Spec model

This project uses a **multi-perspective spec model** — each spec captures input from all relevant roles (business, functional, security, accessibility, testing, documentation, and more) in one document, with required sections enforced before approval. Full structure in `docs/SPEC-MODEL.md`. Template at `specs/_template.md`.

## Cost model

Default to Sonnet for skill invocations; use Haiku for `/commit`; escalate to Opus only for genuinely complex/novel work (see `docs/COST-MODEL.md` for the decision rules and per-skill recommendations). The default model is wired in `.claude/settings.json` (`"model": "claude-sonnet-4-6"`); change it there if your team's default differs. Specialized agents declare their model in their `agent.md` frontmatter — don't override casually. Keep `AGENTS.md`, `CLAUDE.md`, and rules stable to maximize prompt-cache hits (each edit busts the cache for every subsequent request).

## Lightweight mode — when to skip the full workflow

The spec → tests → docs → implement workflow exists for **features and behavior changes**. It is overkill for small, low-risk work and will feel unnecessarily slow if applied to everything. Match the ceremony to the change:

| Change type | Workflow |
|---|---|
| New feature, behavior change, anything user-facing | Full workflow (`/write-spec` → `/write-tests` → `/write-docs` → `/implement`) |
| Bug fix with a clear root cause | `/debug` → fix → add a regression test → `/commit`. Skip spec/docs unless the fix changes documented behavior. |
| Typo, copy tweak, dependency bump (patch), formatting | Edit → `/commit`. No workflow. |
| Refactor with no behavior change | `/refactor` → ensure tests still pass → `/commit`. No spec. |
| Internal tooling (scripts, CI tweaks, dev-only config) | Edit → `/commit`. No workflow. |
| Spike / exploration / throwaway code | No workflow. Delete or promote afterward; if promoted, then write the spec. |

**Heuristic:** if the change wouldn't appear in a release note, it doesn't need a spec. If a teammate could merge the diff without reading any new docs, it doesn't need `/write-docs`.

**Performance tip:** the framework auto-loads `AGENTS.md`, `CLAUDE.md`, all of `.claude/rules/`, and the skills index on every turn. If a rule file in the table below doesn't apply to your project (e.g. `ui-ux.md` on a backend service, `deployment.md` on a library), delete it — fewer tokens in the prefill means faster responses and better cache hit rates.

## Memory strategy

Knowledge has six layers in this project: `AGENTS.md` (identity), `CLAUDE.md` (this file — tool config), `.claude/rules/` (engineering standards), specs (per-feature), ADRs (significant decisions), and persistent memory (recurring gotchas, learned patterns, user preferences). See `docs/MEMORY-STRATEGY.md` for the decision tree on where a given fact belongs. Rule of thumb: if a fact would change more than once a quarter, it doesn't belong in `AGENTS.md` / `CLAUDE.md` / rules — it belongs in memory or a spec.

## MCP integration (optional)

For projects with many specs / ADRs / runbooks, an optional MCP server can expose them as queryable resources (e.g. `mcp://specs/newsletter-signup/security` returns just the Security section). See `docs/MCP-INTEGRATION.md` for when to set one up, what to expose, a reference TypeScript implementation, and how to wire it into Claude Code / Cursor / Antigravity. Not a hard dependency — the framework works without MCP.

## Evals (optional pattern)

This project has an empty `evals/` directory by design. **Evals test the framework that produced this skeleton, not your project.** If your team writes custom skills / rules / spec patterns and wants automated checks against them, the framework's eval pattern transfers — see `evals/README.md` in this directory for guidance, then adopt structural checks (bash + grep) and dynamic fixtures (AI invocation) as needed. Add evals only when real regressions surface; don't write speculative coverage.

## Engineering standards (path-scoped)

Standards are in `.claude/rules/` and auto-load when you touch matching file paths:

| Rule file | Scope |
|---|---|
| `code-quality.md` | All source code |
| `testing.md` | Test files |
| `security.md` | All source code |
| `git-workflow.md` | All files |
| `architecture.md` | App structure (customize paths) |
| `ui-ux.md` | UI components and styles |
| `deployment.md` | Infrastructure files |
| `performance.md` | Components and dependencies |
| `observability.md` | API and server code |

## Specialized agents

Defined in `.claude/agents/`. Invoke with `@agent-name`. All agents are generic — they learn project specifics from AGENTS.md, this file, and `.claude/rules/`.

| Agent | Purpose | Access |
|---|---|---|
| `@spec-writer` | Drafts specs from business requirements | Read + Write `specs/` |
| `@code-reviewer` | Reviews quality, conventions, patterns | Read-only |
| `@security-reviewer` | Audits for vulnerabilities and credential exposure | Read-only |
| `@test-runner` | Writes and runs tests from spec ACs | Full edit + Bash |
| `@architect` | Reviews design decisions and data flow | Read-only |
| `@debugger` | Root cause analysis for errors and failures | Read + Bash (no edit) |
| `@ux-reviewer` | Reviews UI against specs and UX standards | Read-only |

## Workflow skills

Defined in `.claude/skills/`. Invoke with `/skill-name`. These are step-by-step playbooks for common tasks.

| Skill | Purpose |
|---|---|
| `/spec-workflow` | Complete workflow reference (setup, feature dev, hotfix) |
| `/init-project` | First-time project setup |
| `/write-spec` | Draft a feature specification using the multi-perspective spec model (see `docs/SPEC-MODEL.md`). Enforces required sections before approval. |
| `/write-tests` | Write tests from spec acceptance criteria AND testable requirements in security / accessibility / performance sections |
| `/write-docs` | Docs-first: plan and write pre-implementable user-facing docs (admin guides, API contracts, end-user copy defaults) BEFORE implementation. Skips cleanly when the spec has no pre-implementable docs. |
| `/implement` | Build from an approved spec (reads spec git diff for scope, addresses every filled section: functional, security, a11y, perf, etc.; reads committed docs to drive thinking and reconciles them deliberately when implementation diverges) |
| `/spec-drift` | Read-only audit: detect divergences between a committed spec and current code/tests/docs. Reports findings categorized by severity; does not fix. Run periodically (monthly per spec area) to catch silent decay. |
| `/orchestrate` | Dispatch multiple specialized agents in parallel for thorough reviews or investigations. Built-in task types: `review`, `investigate`, `pre-commit`, `custom`. Costs more than `/review`; use for high-stakes diffs or multi-angle exploration. Does NOT auto-progress through workflow phases. |
| `/review` | Multi-perspective code review |
| `/debug` | Systematic root cause analysis |
| `/refactor` | Safe code restructuring |
| `/commit` | Review and commit changes |
| `/evaluate` | Deep analysis with options, pros/cons, risks |

## When to use skills vs agents

- **Use skills** (`/name`) for sequential tasks in your current conversation — they run in the main context, which already has CLAUDE.md and rules loaded. More token-efficient.
- **Use agents** (`@name`) when you need parallel execution (e.g., run security review while continuing implementation), a second opinion in isolation, or specialized tool restrictions (read-only reviewers can't accidentally edit code).
- **Default to skills** for: review, implement, test, debug, refactor, commit.
- **Use agents** for: parallel reviews before a big merge, independent security audits, architecture reviews where isolation prevents bias.
