---
name: adopt
description: Bootstrap a repository for AI-agentic development with the Aplyca framework — inspect it, copy the skeleton and the optional modules the team chooses, fill placeholders with verified facts only, configure the guardrail hooks, stamp the baseline SHA, record the adoption as PDR-0001, verify, and prepare an adoption PR. Also adds modules to an already-adopted repository. Use when asked to adopt the framework, enable agentic development, bootstrap AI config, or make a repo AI-ready.
---

# Adopt the Agentic Development Framework

Bring a repository to "Context & Harness" maturity: committed, multi-tool AI configuration
(`AGENTS.md`, tool layers, rules, hooks, spec-folder scaffold) derived from **verified facts about
this specific repo** — never from guesses.

This skill automates `docs/SETUP.md` from the framework repo. When in doubt about a step's intent,
read the source doc (locations in step 1).

## Ground rules

- **Never commit to the default branch.** Work on a feature branch (suggest `docs/agentic-adoption`);
  the deliverable is a reviewable draft PR.
- **Docs and config only.** Adoption adds no dependencies, no runtime code, and no build changes. The
  hook and worktree scripts are dev tooling; if anything seems to need more, stop and ask.
- **Facts need evidence.** Every placeholder you fill traces to a file you read (manifest, lockfile,
  CI config, code, git history). Anything you can't evidence becomes a
  `<!-- TODO(team): <concrete question> -->` — an honest TODO beats a plausible invention.
- **Client repositories:** confirm before pushing anything. If committing AI config isn't
  appropriate for the client, offer the local-only fallback (`.git/info/exclude` + user-level config).

## Step 1 — Locate the framework source

Resolve the framework root, in order:

1. `${CLAUDE_PLUGIN_ROOT}/../..` — only when the plugin runs from a checkout of the framework repo.
2. The marketplace checkout: `~/.claude/plugins/marketplaces/<marketplace-name>/` (usually `aplyca`).
   **The normal case on installed machines** — installed plugins run from a version cache, so
   `${CLAUDE_PLUGIN_ROOT}` isn't inside the repo. Run `claude plugin marketplace update <name>` first.
3. Otherwise clone: `git clone --depth 1 https://github.com/aplyca/AgenticDevelopmentFramework`.

You need `<framework-root>/skeleton/`, `<framework-root>/modules/`, and `<framework-root>/docs/`.
Record the source SHA and date: `git -C <framework-root> log -1 --format='%h (%ad)' --date=short`.

**Already adopted?** If the target's `CLAUDE.md` has a `Skeleton source:` line, don't re-adopt: offer
to install modules (steps 3–4 for the chosen modules only, then update the `modules:` list in the
stamp) or point to `/upgrade`. When the parallel-agents module is already installed, the main
checkout is the hub and its hook stops edits there: do this from a session in a worktree of its own
(`scripts/agent/worktree-new.sh chore/add-modules --no-start`).

## Step 2 — Discover the repo (read-only, before copying anything)

Build a facts table (`fact → evidence file:line`):

- **Stack & versions** — manifests, lockfiles, framework configs, version files
- **Commands** — install, dev server(s) and ports, build, test layers, lint, typecheck; per-app in a monorepo
- **Environment** — the env template's name, declared variables vs the variables the code actually
  reads (grep `process.env`, `os.environ`, `getenv`…) — undeclared ones are onboarding landmines
- **Structure** — monorepo layout, module boundaries, shared libraries, generated code
- **Branching & release** — permanent branches (`git branch -r`), merge style (`git log --merges`,
  squash patterns), tags, deploy triggers in CI. Match it to **Model A** (feature branches into
  `main`, optional never-merged integration branch) or **Model B** (integration branch, release
  merge, tag ships) from the skeleton's `CONTRIBUTING.md` — or note a third shape
