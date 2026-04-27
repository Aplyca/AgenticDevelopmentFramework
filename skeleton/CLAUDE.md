# [PROJECT NAME] — Claude Code Instructions

<!-- This file extends AGENTS.md with Claude Code-specific features. -->
<!-- AGENTS.md contains universal project context (read by all AI tools). -->
<!-- This file adds: path-scoped rules, specialized agents, workflow skills. -->

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
| `/write-spec` | Draft a feature specification |
| `/implement` | Build from an approved spec (reads spec git diff for scope) |
| `/write-tests` | Write tests from spec acceptance criteria |
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
