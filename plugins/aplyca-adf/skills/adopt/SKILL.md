---
name: adopt
description: Bootstrap a repository for AI-agentic development with the Aplyca framework — inspect it, copy the skeleton and the optional modules the team chooses, fill placeholders with verified facts only, configure the guardrail hooks, stamp the baseline SHA, record the adoption as PDR-0001, verify, and prepare an adoption PR. Works in a new project before any code exists, and adds modules to an already-adopted repository. Use when asked to adopt the framework, enable agentic development, bootstrap AI config, or make a repo AI-ready.
---

# Adopt the Agentic Development Framework

Bring a repository to "Context & Harness" maturity: committed, multi-tool AI configuration
(`AGENTS.md`, tool layers, rules, hooks, spec-folder scaffold) derived from **verified facts about
this specific repo** — never from guesses.

This skill automates `docs/SETUP.md` from the framework repo. When in doubt about a step's intent,
read the source doc (locations in step 1).

## Ground rules

- **Never commit to the default branch.** Work on a feature branch (suggest `docs/agentic-adoption`);
  the deliverable is a reviewable draft PR. The one exception is a new repository's first commit
  (§ A new project).
- **Docs and config only.** Adoption adds no dependencies, no runtime code, and no build changes. The
  hook and worktree scripts are dev tooling; if anything seems to need more, stop and ask.
- **Facts need evidence.** Every placeholder you fill traces to a file you read (manifest, lockfile,
  CI config, code, git history). Anything you can't evidence becomes a
  `<!-- TODO(team): <concrete question> -->` — an honest TODO beats a plausible invention.
- **Client repositories:** confirm before pushing anything. If committing AI config isn't
  appropriate for the client, offer the local-only fallback (`.git/info/exclude`, and the plugin at `--scope local`).

## Step 1 — Locate the framework source

Resolve the framework root, in order:

1. `${CLAUDE_PLUGIN_ROOT}/../..` — only when the plugin runs from a checkout of the framework repo.
2. The marketplace checkout: the `installLocation` of the marketplace (usually `aplyca`) in
   `claude plugin marketplace list --json` — by default `~/.claude/plugins/marketplaces/aplyca/`.
   **The normal case on installed machines** — installed plugins run from a version cache, so
   `${CLAUDE_PLUGIN_ROOT}` isn't inside the repo. Run `claude plugin marketplace update <name>` first.
3. Otherwise clone: `git clone --depth 1 https://github.com/aplyca/AgenticDevelopmentFramework`.

You need `<framework-root>/skeleton/`, `<framework-root>/modules/`, and `<framework-root>/docs/`.
Record the source release, SHA, and date: `git -C <framework-root> describe --tags --abbrev=0 --match 'v*'`
(the newest release at or before the source; none before v1.0.0) and
`git -C <framework-root> log -1 --format='%h (%ad)' --date=short`.

**Already adopted?** If the target's `CLAUDE.md` has a `Skeleton source:` line, don't re-adopt: offer
to install modules (steps 3–4 for the chosen modules only, then update the `modules:` list in the
stamp) or point to `/upgrade`. When the parallel-agents module is already installed, the main
checkout is the hub and its hook stops edits there: do this from a session in a worktree of its own
(`scripts/agent/worktree-new.sh chore/add-modules --no-start`).

### A new project

No git repository, no commits, or nothing to inspect yet (no manifest, no source code): adopting
before the first line of code puts the process and the guardrails in place first. Every other step
applies, with these changes:

- **No repository:** offer `git init -b <default branch>` — ask for the name; suggest `main`.
- **No commits:** there is no default branch to branch from. With the developer's yes, make exactly
  one commit on it, holding everything already there — check `git status` first, so no secret goes
  in — with `git add -A && git commit -m "chore: initial commit"` (add `--allow-empty` when the folder
  is empty). Then branch as usual; nothing else lands on the default branch.