- **History that must stay append-only** — migrations directories; **generated files** — lockfiles, generated types
- **Requirements source** — ask: which tracker (ClickUp, Jira, Linear, GitHub Issues, none)? Its MCP endpoint, if any
- **Git host** — GitHub, GitLab, other (from `git remote -v`)
- **Ways of working** — ask: several agent sessions in parallel, each needing a running app? A requester who gets status updates?
- **Boundaries & antipatterns** — frozen or legacy directories, deliberate deviations (ask; rarely has file evidence)
- **Sensitive areas** — ask: which parts of the code need care whatever the size of the change (billing, auth, migrations, data exports…)? Past incidents and fragile modules are good evidence
- **CI & enforcement** — what pipelines exist, what branch protection is known; if none, record that as a fact

Present the table before going further. Wrong facts here poison every file downstream.

## Step 3 — Copy the skeleton and the chosen modules

- Copy `skeleton/` into the repo **without overwriting existing files**. For collisions (`README.md`,
  `CONTRIBUTING.md`, `.claude/settings.json` are common), merge: keep the project's content, add the
  skeleton's missing sections.
- Ask which AI tools the team uses; delete unused layers per `docs/SETUP.md`: `CLAUDE.md` +
  `.claude/` (Claude Code), `GEMINI.md` + `.agents/` (Antigravity/Gemini), `.cursor/` (Cursor).
  `AGENTS.md` always stays.
- Ask whether the team writes custom skills, rules, or hooks that need automated checks. If not — the
  common case — delete `evals/`.
- **Offer the modules** (`modules/README.md`), recommending from the facts:
  - `github` — when the repo is on GitHub
  - `git-hooks` — when the team wants local gates for every git client
  - `clickup` — when requirements arrive as ClickUp tasks (`app.clickup.com` links in pull requests,
    commits, or the README are good evidence)
  - `parallel-agents` — recommend it whenever several agent sessions may work on the repository at once: each task gets its own worktree, branch, pull request, and session, and the main checkout only dispatches (ports and start commands only if each worktree runs a server)
  Install each chosen one with `cp -R modules/<name>/files/. <repo>/` (same no-overwrite rule) —
  except `clickup`, which merges into `.mcp.json` and `.claude/settings.json`:
  `modules/clickup/install.sh <repo>`.
- Make sure `.gitignore` covers `.env` files, `.claude/settings.local.json`, `CLAUDE.local.md`, and
  `.claude/worktrees/`.

## Step 4 — Fill placeholders from the facts table

- **`AGENTS.md`** — identity, stack, ground rules, delivery rules (base branch, protected branches),
  sensitive areas, boundaries & antipatterns, conventions, structure, quick reference (commands
  exactly as typed).
  Under ~200 lines; link instead of inlining. Monorepo: nested `AGENTS.md` per module whose rules
  differ (template in `/init-project`).
- **`docs/CONSTITUTION.md`** — 5–10 real principles agreed with the user; it overrides `AGENTS.md`, so
  the two must agree.
- **`CLAUDE.md`** — keep `@AGENTS.md` as its first instruction (Claude Code reads `CLAUDE.md` instead
  of `AGENTS.md` when both exist). Leave the skeleton-source line for step 5.
- **`.claude/hooks/config.sh`** — `PROTECTED_BRANCHES` (every permanent branch), `APPEND_ONLY_GLOBS`
  (migrations), `GENERATED_GLOBS` (add generated types/clients), `CAREFUL_GLOBS` (the sensitive
  areas, as path globs), `ENV_TEMPLATE` if not auto-detected.
- **`.claude/settings.json`** — extend `permissions.allow` with the repo's routine read-only commands;
  keep the `ask` rules for outward actions; for GitLab, add the `glab` equivalents of the `gh` rules.
- **`.claude/rules/*`** — `<!-- CUSTOMIZE -->` sections and `paths:` frontmatter to the real
  structure; delete rules that can't apply.
- **`CONTRIBUTING.md`** — keep the branching model that matches (A or B), the status vocabulary,
  and an honest "what's enforced" section.
