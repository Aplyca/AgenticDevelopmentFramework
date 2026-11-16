# Module: git-hooks

Local git hooks that apply to **every** git client — people, Claude Code, Cursor, any agent — rather
than only to Claude Code's own hooks.

## What it adds

| File | Purpose |
|---|---|
| `.githooks/pre-push` | Refuses pushes to protected branches (reading the refs being pushed, so `git push origin HEAD:main` is caught too), then runs the fast checks — lint, typecheck, unit tests |

The protected branches come from `PROTECTED_BRANCHES` in `.claude/hooks/config.sh` when that file
exists, so the agent guard and the git hook can't disagree. Otherwise the hook defaults to
`main master`.

## Install

```bash
cp -R modules/git-hooks/files/. /path/to/your-repo/
git config core.hooksPath .githooks   # once per clone — add this line to DEV-SETUP.md
```

Already using a hook manager (Husky, Lefthook, pre-commit)? Copy the protected-branch block into its
`pre-push` instead of switching `core.hooksPath`.

## Customize

Set `FAST_CHECKS` at the top of `pre-push` to your fast layers only (lint, typecheck, unit). Keep
integration, end-to-end, and visual tests in CI: a hook slow enough to annoy is a hook people push
past — and agents are told never to bypass hooks, so a slow one taxes every push.

With the `docker` module, the checks are its make tasks — `make lint`, `make typecheck`,
`make test` (`tier=smoke` with the `unit` module) — never the package manager on the host: they run
where the local mode runs the app, so a Docker-mode checkout needs nothing installed for the hook.
In Docker mode they start the tools container themselves, so the stack needn't be up when you push;
`make test` starts the backing services the tests need, which keep running until `make stop`.

## Limits

A local hook is a convenience, not enforcement: anyone can skip it, and it doesn't exist in a fresh
clone until `core.hooksPath` is set. The real boundary is branch protection on the Git host.
