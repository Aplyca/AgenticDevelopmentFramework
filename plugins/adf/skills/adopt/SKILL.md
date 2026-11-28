---
name: adopt
description: Bootstrap a repository for the Agentic Development Framework — the skeleton and chosen modules, placeholders filled from verified facts, the hooks, PDR-0001, and the adoption pull request — even before any code exists; also adds modules to an adopted repository. Use when asked to adopt the framework, enable agentic development, bootstrap AI config, or make a repo AI-ready.
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
  (`new-project.md`).
- **Docs and config only.** Adoption adds no dependencies, no runtime code, and no build changes. The
  hook and worktree scripts are dev tooling; if anything seems to need more, stop and ask.
- **Facts need evidence.** Every placeholder you fill traces to a file you read (manifest, lockfile,
  CI config, code, git history). Anything you can't evidence becomes a
  `<!-- TODO(team): <concrete question> -->` — an honest TODO beats a plausible invention.
- **Client repositories:** confirm before pushing anything. If committing AI config isn't
  appropriate for the client, offer the local-only fallback (`.git/info/exclude`, and the plugin at `--scope local`).

## Step 1 — Locate the framework source, at the newest release

Adopt from a release, never from whatever commit a checkout is at: the project pins that release
(Step 5), and its committed files and the plugin's copies have to be the same release (decision 0016).

1. **The newest release:** `git ls-remote --tags --refs --sort=-v:refname https://github.com/aplyca/AgenticDevelopmentFramework 'v*' | head -1`
   — sorted by version, so v2.10.0 comes before v2.9.0, which a sort by name gets wrong.
2. **The framework at that tag**, as `<framework-root>`, in a scratch folder outside the target:
   - from a local checkout of the framework repository that has the tag — the marketplace's
     `installLocation` in `claude plugin marketplace list --json`, when the marketplace was added from
     one: `git -C <checkout> worktree add --detach <scratch> <tag>`;
   - otherwise: `git clone --depth 1 --branch <tag> https://github.com/aplyca/AgenticDevelopmentFramework <scratch>`.

   Installed plugins run from a version cache, never from the repository.

You need `<framework-root>/skeleton/`, `<framework-root>/modules/`, and `<framework-root>/docs/`.
Record the release (the tag), its commit (`git -C <framework-root> rev-parse --short HEAD`), and the
commit's date (`git -C <framework-root> log -1 --format=%ad --date=short`).

**Already adopted?** If the first line of the target's `AGENTS.md` — or of `CLAUDE.md`, in a project
adopted before v2.0.0 — is a `Skeleton source:` stamp, don't re-adopt: offer to install modules, as
`<this skill's base directory>/modules.md` § Already adopted says, or point to `/adf:upgrade`.

**A new project** — no git repository, no commits, or nothing to inspect yet (no manifest, no source
code): read `<this skill's base directory>/new-project.md`. Every step applies, with the changes it
lists.

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
- **Requirements source** — ask: which tracker (ClickUp, GitHub issues, GitLab issues, Jira, Linear, none)? Its MCP endpoint, if any; on issues, the labels that mean in progress and in review; and when a merged change is live — on the merge, on a release, or when someone says? Recommend the answer the branching model suggests (Model A deploying `main`: on the merge; a tag that ships: on a release)
- **Connected services** — ask: which services does the stack use that agents should read — a database, hosting, a CMS (Supabase, Vercel, Contentful…)? Each one with an official MCP server is a later `/adf-connect:connect`
- **Git host** — GitHub, GitLab, other (from `git remote -v`)
- **Containers** — `Dockerfile*`, Compose files (`compose.yaml`, `compose.yml`, `docker-compose.y*ml`), a `Makefile`, `ops/`, `.devcontainer/`; what the local stack runs, and how
- **Ways of working** — ask: several agent sessions in parallel, each needing a running app? A requester who gets status updates?
- **Boundaries & antipatterns** — frozen or legacy directories, deliberate deviations (ask; rarely has file evidence)
- **Sensitive areas** — ask: which parts of the code need care whatever the size of the change (billing, auth, migrations, data exports…)? Past incidents and fragile modules are good evidence
- **CI & enforcement** — what pipelines exist, what branch protection is known; if none, record that as a fact
- **The project's own instructions** (decision 0099) — an existing `AGENTS.md`, `CLAUDE.md`,
  `GEMINI.md`, `.cursor/rules/`, or `.claude/rules/`: read `<this skill's base directory>/compatibility.md`
  and run its pass. Its table goes beside the facts table, with its questions in the same round.