- **Step 2 asks instead of reads.** There are no facts to evidence yet. Ask for the planned ones in one
  round, with your recommendations: language and framework, package manager, test runner, hosting,
  branching model (Model A is the usual start), tracker, ways of working, sensitive areas. Mark each
  answer in `AGENTS.md` as planned — `<!-- planned: not in the repository yet -->` — so no one mistakes
  it for a verified fact. A command nobody has run yet stays a `TODO(team)`.
- **The stack is a decision.** Record it as ADR-0001 in `docs/architecture/decisions/` from the
  template, status `proposed`, with the alternatives the developer considered; the adoption's review
  accepts it.
- **Globs point at planned paths or stay empty** — `CAREFUL_GLOBS`, `APPEND_ONLY_GLOBS`,
  `GENERATED_GLOBS`, the rules' `paths:` — and no nested `AGENTS.md` yet.
- **Step 6:** commands that can't run yet are a GAP — "no code yet" — not a failure.
- **Step 7 without a remote:** commit on the adoption branch, then put the full PR body in your reply —
  not an offer to draft it — with the steps that follow: add the remote, push the branch, and open
  the draft pull request with that body.
- **After the adoption,** the scaffold — the framework's init, the first test — is the first task
  through the lanes; usually full, since it sets the structure others follow. Once that code lands,
  run `/init-project` to replace the planned entries with verified facts, and `/context-audit` to find
  what's stale.

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

- **Ask how to install** (decision 0016), with your recommendation:
  - **Committed** — the default. Everything below is copied into the repository: every AI tool reads
    it, and nothing depends on a plugin.
  - **Packaged** — for a team that works in Claude Code only. The skills, agents, workflows, and hook
    scripts come from the `aplyca-adf` plugin, pinned to a release tag, and the repository commits
    only its own layer and its modules: about 40 fewer files. People type `/aplyca-adf:triage`.
    Claude Code's cloud sessions don't load it, and CI installs it first. It pins a release tag,
    v1.0.0 or later (`git ls-remote --tags https://github.com/aplyca/AgenticDevelopmentFramework 'v*'`);
    with none yet, say so and install committed.

  For packaged, follow `docs/SETUP.md` § Packaged install alongside the steps below: what to leave
  out, the settings, the names in `CLAUDE.md` and `DEV-SETUP.md`, the stamp, and the checks.
- Copy `skeleton/` into the repo **without overwriting existing files**. For collisions (`README.md`,
  `CONTRIBUTING.md`, `.claude/settings.json` are common), merge: keep the project's content, add the
  skeleton's missing sections.
- Ask which AI tools the team uses; delete unused layers per `docs/SETUP.md`: `CLAUDE.md` +
  `.claude/` (Claude Code), `GEMINI.md` (Antigravity/Gemini), `.cursor/` (Cursor).
  `AGENTS.md` always stays. For Antigravity, link its skills folder to Claude Code's — the framework
  ships no symlinks: `mkdir -p .agents && ln -s ../.claude/skills .agents/skills`.
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
  of `AGENTS.md` when both exist). Leave the skeleton-source line for step 5. Packaged: add the names
  note from `docs/SETUP.md` § Packaged install.
- **`docs/getting-started/DEV-SETUP.md`** — packaged: the key commands under § AI-assisted
  development by their full names (`/aplyca-adf:triage`, `@aplyca-adf:code-reviewer`).
- **`.claude/hooks/config.sh`** — `PROTECTED_BRANCHES` (every permanent branch), `APPEND_ONLY_GLOBS`
  (migrations), `GENERATED_GLOBS` (add generated types/clients), `CAREFUL_GLOBS` (the sensitive
  areas, as path globs), `ENV_TEMPLATE` if not auto-detected.