- **`docs/TRACKER-INTEGRATION.md`** — the tracker, `.mcp.json` (if it has an MCP server), and a
  read-only `mcp__<server>__…` allowlist from the server's real tool names. With the `clickup`
  module, fill the values its `MODULE.md` § Customize lists (task links, statuses via
  `clickup_get_task` with `expand_statuses: true`, where PR links go). Delete the page if there is no
  tracker.
- **Modules** — `scripts/agent/worktree.conf`; the PR template's quality and constitution checklists;
  `branch-policy.yml` (`GUARDED_BASE`, `ALLOWED_HEADS` or `FORBIDDEN_HEADS`); `FAST_CHECKS` in
  `.githooks/pre-push`; the `AGENTS.md` "Parallel sessions" line per the module's `MODULE.md`.
- **`.claudeignore`** — prune entries that can't apply (keep its header); add generated/secret paths.
- Every unknown: `<!-- TODO(team): <question> -->`. Fill each doc's `owner · last_updated · scope`.

## Step 5 — Stamp the baseline and record the decision

- Top of `CLAUDE.md`:
  `<!-- Skeleton source: <SHA> (<YYYY-MM-DD>) · modules: <comma-separated, or none> — see docs/UPGRADING.md in AgenticDevelopmentFramework -->`
  Without it, `/upgrade` has no baseline to diff against.
- Write **`docs/process/0001-adopt-ai-assisted-workflow.md`** from the PDR template: why the
  team is adopting, what it adds (files, gates, modules), the costs (docs to keep fresh, more tokens
  for phased work, the approval gate on the critical path), alternatives considered. Ask who the
  deciders are. Add it to the index in `docs/process/README.md`.
- *(Optional, ask)* Register the framework marketplace for the team in `.claude/settings.json`, so
  teammates get `/upgrade`:
  `"extraKnownMarketplaces": {"aplyca": {"source": {"source": "github", "repo": "aplyca/AgenticDevelopmentFramework"}}}`
  and `"enabledPlugins": {"aplyca-framework@aplyca": true}` — the marketplace key must be `aplyca`,
  the name `enabledPlugins` refers to.

## Step 6 — Verify

Run these checks and report each as PASS / GAP with one line of evidence:

- [ ] `.claude/settings.json` is valid JSON (`python3 -m json.tool .claude/settings.json`) and every hook entry uses the nested `hooks` array
- [ ] Hook scripts are executable and behave: pipe a sample event to each — e.g. `printf '{"cwd":"%s","tool_input":{"command":"git push origin main"}}' "$PWD" | .claude/hooks/guard-git.sh` exits 2; a `git status` event exits 0
- [ ] `CLAUDE.md` imports `AGENTS.md` (`@AGENTS.md`) — ask the user to start a new session and confirm with `/memory` that both load
- [ ] No `[bracketed placeholders]` remain in `AGENTS.md`, `CONSTITUTION.md`, `CONTRIBUTING.md`; every unknown is a `TODO(team)` question
- [ ] Skill frontmatter uses hyphenated keys only (no `user_invocable` and the like)
- [ ] Build/test/lint commands documented AND runnable by an agent (actually run the safe ones)
- [ ] Readiness checklist (Agentic Development Guide §9): `README.md` + `AGENTS.md` current; constitution; `specs/` scaffold; `docs/` with architecture and ADRs; skills/MCP versioned; nested `AGENTS.md` where needed (or explicitly not needed); boundaries section; CI gates before merge (GAP if none — don't invent one); written "no merge without human review"

GAPs go in the PR description; they're findings, not failures to hide.

## Step 7 — Deliver

1. Commit on the feature branch: `docs: adopt the Agentic Development Framework (skeleton <SHA>)`.
2. Draft the PR body: facts table summary, tool layers kept/removed, modules installed, open TODOs as
   a checklist, verification results.
3. Push and open the PR **as a draft, only after the user approves**.
