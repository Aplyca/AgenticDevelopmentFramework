# Setup Guide

## Quick start (5 minutes)

### 1. Copy the skeleton into your project

```bash
cp -r skeleton/. your-project/
cd your-project
```

This copies everything your project needs: `.claude/`, `specs/`, `docs/`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `README.md`, `CONTRIBUTING.md`, and `.claudeignore`.

**Remove tool-specific files you don't need:**
- Not using Claude Code? Delete `CLAUDE.md` and `.claude/` (agents, skills, rules are Claude Code features)
- Not using Antigravity/Gemini? Delete `GEMINI.md` and `.agents/` (the `.agents/skills` symlink points to `.claude/skills` for Antigravity)
- Not using Cursor? Delete `.cursor/` (rule files mirror `.claude/rules/` in Cursor's `.mdc` format)
- `AGENTS.md` works with all AI tools — always keep it

### 2. Customize AGENTS.md

`AGENTS.md` is the [open standard](https://agents.md) read by all AI coding tools (Claude Code, Cursor, Copilot, Windsurf, Aider, etc.). Open it and replace all `[bracketed placeholders]`:

- **Project identity**: what the project is, its stage, its stack
- **Critical rules**: your non-negotiable rules (test ports, framework patterns)
- **Coding conventions**: naming, file organization specific to your project
- **Project structure**: your actual directory layout. In a monorepo, also add nested `AGENTS.md` files in modules whose conventions differ from the root — agents read the nearest file; nearest wins.
- **Quick reference**: your dev/test/build commands

`CLAUDE.md` layers Claude Code-specific features (agents, skills, path-scoped rules) on top of AGENTS.md. It requires minimal customization — update it only if you add custom agents or skills.

`GEMINI.md` layers Antigravity/Gemini-specific features on top of AGENTS.md. Customize it if your team uses Antigravity, or delete it if not.

### 3. Customize README.md

Open `README.md` and replace `[bracketed placeholders]` with your project name, stack, setup commands, and structure.

### 4. Customize rules

The rules in `.claude/rules/` are split into two categories:

**Universal (ready to use, no changes needed):**
- `code-quality.md` ��� naming, typing, error handling, principles
- `testing.md` — test structure, mocking, test data
- `security.md` — injection, credentials, validation
- `git-workflow.md` — commits, branches, PRs

**Customizable (update the `<!-- CUSTOMIZE -->` sections):**
- `architecture.md` — your layers, data flow, file paths
- `ui-ux.md` — your color system, typography, patterns
- `deployment.md` — your environments, ports, Docker setup
- `performance.md` — your bundle targets, optimization priorities
- `observability.md` — your logging, monitoring, alerting

For each customizable file:
1. Update the `paths:` frontmatter to match your project structure
2. Replace `<!-- CUSTOMIZE -->` sections with your specifics
3. Remove anything that doesn't apply

### 5. Customize hooks

Open `.claude/settings.json` and update the enforcement hooks for your project. The included example blocks test files from using the dev port — adapt it to your port assignments.

### 6. Fill in documentation templates

Open each file in `docs/` and replace `[bracketed placeholders]` with your project details. Start with:
- `docs/CONSTITUTION.md` — your project's non-negotiable principles (5-10, short). Specs are gate-checked against this before approval; keep day-to-day conventions out of it.
- `docs/SPEC-MODEL.md` — the multi-perspective spec model (read it; usually no edits needed unless your team has different role names or different mandatory sections)
- `docs/ARCHITECTURE.md` — system context, components, tech stack rationale
- `docs/security/SECURITY.md` — auth scheme, data classification, threat model
- `docs/infrastructure/OVERVIEW.md` — platform, environments, CI/CD, monitoring

Each customizable doc starts with a metadata header — `<!-- owner: … · last_updated: … · scope: … -->`. Fill it in and keep `last_updated` current on every meaningful edit: it lets agents (and humans) judge whether a doc is worth reading and who to ask when it's stale. Context without an owner rots silently.

#### Customizing the spec model (optional)

The spec model in `docs/SPEC-MODEL.md` and `specs/_template.md` ships with sensible defaults for web/website projects. If your team needs to adjust:

- **Role names** — the template uses generic role labels (`client`, `senior-dev`, `designer`, `tech-lead`, `qa`, etc.). Replace with your team's actual role titles in `specs/_template.md` and `docs/SPEC-MODEL.md`.
- **Mandatory sections** — defaults are Business, Functional, Out of scope, Security, Testing, Documentation, Clarifications (plus Accessibility for UI, Privacy for personal data). To add or remove mandatory sections, update step 9 of `.claude/skills/write-spec/SKILL.md` and the corresponding table in `docs/SPEC-MODEL.md`.
- **Section list** — to add or remove optional sections (e.g., add a "Compliance" section for regulated industries), update both `specs/_template.md` and `docs/SPEC-MODEL.md`.
- **Conditional rules** — to change when sections become required (e.g., make Localization mandatory if you're a multi-region shop), update step 9 of `.claude/skills/write-spec/SKILL.md`.

### 7. Commit

```bash
git add .claude/ .agents/ .cursor/ AGENTS.md CLAUDE.md GEMINI.md README.md CONTRIBUTING.md specs/ docs/ .claudeignore
git commit -m "docs: add AI-assisted development configuration"
```

Every team member who clones the repo now gets identical Claude Code behavior.

## Verifying the setup

Run `claude` in your project directory and try:

```
@spec-writer draft a spec for [any small feature]
@code-reviewer review [any file in your project]
@architect review the data flow for [any feature]
```

If agents reference your project specifics (from CLAUDE.md), the setup is working.

## Updating

To pull newer framework changes into a project that already adopted an earlier skeleton version, follow [docs/UPGRADING.md](./UPGRADING.md). It documents the three-bucket file taxonomy (safe-to-overwrite, merge-required, project-owned), the upgrade procedure with `OLD_SHA → NEW_SHA` discipline, and an AI-assisted upgrade pattern that preserves the plan-then-execute gate.

## What NOT to customize

- **Agent definitions** (`agents/`) — these are generic by design. They learn your project from CLAUDE.md and rules. If you modify them, they lose portability.
- **Spec workflow skill** (`skills/spec-workflow/`) — the process is universal. Project-specific workflow details go in CLAUDE.md.