- **`.claude/settings.json`** — extend `permissions.allow` with the repo's routine read-only commands;
  keep the `ask` rules for outward actions; for GitLab, add the `glab` equivalents of the `gh` rules.
  Packaged: no `hooks` block, since the plugin wires them.
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
  `<!-- Skeleton source: <vX.Y.Z> · <SHA> (<YYYY-MM-DD>) · modules: <comma-separated, or none> — see docs/UPGRADING.md in AgenticDevelopmentFramework -->`
  Without it, `/upgrade` has no baseline to diff against. Packaged: the release is the pinned tag and
  the SHA its commit, and `· install: packaged` follows the modules — it's what turns the plugin's
  skills, agents, and hooks on in this project.
- Write **`docs/process/0001-adopt-ai-assisted-workflow.md`** from the PDR template: why the
  team is adopting, what it adds (files, gates, modules, and the install — committed or packaged, and
  why), the costs (docs to keep fresh, more tokens
  for phased work, the approval gate on the critical path), alternatives considered. Ask who the
  deciders are. Add it to the index in `docs/process/README.md`.
- **The plugin setting.** The documented install (`--scope project`) already wrote
  `"extraKnownMarketplaces": {"aplyca": {"source": {"source": "github", "repo": "aplyca/AgenticDevelopmentFramework"}}}`
  and `"enabledPlugins": {"aplyca-adf@aplyca": true}` into `.claude/settings.json`: keep both when
  merging the skeleton's settings, so they're committed with the adoption and teammates get the
  plugin and `/upgrade`. If they're missing — a user- or local-scope install — offer to add them
  (the marketplace key must be `aplyca`, the name `enabledPlugins` refers to), and for a user-scope
  install, give the commands that remove it (the plugin's README § Install). **Pin the release** the
  skeleton came from in the marketplace entry, `"ref": "v<X.Y.Z>"`, in either install: a committed
  project then gets the plugin's copies at the same release as its own files, and a packaged one gets
  its machinery from that release. With no release yet, leave the entry unpinned.

## Step 6 — Verify

Run these checks and report each as PASS / GAP with one line of evidence:

- [ ] `.claude/settings.json` is valid JSON (`python3 -m json.tool .claude/settings.json`) and every hook entry uses the nested `hooks` array
- [ ] `.claude/settings.json` turns the plugin on for the project (`enabledPlugins` and the `aplyca` marketplace) — unless the team chose the local-only fallback
- [ ] Packaged: in a new session, `/aplyca-adf:triage` is offered; run the hook samples below against the plugin's scripts with `CLAUDE_PROJECT_DIR` set (`docs/SETUP.md` § Packaged install)
- [ ] Hook scripts are executable and behave: pipe a sample event to each — e.g. `printf '{"cwd":"%s","tool_input":{"command":"git push origin main"}}' "$PWD" | .claude/hooks/guard-git.sh` exits 2; a `git status` event exits 0
- [ ] `CLAUDE.md` imports `AGENTS.md` (`@AGENTS.md`) — ask the user to start a new session and confirm with `/memory` that both load
- [ ] No `[bracketed placeholders]` remain in `AGENTS.md`, `CONSTITUTION.md`, `CONTRIBUTING.md`; every unknown is a `TODO(team)` question
- [ ] Skill frontmatter uses hyphenated keys only (no `user_invocable` and the like)
- [ ] Build/test/lint commands documented AND runnable by an agent (actually run the safe ones) — in a new project, a GAP until the first code lands
- [ ] Readiness checklist (Agentic Development Guide §9): `README.md` + `AGENTS.md` current; constitution; `specs/` scaffold; `docs/` with architecture and ADRs; skills/MCP versioned; nested `AGENTS.md` where needed (or explicitly not needed); boundaries section; CI gates before merge (GAP if none — don't invent one); written "no merge without human review"

GAPs go in the PR description; they're findings, not failures to hide.

## Step 7 — Deliver

1. Commit on the feature branch: `docs: adopt the Agentic Development Framework (skeleton <SHA>)`.
2. Draft the PR body: facts table summary, tool layers kept/removed, modules installed, open TODOs as
   a checklist, verification results.
3. Push and open the PR **as a draft, only after the user approves**.
