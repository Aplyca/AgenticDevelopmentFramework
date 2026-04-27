---
name: init-project
description: Initialize a new project with AI-assisted development configuration. Use when setting up a project for the first time.
user_invocable: true
argument-hint: "[project-name]"
---

# Initialize Project

Set up the AI-assisted development configuration for this project. This is Workflow 1 (Project Setup) — done once at project start.

## Steps

### Configure AI tools

1. **Understand the project** — Read any existing README, package.json, or equivalent to understand the stack, purpose, and current state.

2. **Customize AGENTS.md** — This is the universal AI instructions file read by all AI tools (Claude Code, Cursor, Copilot, Windsurf, etc.). Replace all `[bracketed placeholders]` with the project's actual details:
   - Project name and description
   - Tech stack
   - Critical rules specific to this project
   - Coding conventions
   - Project structure
   - Dev/test/build commands

3. **Review CLAUDE.md** — This file layers Claude Code-specific features (agents, skills, path-scoped rules) on top of AGENTS.md. It requires minimal customization unless you add custom agents or skills.

3. **Customize rules** — Go through each file in `.claude/rules/` that has `<!-- CUSTOMIZE -->` markers:
   - `architecture.md` — update layers, file paths, data flow
   - `ui-ux.md` — update color system, typography, patterns (if frontend project)
   - `deployment.md` — update environments, ports, infra files
   - `performance.md` — update bundle targets, dependency paths
   - `observability.md` — update logging, monitoring setup
   - Update `paths:` frontmatter in each to match the project's file structure

4. **Set up hooks** — Update `.claude/settings.json` with project-specific enforcement rules (e.g., test port validation).

5. **Customize README** — Open `README.md` and replace `[bracketed placeholders]` with project details.

### Write initial technical documentation

These docs serve as persistent context for AI agents throughout the project. They're not just for humans — agents read them before every design review, security audit, and architecture decision. Invest time in them now.

6. **Architecture overview** — Open `docs/ARCHITECTURE.md` and fill in:
   - System context (what the system does, who uses it, what it integrates with)
   - Key components and their responsibilities
   - Data flow between components
   - Tech stack with rationale (why each technology was chosen)
   - Non-functional requirements (performance, availability, security targets)

7. **Security baseline** — Open `docs/security/SECURITY.md` and fill in:
   - Authentication and authorization scheme
   - Data classification (what's sensitive, what's public)
   - Input validation and output encoding approach
   - Secrets management strategy
   - Known threat model (even a rough STRIDE analysis helps)

8. **Infrastructure overview** — Open `docs/infrastructure/OVERVIEW.md` and fill in:
   - Platform and hosting (PaaS, containers, serverless)
   - Environments (dev, staging, production)
   - CI/CD pipeline
   - Monitoring and alerting setup

9. **Glossary** — Open `docs/GLOSSARY.md` and add the domain terms that the team, specs, and UI should use consistently.

### Finalize

10. **Create first spec** — If there's an existing feature to document, write the first spec using `specs/_template.md` to establish the pattern for the team.

11. **Commit everything** — Commit all configuration and documentation:
    ```
    docs: initialize project configuration and technical documentation
    ```

12. **Verify** — Run a quick test: ask `@code-reviewer` to review any existing file. If it references project-specific conventions from CLAUDE.md, the setup is working.
