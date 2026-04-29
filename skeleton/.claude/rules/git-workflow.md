---
paths:
  - "**/*"
---

# Git Workflow Rules

## Commits
- Concise messages in imperative mood ("add login flow", not "added login flow" or "adds login flow").
- Explain *why* the change was made, not *what* changed (the diff shows the what).
- One logical change per commit. Don't mix unrelated changes in a single commit.

## Commit prefixes (feature-development workflow)

This workflow uses these prefixes in a specific order during feature development:

| Prefix | When | What it captures |
|---|---|---|
| `spec:` | Phase 1 — committed BEFORE tests | Intent — what to build, scoped by the diff |
| `test:` | Phase 2 — committed BEFORE docs and code | Verification contract — failing tests that define "done" |
| `docs:` | Phase 3 — committed BEFORE code (when pre-impl docs exist) | Initial design intent for usage — admin guides, API specs, end-user copy. Drives implementation thinking; updated during Phase 4 when reality moves |
| `docs:` | Phase 4 — additional commits during implementation | Doc reconciliations when implementation surfaces meaningful divergence from the original docs (preferred over folding into `feat:` for non-trivial revisions) |
| `feat:` / `fix:` | Phase 4 — committed AFTER spec, tests, docs | Execution — code that makes the tests pass; small doc fixes can fold in here (called out in the message) |
| `docs:` | Phase 5 (optional follow-up) | Post-implementable backfill — runbooks, JSDoc, troubleshooting that needed real code |
| `refactor:` | Standalone | Structural change with no behavior change |

## What NOT to commit
- Generated files: build output, compiled assets, cache directories.
- Dependency directories: `node_modules/`, `venv/`, `vendor/` (unless vendoring is the project convention).
- Environment files: `.env`, `.env.local`, any file containing credentials.
- Test artifacts: screenshots, reports, coverage output (unless the project explicitly tracks them).
- IDE/editor files: `.idea/`, `.vscode/settings.json` (unless shared team config).

## Branch discipline
- Work on feature branches, not directly on main/master.
- Keep branches short-lived. Merge frequently to avoid large conflicts.
- Delete branches after merging.

## Pull requests
- PR title: short, descriptive, under 70 characters.
- PR body: summary of what changed and why, test plan, link to spec if applicable.
- One logical change per PR. Don't bundle unrelated work.