Present the table before going further. Wrong facts here poison every file downstream.

## Step 3 — Copy the skeleton and the chosen modules

- **Ask how to install** (decisions 0016, 0018), with your recommendation:
  - **Packaged** — the default. The skills, agents, workflows, hook scripts, and the framework's
    reference docs come from the `adf` plugin, pinned to a release tag, and the repository
    commits only its own layer and its modules. People type
    `/adf:triage`. Claude Code's cloud sessions don't load it, and CI installs it first. It
    pins the release from Step 1.
  - **Committed** — recommend it instead when the team also uses another AI tool for the framework's
    skills (Cursor, Copilot, Gemini or Antigravity) or needs Claude Code's cloud sessions. The
    machinery is written into the repository too: every AI tool reads it, and nothing depends on a
    plugin.

  For packaged, follow `docs/SETUP.md` § Packaged install alongside the steps below: what to leave
  out, the settings, the names in `.claude/rules/claude-code.md` and `DEV-SETUP.md`, the stamp, and the
  checks.
  **The reference docs** (decision 0019) — `COST-MODEL.md`, `MCP-INTEGRATION.md`,
  `MEMORY-STRATEGY.md`, `PROSE-PATTERNS.md`, `SPEC-MODEL.md` — come from the plugin. Once the
  files are in, run
  `python3 <framework-root>/scripts/link-reference-docs.py <repo> --packaged <tag>`: it points the
  files that name a reference doc at the pinned release, and lists any other file that still names
  one — one the team wrote follows by hand.
- Copy `skeleton/` into the repo **without overwriting existing files**: it's the layer the project
  owns. For collisions (`README.md`, `CONTRIBUTING.md`, `.claude/settings.json` are common), merge:
  keep the project's content, add the skeleton's missing sections. **An existing `AGENTS.md`, or a
  rule in `.cursor/rules/` or `.claude/rules/`, merges by the compatibility table** Step 2 showed and
  the developer approved: each line where the table put it.
- **Committed:** write the machinery from the plugins, as
  `<this skill's base directory>/committed.md` says. Packaged: skip it.
- **An existing `CLAUDE.md` or `GEMINI.md`** (decisions 0024, 0025): sort each by the compatibility
  table, as `<this skill's base directory>/ai-tools.md` says.
- Ask which AI tools the team uses; delete unused layers per `docs/SETUP.md`: `.claude/` (Claude
  Code, with its layer in `.claude/rules/claude-code.md`), `.gemini/` (Gemini CLI, which it points at
  `AGENTS.md`), `.cursor/` (Cursor).
  `AGENTS.md` always stays. For Antigravity, link its skills folder as `ai-tools.md` says.
- Ask whether the team writes custom skills, rules, or hooks that need automated checks. If not — the
  common case — delete `evals/`.
- **Offer the modules** by `<framework-root>/modules/README.md` § Recommending a module: recommend
  each one the facts support, with why it fits and what it costs; the developer chooses. Install
  each chosen one, and turn on the plugin that carries it, as
  `<this skill's base directory>/modules.md` § Installing says.
- **Offer `adf-connect`** (decision 0023) when the facts name a tracker other than ClickUp or GitHub or
  GitLab issues (Jira, Linear), or connected services: turn on `"adf-connect@aplyca": true` in
  `enabledPlugins`, in either install. Connecting each service is a follow-up for the pull request:
  `/adf-connect:connect <service>` in a new session after the merge.
- Make sure `.gitignore` covers `.env` files, `.claude/settings.local.json`, `CLAUDE.local.md`, and
  `.claude/worktrees/`.

## Step 4 — Fill placeholders from the facts table

- **`AGENTS.md`** — identity, stack, ground rules, delivery rules (base branch, protected branches),
  sensitive areas, boundaries & antipatterns, conventions, structure, quick reference (commands
  exactly as typed — running one test or linting one file with the variable the project's task
  takes, read from its `Makefile` or scripts, or "none").
  Under ~200 lines; link instead of inlining. Monorepo: nested `AGENTS.md` per module whose rules
  differ (template in `/init-project`).
