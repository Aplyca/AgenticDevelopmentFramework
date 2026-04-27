---
paths:
  - "**/*"
---

# Git Workflow Rules

## Commits
- Concise messages in imperative mood ("add login flow", not "added login flow" or "adds login flow").
- Explain *why* the change was made, not *what* changed (the diff shows the what).
- One logical change per commit. Don't mix unrelated changes in a single commit.

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
