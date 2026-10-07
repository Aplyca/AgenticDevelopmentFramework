# 0006: Guardrails that must hold are configuration and code, not prose

- **Status:** accepted; amended by [0022](0022-local-check-before-the-pull-request.md) (the work branch's push and its draft pull request no longer ask; `guard-git.sh` enforces the draft)
- **Date:** 2026-10-01

## Context

Instruction files are context: an agent reads them and usually follows them. Several rules the
framework treated as guarantees turned out to depend on details that silently failed:

- **`AGENTS.md` was never loaded by Claude Code.** When a repository has both a `CLAUDE.md` and an
  `AGENTS.md`, Claude Code reads `CLAUDE.md` *instead of* `AGENTS.md` by default. The skeleton's
  `CLAUDE.md` said it "extends AGENTS.md" but didn't import it — so the workflow, critical rules, and
  conventions in `AGENTS.md` were invisible to Claude Code in every adopting repository.
- **The example hook never ran.** The skeleton's `settings.json` declared a hook as a flat
  `{"matcher", "command"}` entry reading `$CLAUDE_FILE_PATH`. Claude Code requires a nested `hooks`
  array and passes the tool input as JSON on stdin; that variable doesn't exist. An adopting team
  built a useful hook (every environment variable read in code must be declared in the env template)
  on the same pattern — and it never executed.
- **Skill settings were ignored.** Skills declared `user_invocable: true`; the field is
  `user-invocable`, and unknown keys are silently ignored.
- **Rules nobody can enforce from prose:** never `--no-verify`, never push to `main`, never hand-edit
  a lockfile or an existing migration.

## Decision

- `CLAUDE.md` begins with `@AGENTS.md`, the documented way to load both. `GEMINI.md` does the same.
- Rules that must hold every time are **hooks** (`skeleton/.claude/hooks/`), with project values in
  `config.sh`: `guard-git.sh` (no `--no-verify`, no commits or pushes on protected branches),
  `protect-paths.sh` (generated files and append-only history), `check-env-declared.sh` (environment
  variables declared in the template), `session-context.sh` (branch, worktree role, spec folder).
- Outward actions are **`permissions.ask`** rules; `.env` reads are **`permissions.deny`** rules.
- Skill and agent frontmatter use only documented keys.
- **The framework tests its own guardrails.** `evals/static/test-hooks.sh` and `test-modules.sh` feed
  real tool events into the hooks and run the module scripts in throwaway repositories on every pull
  request; `check-skills.sh` fails on flat hook entries, underscore frontmatter keys, a missing
  `@AGENTS.md` import, and links that would break in an adopting repository.

## Consequences

- **Positive:** the rules that matter hold regardless of what the model decides; regressions in the
  configuration itself are caught in CI.
- **Negative / cost:** hooks are shell scripts to maintain and need `jq` or `python3`. They match the
  command text an agent writes, so a deliberately disguised command can get past them — they're
  guardrails against mistakes, not a security boundary; branch protection on the Git host and human
  review remain the real boundaries. Hooks are Claude Code–specific; other tools get the
  `git-hooks` module.

## Alternatives considered

- **Stronger wording in `AGENTS.md`.** Doesn't help when the file isn't loaded, and doesn't bind when
  it is.
- **A symlink `CLAUDE.md → AGENTS.md`.** Works, but loses the Claude-specific layer and breaks on
  Windows checkouts without symlink support; the import is the documented approach.