- **`docs/CONSTITUTION.md`** — 5–10 real principles agreed with the user; it overrides `AGENTS.md`, so
  the two must agree.
- **`.claude/rules/claude-code.md`** — the Claude Code layer, which loads in every session beside
  `AGENTS.md`. Leave the stamp on `AGENTS.md`'s first line for step 5. Packaged: add the names note
  from `docs/SETUP.md` § Packaged install.
- **`docs/getting-started/DEV-SETUP.md`** — packaged: the key commands under § AI-assisted
  development by their full names (`/adf:triage`, `@adf:code-reviewer`); a
  module's skill goes by the name of the plugin that carries it (`/adf-dev:dev-env`).
- **`.claude/hooks/config.sh`** — `APPROVE_STATUS_MOVE` (the tracker tool that moves a task's status, when the tracker has an MCP server), `PROTECTED_BRANCHES` (every permanent branch), `APPEND_ONLY_GLOBS`
  (migrations), `GENERATED_GLOBS` (add generated types/clients), `CAREFUL_GLOBS` (the sensitive
  areas, as path globs), `ENV_TEMPLATE` if not auto-detected, `LOCAL_URL` (the URL the agent
  walks for the local check — from the facts' dev server and port).
- **`.claude/settings.json`** — extend `permissions.allow` with the repo's routine read-only commands;
  keep the `ask` rules for outward actions, the `glab` ones beside the `gh` ones on either host.
  Packaged: no `hooks` block, since the plugin wires them, and
  `Read(~/.claude/plugins/cache/aplyca/adf/**)` in `permissions.allow`, so the plugin's skills
  and agents open its reference docs without asking.
- **`.claude/rules/*`** — `<!-- CUSTOMIZE -->` sections and `paths:` frontmatter to the real
  structure; delete rules that can't apply.
- **`CONTRIBUTING.md`** — keep the branching model that matches (A or B), the status vocabulary,
  and an honest "what's enforced" section.
- **`docs/TRACKER-INTEGRATION.md`** — the tracker, `.mcp.json` (if it has an MCP server), and a
  read-only `mcp__<server>__…` allowlist from the server's real tool names. With the `clickup`
  module, `modules.md` § Filling in has its values. On GitHub or GitLab issues, there's no server:
  name the labels for in progress and in review in *Status at each moment*, and keep § Issues as the
  tracker. Fill *Live when* from the answer in Step 2, and leave *Updates post* at `on their own`
  unless the team wants every update approved first. Delete the page if there is no tracker.
- **Modules** — each chosen module's settings, as `modules.md` § Filling in says.
- **`.claudeignore`** — prune entries that can't apply (keep its header); add generated/secret paths.
- Every unknown: `<!-- TODO(team): <question> -->`. Fill each doc's `owner · last_updated · scope`.

## Step 5 — Stamp the baseline and record the decision

- First line of `AGENTS.md`:
  `<!-- Skeleton source: <vX.Y.Z> · <SHA> (<YYYY-MM-DD>) · modules: <comma-separated, or none> — see docs/UPGRADING.md in AgenticDevelopmentFramework -->`
  The release, its commit, and the date are the ones Step 1 recorded. Without the stamp, `/adf:upgrade` has
  no baseline to diff against. Packaged: `· install: packaged` follows the modules — it's what turns
  the plugin's skills, agents, and hooks on in this project.
- Write **`docs/process/0001-adopt-ai-assisted-workflow.md`** from the PDR template: why the
  team is adopting, what it adds (files, gates, modules, and the install — committed or packaged, and
  why), the costs (docs to keep fresh, more tokens
  for phased work, the approval gate on the critical path), alternatives considered, and each
  override the compatibility pass kept. Ask who the deciders are. Add it to the index in
  `docs/process/README.md`.
- **The plugin setting.** The documented install (`--scope project`, at the newest release) already wrote
  `"extraKnownMarketplaces": {"aplyca": {"source": {"source": "github", "repo": "aplyca/AgenticDevelopmentFramework", "ref": "v<X.Y.Z>"}}}`
  and `"enabledPlugins": {"adf@aplyca": true}` into `.claude/settings.json`: keep both when merging
  the skeleton's settings, so they're committed with the adoption and teammates get the plugin and
  `/adf:upgrade`. If they're missing — a user- or local-scope install — read
  `<this skill's base directory>/plugin-scope.md`. **Pin the release** the skeleton came from in the
  marketplace entry, `"ref": "v<X.Y.Z>"`, in either install: a committed project then gets the
  plugin's copies at the same release as its own files, and a packaged one gets its machinery from
  that release. Add `"autoUpdate": true` to the same entry. Writing the pin doesn't move this
  machine's copy of the marketplace, which Step 6 checks (`plugin-scope.md`).

## Step 6 — Verify

Run these checks and report each as PASS / GAP with one line of evidence:

- [ ] `.claude/settings.json` is valid JSON (`python3 -m json.tool .claude/settings.json`) and every hook entry uses the nested `hooks` array
- [ ] `.claude/settings.json` turns the plugin on for the project (`enabledPlugins` and the `aplyca` marketplace) — unless the team chose the local-only fallback
- [ ] This machine's copy of the marketplace is at the pin: `aplyca`'s `ref` in `claude plugin marketplace list --json` equals the settings' `"ref"`. A GAP when it differs or is missing, fixed as `plugin-scope.md` says: `claude plugin update` isn't enough (decision 0091)
- [ ] Packaged: in a new session, `/adf:triage` is offered; run the hook samples below against the plugin's scripts with both variables set — `CLAUDE_PROJECT_DIR="$PWD" CLAUDE_PLUGIN_ROOT=<marketplace folder>/plugins/adf <marketplace folder>/plugins/adf/hooks/guard-git.sh`, the marketplace folder being `aplyca`'s `installLocation` in `claude plugin marketplace list --json` (`docs/SETUP.md` § Packaged install)
- [ ] Packaged: none of the reference docs is in `docs/`, `link-reference-docs.py` run again rewrites nothing, and `permissions.allow` has the plugin's read rule
- [ ] Each installed module passes the checks in `modules.md` § Checking them
- [ ] Hook scripts are executable and behave: pipe a sample event to each — e.g. `printf '{"cwd":".","tool_input":{"command":"git push origin main"}}' | .claude/hooks/guard-git.sh` exits 2; a `git status` event exits 0
- [ ] No `CLAUDE.md` or `CLAUDE.local.md` in the repository; ask the user to start a new session and confirm with `/memory` that `AGENTS.md` and `.claude/rules/claude-code.md` load, and that the session-context hook prints no warning about a `CLAUDE.md`
- [ ] No `[bracketed placeholders]` remain in `AGENTS.md`, `CONSTITUTION.md`, `CONTRIBUTING.md`; every unknown is a `TODO(team)` question
- [ ] The compatibility pass held, by `compatibility.md`'s check
- [ ] Skill frontmatter uses hyphenated keys only (no `user_invocable` and the like)
- [ ] Build/test/lint commands documented AND runnable by an agent (actually run the safe ones) — in a new project, a GAP until the first code lands
- [ ] Readiness checklist (Agentic Development Guide §9): `README.md` + `AGENTS.md` current; constitution; `specs/` scaffold; `docs/` with architecture and ADRs; skills/MCP versioned; nested `AGENTS.md` where needed (or explicitly not needed); boundaries section; CI gates before merge (GAP if none — don't invent one); written "no merge without human review"

GAPs go in the PR description; they're findings, not failures to hide.

## Step 7 — Deliver

1. Commit on the feature branch: `docs: adopt the Agentic Development Framework (skeleton <SHA>)`.
2. Draft the PR body: facts table summary, tool layers kept/removed, modules installed, the
   compatibility table under `## Compatibility` (or `- none found`), open TODOs as a checklist,
   verification results — and a `## Follow-ups` section, the one `/adf:wrap-up` reads
   after the merge: one `- [ ] \`<command>\` — <why> (adoption)` line for each follow-up Steps 3–4
   named (the committed names in a committed install), or `- none`.
3. Push and open the PR **as a draft, only after the user approves** — the standing go-ahead for drafts (`AGENTS.md` § Delivery rules) covers task work, and this pull request installs the rules that grant it.
