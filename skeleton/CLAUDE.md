<!-- Skeleton source: [SHA] ([YYYY-MM-DD]) · modules: [none] — update on every framework upgrade. See docs/UPGRADING.md in AgenticDevelopmentFramework. -->
@AGENTS.md

# [PROJECT NAME] — Claude Code

<!-- The import above loads AGENTS.md (the instructions every AI tool shares) first. When a CLAUDE.md exists, Claude Code reads CLAUDE.md instead of AGENTS.md — so never remove the import. This file only adds what is specific to Claude Code. HTML comments like this one are stripped before loading and cost no context. -->

## Skills, agents, and workflows

- **Skills** (`.claude/skills/`, invoke with `/`) — the workflow playbooks: `/triage`, `/write-spec`, `/write-plan`, `/write-docs`, `/implement`, `/review`, `/commit`, `/open-pr`, and more. They run in this conversation, which already has the rules loaded — the cheapest option.
- **Agents** (`.claude/agents/`, invoke with `@`) — isolated specialists for an independent second opinion, restricted tools (reviewers can't edit), or work that runs alongside yours. `@spec-analyzer` checks a spec folder adversarially before the approval gate.
- **Workflows** (`.claude/workflows/`, invoke with `/deep-…`) — deterministic multi-agent fan-outs with adversarial verification: `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep`. Several times the cost of the skill they extend — use them for high-stakes changes and broad sweeps.

| Situation | Use |
|---|---|
| Sequential work in this conversation | Skill |
| Independent second opinion, restricted tools, or parallel to your own work | Agent |
| Broad fan-out with verification — a large diff, every spec, every instruction file | Workflow |

Full catalogs (purpose, tools, model tier) are `SKILLS-REFERENCE.md` and `AGENTS-REFERENCE.md` in the framework repository. Agents and skills are generic: they learn this project from `AGENTS.md`, this file, and `.claude/rules/`.

## Guardrails enforced by configuration

Instructions are context, not enforcement. These hold regardless of what the model decides:

| Guardrail | Enforced by |
|---|---|
| Outward actions — `git push`, PR create / ready / merge / comment / review, releases, issue writes — need your confirmation | `permissions.ask` in `.claude/settings.json` |
| Secret env files (`.env`, `.env.local`, `.env.*.local`) are never read into context — extend the list for your other secret files | `permissions.deny` in `.claude/settings.json` |
| No `--no-verify`; no commits or pushes on protected branches; no force-push to them | `.claude/hooks/guard-git.sh` (PreToolUse) |
| Generated files and append-only history are not hand-edited | `.claude/hooks/protect-paths.sh` (PreToolUse) |
| Environment variables read in code are declared in the env template (when the repository has one) | `.claude/hooks/check-env-declared.sh` (PostToolUse) |
| Each session starts knowing its branch, worktree role, and spec folder | `.claude/hooks/session-context.sh` (SessionStart) |

Project-specific values (protected branches, append-only paths, the env template) live in `.claude/hooks/config.sh`. `/open-pr` runs only when you invoke it. `/stakeholder-update` also starts when you ask for a client update in plain words; it shows the draft, and posting asks for confirmation.

## Lightweight mode — match ceremony to the change

| Change | Workflow |
|---|---|
| New feature, behavior change, anything user-facing | `/triage` → `/write-spec` → `/write-plan` → approval → `/write-docs` → `/implement` → `/review` |
| Change request on delivered work | `/triage` → `/write-spec` (amend the folder) → `/write-plan` → approval → `/write-docs` (if documented behavior changes) → `/implement` → `/review` |
| Investigation, impact analysis, estimate | `/triage` → deliver the answer. No spec, no environment unless needed |
| Bug with a clear root cause, behavior restored as documented | `/debug` → regression test → fix → `/commit` |
| Refactor with no behavior change | `/refactor` → tests still green → `/commit` |
| Typo, copy tweak, version bump, formatting, dev-only tooling | Edit → `/commit` |
| Spike or throwaway code | No workflow. If promoted, it gets a spec |

**Heuristic:** if there's nothing to decide, there's nothing to spec. If a teammate could merge the diff without reading new docs, there's nothing for `/write-docs`.

## Cost model

The default model is the version-less alias `"model": "sonnet"` in `.claude/settings.json`; it follows the latest Sonnet as Claude Code updates (keep Claude Code current with `claude update`). Agents use the `haiku` / `sonnet` / `opus` aliases the same way — don't override them casually; pin a full model ID only when the team needs a fixed version. Escalate to Opus for genuinely hard reasoning; workflows multiply cost by the number of agents they run. Keep `AGENTS.md`, this file, and the rules stable: every edit busts the prompt cache for the requests that follow. Decision rules and per-skill tiers: `docs/COST-MODEL.md`.

## Memory

Knowledge lives in layers — `AGENTS.md` (identity and rules), this file (Claude Code config), `.claude/rules/` (standards), spec folders (per feature), ADRs and PDRs (decisions), `docs/reference/` (how subsystems work), and auto memory (learned preferences). If a fact changes more than once a quarter, it doesn't belong in the always-loaded files. Decision tree: `docs/MEMORY-STRATEGY.md`.

## Engineering standards (path-scoped rules)

Rules in `.claude/rules/` load when Claude reads a file matching their `paths:` frontmatter:

| Rule | Scope |
|---|---|
| `code-quality.md` | Source code — typing, naming, error handling, comments |
| `security.md` | Source code |
| `testing.md` | Test files |
| `git-workflow.md` | All files — commits, branches, pull requests |
| `architecture.md` | App structure (customize paths) |
| `ui-ux.md` | UI components and styles |
| `deployment.md` | Infrastructure and CI files |
| `performance.md` | Components and dependency manifests |
| `observability.md` | API and server code |

Delete rules that can't apply to this stack — fewer, sharper rules are followed more consistently.

## MCP servers

Servers in `.mcp.json` are shared with the team; approve them once per machine. A tracker server lets agents read requirements directly — see `docs/TRACKER-INTEGRATION.md` for the rules of engagement and a read-only permission allowlist. Exposing specs and ADRs as MCP resources is optional: `docs/MCP-INTEGRATION.md`.
