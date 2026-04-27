# [PROJECT NAME]

<!-- CUSTOMIZE: Replace everything in [brackets] with your project details -->
<!-- This file follows the AGENTS.md open standard (https://agents.md) -->
<!-- It is read automatically by: Claude Code, Cursor, GitHub Copilot, Antigravity, Windsurf, Aider, and others -->
<!-- Tool-specific features are in: CLAUDE.md (Claude Code) and GEMINI.md (Antigravity/Gemini) -->

## Project identity

[One paragraph describing what this project is, its purpose, and its current stage (PoC, MVP, production).]

Stack: [List your tech stack. Example: Next.js 15, React 19, TypeScript, PostgreSQL, Redis.]

## Development workflows

### Feature development (new features, modifications, bug fixes)

1. **Check existing specs** — Read `specs/` before starting.
2. **Write or update the spec** — Get approval before coding.
3. **Architecture review** — For non-trivial changes. Skip for small changes.
4. **Commit the spec** — Commit approved spec BEFORE implementation (`spec:` prefix). This creates a clean diff that scopes the implementation.
5. **Implement** — Read `git diff` of the spec commit to know the exact scope.
6. **Test** — Every acceptance criterion becomes at least one test.
7. **Review** — Code quality, security, UX as needed.
8. **Commit and deploy** — `feat:` or `fix:` prefix.

### Hotfix (production-breaking bugs only)

1. Fix the issue directly
2. Write a regression test
3. Commit and deploy (`fix:` prefix)
4. Backfill the spec afterward if behavior changed

Spec format: use the template at `specs/_template.md`. Specs contain business requirements and acceptance criteria — not implementation details, code snippets, or file paths.

## Critical rules

<!-- CUSTOMIZE: Add your project's non-negotiable rules here. Examples: -->
- [Testing port rule: "Tests run on port XXXX — never YYYY"]
- [Framework-specific rules: "Never read localStorage in useState initializers"]
- [Architecture rules: "All pages are client components" or "Use SSR for all pages"]

## AI interaction rules

- **Research before acting** — read existing code, specs, and rules before proposing changes. When a task is ambiguous, ask rather than guess.
- **Evaluate honestly** — when the developer proposes an approach, assess it critically. Flag concerns and suggest alternatives if you see a better path.
- **Flag risks proactively** — if an approach introduces security risks, breaking changes, or tech debt, say so even if not asked. Identify blast radius before proceeding.
- **Right-size responses** — simple task → just do it. Implementation with clear spec → follow it. Design decision → present options with trade-offs. "Deeply research" → thorough multi-perspective analysis.
- **Never do silently** — don't add features, dependencies, or abstractions beyond what was asked. Don't make irreversible changes without confirmation. Don't skip workflow steps.

## Coding conventions

<!-- CUSTOMIZE: Add your project's coding conventions here. These apply regardless of which AI tool is used. -->

| Element | Convention |
|---|---|
| Files (components/classes) | PascalCase |
| Files (utilities/hooks) | camelCase |
| Functions/methods | camelCase |
| Constants | UPPER_SNAKE_CASE |
| CSS classes / URLs | kebab-case |

Adapt to your language's idioms (e.g., snake_case for Python, PascalCase for Go exports).

## Commit message prefixes

| Prefix | When to use |
|---|---|
| `spec:` | Spec changes (new or updated) — committed before implementation |
| `docs:` | Documentation changes (architecture, security, ADRs) |
| `feat:` | New feature implementation |
| `fix:` | Bug fix implementation |
| `refactor:` | Code restructuring without behavior change |
| `test:` | Test additions or updates |

## Project documentation

Documentation lives in `docs/`. Read the relevant docs before making decisions in that area.

<!-- CUSTOMIZE: Update paths to match your actual documentation structure -->

| Document | Read when... |
|---|---|
| `docs/ARCHITECTURE.md` | Designing features, reviewing data flow, choosing patterns |
| `docs/architecture/decisions/` | Making or revisiting a technical decision (ADRs) |
| `docs/security/SECURITY.md` | Touching auth, data handling, API endpoints, or dependencies |
| `docs/infrastructure/OVERVIEW.md` | Changing deployment, CI/CD, environments, or scaling |
| `docs/getting-started/DEV-SETUP.md` | Setting up or troubleshooting the dev environment |
| `docs/GLOSSARY.md` | Writing specs, docs, or user-facing text — use consistent terms |

When documentation contradicts the code, investigate which is correct. Update the one that's wrong.

## Project structure

<!-- CUSTOMIZE: Replace with your project's actual structure -->
```
specs/               Feature specs (business requirements)
src/                 Application source code
tests/               Test files
docs/                Documentation
```

## Quick reference

<!-- CUSTOMIZE: Replace with your project's commands -->
- Dev server: `[command]` (port [XXXX])
- Tests: `[command]` (port [YYYY], auto-started)
- Type check: `[command]`
- Lint: `[command]`
