# [PROJECT NAME] — Claude Code Instructions

<!-- Skeleton source: [SHA] ([YYYY-MM-DD]) — update on every framework upgrade. See docs/UPGRADING.md in AgenticDevelopmentFramework. -->

<!-- This file extends AGENTS.md with Claude Code-specific features. -->
<!-- AGENTS.md contains universal project context (read by all AI tools). -->
<!-- This file adds: path-scoped rules, specialized agents, workflow skills. -->

## Spec model

This project uses a **multi-perspective spec model** — each spec captures input from all relevant roles (business, functional, security, accessibility, testing, documentation, and more) in one document, with required sections enforced before approval. Full structure in `docs/SPEC-MODEL.md`. Template at `specs/_template.md`.

## Cost model

Default to Sonnet for skill invocations; use Haiku for `/commit`; escalate to Opus only for genuinely complex/novel work (see `docs/COST-MODEL.md` for the decision rules and per-skill recommendations). The default model is wired in `.claude/settings.json` (`"model": "claude-sonnet-5"`); change it there if your team's default differs. Specialized agents declare their model in their `agent.md` frontmatter — don't override casually. Keep `AGENTS.md`, `CLAUDE.md`, and rules stable to maximize prompt-cache hits (each edit busts the cache for every subsequent request).

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

**Performance tip:** Claude Code auto-loads `AGENTS.md`, `CLAUDE.md`, and the skills/agents index (frontmatter only) on every turn. Rule bodies in `.claude/rules/` load on demand, not automatically — but Cursor DOES auto-load `.cursor/rules/*.mdc` by glob, so deleting unused rule files there shrinks Cursor's per-turn prefill. Across all tools, the highest-leverage tokens to trim are in `AGENTS.md` and `CLAUDE.md` themselves — keep them lean and stable (each edit busts the prompt cache).

## Memory strategy

Knowledge has six layers in this project: `AGENTS.md` (identity), `CLAUDE.md` (this file — tool config), `.claude/rules/` (engineering standards), specs (per-feature), ADRs (significant decisions), and persistent memory (recurring gotchas, learned patterns, user preferences). See `docs/MEMORY-STRATEGY.md` for the decision tree on where a given fact belongs. Rule of thumb: if a fact would change more than once a quarter, it doesn't belong in `AGENTS.md` / `CLAUDE.md` / rules — it belongs in memory or a spec.

## MCP integration (optional)

For projects with many specs / ADRs / runbooks, an optional MCP server can expose them as queryable resources (e.g. `mcp://specs/newsletter-signup/security` returns just the Security section). See `docs/MCP-INTEGRATION.md` for when to set one up, what to expose, a reference TypeScript implementation, and how to wire it into Claude Code / Cursor / Antigravity. Not a hard dependency — the framework works without MCP.

## Evals (optional pattern)

This project has an empty `evals/` directory by design — add evals only if your team writes custom skills, rules, or spec patterns that need automated verification. See `evals/README.md` for the two-tier pattern (static structural checks + dynamic AI-invocation fixtures) and adoption guidance. Add evals only when a real regression surfaces; don't write speculative coverage.

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

## Specialized agents and workflow skills

Agents (`.claude/agents/`, invoke with `@`) and skills (`.claude/skills/`, invoke with `/`) appear in the auto-loaded index — type `@` or `/` to see the live list. Full catalogs (purpose, access scope, model tier, when to use each) are in `AGENTS-REFERENCE.md` and `SKILLS-REFERENCE.md` in the AI-Assisted Development Framework repository — those are framework-owned reference docs and aren't copied into your project. Agents are generic; they learn project specifics from `AGENTS.md`, this file, and `.claude/rules/` at runtime.

## When to use skills vs agents

- **Use skills** (`/name`) for sequential tasks in your current conversation — they run in the main context, which already has CLAUDE.md and rules loaded. More token-efficient.
- **Use agents** (`@name`) when you need parallel execution (e.g., run security review while continuing implementation), a second opinion in isolation, or specialized tool restrictions (read-only reviewers can't accidentally edit code).
- **Default to skills** for: review, implement, test, debug, refactor, commit.
- **Use agents** for: parallel reviews before a big merge, independent security audits, architecture reviews where isolation prevents bias.
