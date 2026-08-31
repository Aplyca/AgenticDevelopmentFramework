---
name: adopt
description: Bootstrap a repository for AI-agentic development with the Aplyca framework — copy the skeleton, derive project facts by inspection, fill placeholders with verified facts only, stamp the baseline SHA, and prepare an adoption PR. Use when asked to adopt the framework, enable agentic development, bootstrap AI config, or make a repo AI-ready.
---

# Adopt the AI-Assisted Development Framework

Bring a repository to "Context & Harness" maturity: committed, multi-tool AI configuration
(`AGENTS.md`, tool layers, rules, specs scaffold) derived from **verified facts about this
specific repo** — never from guesses.

This skill automates `docs/SETUP.md` from the framework repo. When in doubt about a step's
intent, read the source doc (locations in step 1).

## Ground rules

- **Never commit to the default branch.** All work happens on a feature branch
  (suggest `feat/agentic-adoption`); the deliverable is a reviewable PR.
- **Docs and config only.** Adoption must add no dependencies, no runtime code, and no
  build changes. If a step seems to require one, stop and ask.
- **Facts need evidence.** Every placeholder you fill must trace to a file you read
  (manifest, lockfile, CI config, code). Anything you cannot evidence becomes a
  `<!-- TODO(team): ... -->` marker with a concrete question — an honest TODO beats a
  plausible invention.
- **Client repos:** confirm with the user before pushing anything to a remote. If
  committing AI config to the repo is inappropriate for the client, offer the local-only
  fallback (`.git/info/exclude` + user-level config) instead.

## Step 1 — Locate the framework source

Resolve the skeleton, in order:

1. `${CLAUDE_PLUGIN_ROOT}/../../skeleton` — present only when the plugin runs from a
   checkout of the framework repo (development / skills-dir installs).
2. The marketplace checkout: `~/.claude/plugins/marketplaces/<marketplace-name>/skeleton`
   (the marketplace this plugin was installed from — usually `aplyca`). **This is the
   normal case on installed machines**: installed plugins run from a version cache, so
   `${CLAUDE_PLUGIN_ROOT}` does not sit inside the repo. Run
   `claude plugin marketplace update <marketplace-name>` first so the checkout is current.
3. Otherwise clone fresh: `git clone --depth 1 https://github.com/aplyca/ai-dev-starter-kit`
   into a temporary directory.

The framework docs sit next to the skeleton at `<framework-root>/docs/`.

Record the source SHA and date: `git -C <framework-root> log -1 --format='%h (%ad)' --date=short`.
You will stamp this into the target's `CLAUDE.md` in step 5.

## Step 2 — Discover the repo (read-only, before copying anything)

Build a facts table (`fact → evidence file:line`) covering:

- **Stack & versions** — package manifests, lockfiles, framework configs, `.nvmrc` / `.tool-versions`
- **Commands** — dev server(s) with ports, build, test, lint, format; for monorepos, per-app commands
- **Environment** — declared env samples vs. variables the code actually reads (grep for
  `process.env`, `os.environ`, etc.); note undeclared ones — they are onboarding landmines
- **Structure** — monorepo layout, module boundaries, shared libraries
- **Conventions** — commit-message style and merge strategy from `git log`, existing lint/format configs
- **Boundaries & antipatterns** — frozen/legacy dirs, generated code, things agents must not touch
  (ask the user; this rarely has file evidence)
- **CI & deployment** — pipelines if present; if absent, record that as a fact worth stating

Present the table to the user before proceeding. Wrong facts here poison every file downstream.

## Step 3 — Copy the skeleton

- Copy `skeleton/` contents into the repo root **without overwriting existing files**.
  For collisions (`README.md`, `CONTRIBUTING.md`, `.claude/settings.json` are common),
  merge: keep the project's content, add the skeleton's missing sections.
- Ask which AI tools the team uses, then delete unused layers per `docs/SETUP.md`:
  `CLAUDE.md` + `.claude/` (Claude Code), `GEMINI.md` + `.agents/` (Antigravity/Gemini),
  `.cursor/` (Cursor). `AGENTS.md` always stays.
- Ask whether the team writes custom skills, rules, or spec patterns that need
  automated checks. If not — the common case — delete `evals/`: it is scaffold for
  testing team-authored framework artifacts, not the project itself, and can be
  re-adopted later from the framework repo when the need appears.

## Step 4 — Fill placeholders from the facts table

- `AGENTS.md` — identity, stack, critical rules, conventions, structure, quick reference.
  Specific beats exhaustive: link to deeper docs rather than inlining them.
- `.claude/rules/*` — update `<!-- CUSTOMIZE -->` sections and `paths:` frontmatter to the
  real structure; delete rules that cannot apply (e.g. `ui-ux.md` in a backend service).
- `.claude/settings.json` — extend the permission allowlist with this repo's routine
  read-only commands; adapt or remove the example hook.
- Large monorepo? Add nested `AGENTS.md` files in modules where local context differs
  from the root (per-app conventions, per-lib boundaries). Nearest file wins.
- Prune `.claudeignore` entries that cannot apply to this stack (keep its explanatory
  header) and add project-specific generated/secret paths.
- Every unknown: `<!-- TODO(team): <question> -->`.

## Step 5 — Stamp the baseline

Top of the target's `CLAUDE.md`:
`<!-- Skeleton source: <SHA> (<YYYY-MM-DD>) — see docs/UPGRADING.md in ai-dev-starter-kit -->`
Without this line, future `/upgrade` runs have no baseline to diff against.

## Step 6 — Verify: agentic-readiness checklist

From the Agentic Development Guide (§9). Report each as PASS / GAP with one line of evidence:

- [ ] `README.md` current for humans; `AGENTS.md` current for agents
- [ ] Non-negotiable principles recorded (constitution / critical rules)
- [ ] `specs/` scaffold with template and acceptance-criteria model
- [ ] `docs/` with architecture + ADR scaffold
- [ ] Build/test/lint commands documented AND runnable by an agent (actually run them)
- [ ] Relevant skills / MCP servers configured and versioned
- [ ] Nested `AGENTS.md` in complex modules (or explicitly not needed)
- [ ] Explicit boundaries / antipatterns section
- [ ] CI gates before merge (report as GAP if repo has no CI — do not invent one)
- [ ] Written policy: no merge without human review

GAPs are findings for the PR description, not failures to hide.

## Step 7 — Deliver

1. Commit on the feature branch, `docs:` prefix, e.g.
   `docs: adopt AI-assisted development framework (skeleton <SHA>)`.
2. Draft the PR body: facts table summary, tool layers kept/removed, open TODOs as a
   checklist, readiness checklist results.
3. Push and open the PR **only after the user approves**.
