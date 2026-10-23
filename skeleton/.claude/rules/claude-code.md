# [PROJECT NAME] — Claude Code

<!-- The Claude Code layer. AGENTS.md holds the instructions every AI tool shares, and Claude Code reads it natively (v2.1.281 or later); this rule has no `paths:`, so Claude Code loads it in every session beside AGENTS.md, and other tools never read it. Keep the project free of a CLAUDE.md or CLAUDE.local.md: Claude Code reads one of those instead of AGENTS.md (decision 0024 in the framework repository). -->

## Skills, agents, and workflows

- **Skills** (`.claude/skills/`, invoke with `/`) — the workflow playbooks: `/triage`, `/write-spec`, `/write-plan`, `/write-docs`, `/implement`, `/review`, `/commit`, `/open-pr`, and more. They run in this conversation, which already has the rules loaded — the cheapest option.
- **Agents** (`.claude/agents/`, invoke with `@`) — isolated specialists for an independent second opinion, restricted tools (reviewers can't edit), or work that runs alongside yours. `@spec-analyzer` checks a spec folder adversarially before the approval gate.
- **The local environment's URL** — `LOCAL_URL` in `.claude/hooks/config.sh`, or a worktree's `READY_URL` with its `APP_PORT` (parallel-agents); when Docker picks the port (the docker module), `make urls` says where it is. With the `adf-dev` plugin on, a band above the prompt shows it and whether it answers; `/local-url` says the same. Give the developer that URL in the local check.
- **Workflows** (`.claude/workflows/`, invoke with `/deep-…`) — deterministic multi-agent fan-outs with adversarial verification: `/deep-review`, `/deep-spec-analysis`, `/deep-context-audit`, `/deep-drift-sweep`. Several times the cost of the skill they extend — use them for high-stakes changes and broad sweeps.

| Situation | Use |
|---|---|
| Sequential work in this conversation | Skill |
| Independent second opinion, restricted tools, or parallel to your own work | Agent |
| Broad fan-out with verification — a large diff, every spec, every instruction file | Workflow |

Full catalogs (purpose, tools, model tier) are `SKILLS-REFERENCE.md` and `AGENTS-REFERENCE.md` in the framework repository. Agents and skills are generic: they learn this project from `AGENTS.md` and `.claude/rules/`, this file included.

## Guardrails enforced by configuration

Instructions are context, not enforcement. These hold regardless of what the model decides:

| Guardrail | Enforced by |
|---|---|
| Outward actions past the draft pull request — PR ready / merge / review, releases — need your confirmation. The agent commits, pushes the work branch, and opens its draft pull request on its own once its local check passes, in every lane, and keeping that draft current — editing it, commenting on it — needs no prompt. An issue write needs no prompt either; an agent still posts only when you ask | `permissions.ask` and `permissions.allow` in `.claude/settings.json` |
| `git` and `gh` run without a prompt, except `git config` (it could switch off the hooks) and `push --tags`, and readying, merging, or reviewing a pull request, releases, `gh repo delete`, secrets, `gh auth`, and `gh api` writes. Those ask | `permissions.allow` (`git *`, `gh *`) and `permissions.ask` in `.claude/settings.json` |
| Secret env files (`.env`, `.env.local`, `.env.*.local`) are never read into context — extend the list for your other secret files | `permissions.deny` in `.claude/settings.json` |
| No `--no-verify`; no commits or pushes on protected branches; no force-push to them; pull requests open only as drafts | `.claude/hooks/guard-git.sh` (PreToolUse) |
| Generated files and append-only history are not hand-edited | `.claude/hooks/protect-paths.sh` (PreToolUse) |
| Environment variables read in code are declared in the env template (when the repository has one) | `.claude/hooks/check-env-declared.sh` (PostToolUse) |
| Each session starts knowing its branch, worktree role, and spec folder | `.claude/hooks/session-context.sh` (SessionStart) |
| A session hears once when its branch's pull request merged or closed, so it offers `/wrap-up` or asks whether the task is dropped | `.claude/hooks/pr-state.sh` (SessionStart, UserPromptSubmit) |
| The first edit in each sensitive area stops once per session, so the agent confirms the lane is careful or full | `.claude/hooks/careful-paths.sh` (PreToolUse) |
| The triage — the lane and why — comes before the first change, in reply text you can read: a session's first file edit or new branch with no lane stated stops once, as a reminder | `.claude/hooks/triage-first.sh` (PreToolUse) |
| With the parallel-agents module, file edits in the main checkout are stopped, so each task moves to its own worktree first (`/dispatch`) | `.claude/hooks/protect-hub.sh` (PreToolUse) |
| With the docker module, nothing an agent runs changes the local mode — a `make` command or an assignment that sets `DEV_MODE` or `SERVICES`, an `export` of either, an edit to `.env` — so only the developer changes it | `permissions.deny` in `.claude/settings.json` (the docker module) |
| A session's move into a worktree of this repository passes Claude Code's permission check in the desktop app; any other folder still asks. The app's own folder-trust check asks until you trust the folder that holds the main checkout and its worktrees | `.claude/hooks/approve-worktree-move.sh` (PreToolUse) |

Project-specific values (protected branches, append-only paths, the env template, sensitive paths) live in `.claude/hooks/config.sh`. `/open-pr` opens a draft once the agent has walked the change on the local environment, and tells you where to test it: locally and on the preview. Commits, the push, and the draft are a standing go-ahead, so the agent doesn't ask for them — not in a reply, and not in the desktop app's next-step box. `/stakeholder-update` also starts when you ask for a client update in plain words; it shows the draft, and posts only after your yes in chat.

## Commands that run without a prompt

An allow rule matches a command as written, so write each command the way a rule can read it.
Claude Code asks about anything it can't check, even when the command itself is allowed.
- **Use the project's tasks:** `make test t=<file>`, `make lint f=<file>`, `make logs s=web` — a
  variable goes after the task, never as a leading `VAR=value`.
- **Run them in the configured mode.** With the docker module, everything runs in the mode the
  checkout is configured for, and only the developer changes it. Never set `DEV_MODE` or `SERVICES`
  on a command, or change them in `.env` or the `Makefile`, even when asked: say which setting to
  change, and let the developer change it. A task that can't run in this mode is a question for them.
- **Write paths out.** No `S=/path; … $S/…`: an allow rule doesn't match past an assignment, and a
  path in a variable can't be checked.
- **Stay in this checkout:** run `git` from the session's folder, not `git -C <path>`, and `cd` only
  inside the project.
- **Read and edit with the tools, not the shell:** no `for` loops, and no `python3 - <<EOF` or
  `node -e` scripts for what Read, Grep, or Edit do.
- **Keep output in the conversation short with a pipe** (`2>&1 | tail -n 40`), rather than a
  redirect into a file outside the project, which asks.

When a command still prompts every time and only reads, it's a gap in `.claude/settings.json`:
name it to the developer rather than working around it.

## Lanes — match ceremony to risk

| Change | Lane | Workflow | Model |
|---|---|---|---|
| Typo, copy, version bump, dev tooling; a precise adjustment the requester already decided; a bug with a clear cause | Fast | `/triage` (one line) → the test first, seen failing → edit → green → `/commit`; a light `CR N` in the same commit when it changes recorded behavior | `sonnet` |
| The same, touching a migration, authorization, personal data, payments, a shared contract, infrastructure, or a sensitive area | Careful | Fast, plus the area's checklist (`specs/README.md`), `@security-reviewer` for authorization, data, or payments, and the risky part named in the pull request for your test | `sonnet`, high effort |
| New feature, unclear requirement, a design choice, cross-layer work, a change request with something to decide | Full | `/triage` → `/write-spec` → `/write-plan` → approval → `/write-docs` → `/implement` → `/review` | `opus` up to the gate; a fresh `sonnet` session from `/write-docs` on |
| Bug, cause unknown | — | `/debug`, then the lane the fix needs | `sonnet`; `opus` after two disproven hypotheses |
| Refactor with no behavior change | Fast, or full when it sets a structure others must follow | `/refactor` → tests still green → `/commit` | `sonnet` |
| Investigation, impact analysis, estimate | — | `/triage` → deliver the answer. No spec, no environment unless needed | `sonnet`; `opus` for architecture-level questions |
| Spike or throwaway code | — | No workflow. If promoted, it gets a lane | — |

**Heuristic:** if there's nothing to decide, there's no spec folder. If a teammate could merge the diff without reading new docs, there's nothing for `/write-docs`.

**Your intuition sets the lane too.** Say "full lane on this", "be careful here", or "just a quick fix" — raising is always honored; lowering keeps a risk area's checklist unless you accept the risk. Effort has other dials — questions first, `/evaluate` before choosing a design, a higher effort level or `/model opus`, `/deep-review` — each with a different cost (`docs/COST-MODEL.md` § Effort).

## Cost model

Every call re-reads the conversation, so a session's cost is roughly *calls × context*: keep sessions to one task (`/clear` between tasks) and output short (`AGENTS.md` § Working economically).

**Choose the model by the work, with the version-less aliases.** `sonnet` when the task has a clear spec and a way to check the result — the fast and careful lanes, bug fixes, investigations, reviews, implementing an approved plan. `opus` for judgment — the full lane's spec and plan, ambiguous or long-horizon work, a bug that resists diagnosis. Effort: the default (medium) for well-specified work, `high` (`/effort high`) for harder or longer work; `xhigh` and `max` make Sonnet think longer and cost more. Each model has its own prompt cache, so switch where it's cheap: when the session starts, right after triage (the context is still small), or in a fresh session after the approval gate. `/triage` says when the session's model doesn't fit the lane. `opusplan` (Opus in plan mode, Sonnet otherwise) suits developers who plan in plan mode.

The project default is `"model": "sonnet"` in `.claude/settings.json`; it follows the latest Sonnet as Claude Code updates (keep Claude Code current with `claude update`). For a session, the desktop app's model picker and `/model` decide — and Claude Code's own `default` is Opus, so pick Sonnet for quick work. A 1M-context model lets sessions grow far past what a task needs. Agents carry their own alias and run in their own context, so their model costs no cache switch: reviews on `sonnet`, `@spec-analyzer` and `@architect` on `opus`. Don't override them casually; pin a full model ID only when the team needs a fixed version. Workflows multiply cost by the number of agents they run. Keep `AGENTS.md`, this file, and the rules stable: every edit busts the prompt cache for the requests that follow. Lanes, effort, and per-skill tiers: `docs/COST-MODEL.md`.

## Memory

Knowledge lives in layers — `AGENTS.md` (identity and rules), this file (Claude Code config), `.claude/rules/` (standards), spec folders (per feature), ADRs and PDRs (decisions), `docs/reference/` (how subsystems work), and auto memory (learned preferences). If a fact changes more than once a quarter, it doesn't belong in the always-loaded files. Decision tree: `docs/MEMORY-STRATEGY.md`.

## Engineering standards (path-scoped rules)

Rules in `.claude/rules/` load when Claude reads a file matching their `paths:` frontmatter; a rule without `paths:`, like this one, loads in every session:

| Rule | Scope |
|---|---|
| `claude-code.md` | Every session — this file, the Claude Code layer |
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
