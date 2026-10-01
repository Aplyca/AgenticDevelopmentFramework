# Optional modules

The skeleton is the core every adopting repository gets. Modules are **opt-in additions** for
practices that depend on the Git host or on how a team runs its agents — useful, proven in real
projects, but not universal.

| Module | Adds | Use it when |
|---|---|---|
| [`github/`](github/MODULE.md) | Pull request template (traceability, verified / not verified, constitution gates), issue forms that redirect requirements to the tracker, a secret-scan workflow, a base-branch policy check, `.gitleaks.toml` | The repository lives on GitHub |
| [`git-hooks/`](git-hooks/MODULE.md) | A tool-agnostic `pre-push` hook that refuses pushes to protected branches and runs the fast checks | You want local gates that apply to every git client, not only to Claude Code |
| [`parallel-agents/`](parallel-agents/MODULE.md) | Worktree scripts (`worktree-new`, `-rm`, `-ls`) that give every task its own worktree, branch, env file, and port; the `/dispatch` skill; the dispatcher/worker process doc | Several agent sessions work on the same repository at once, and each needs a running app |

## Installing a module

Each module has a `MODULE.md` (what it adds, prerequisites, how to customize — not copied) and a
`files/` tree that mirrors the target repository's layout:

```bash
cp -R modules/<module>/files/. /path/to/your-repo/
```

Nothing is overwritten that you didn't mean to — check `git status` and merge any file that already
existed (a pull request template, for example). Then follow the module's customization steps and
record the module in the `Skeleton source` line at the top of `CLAUDE.md`
(`· modules: github, parallel-agents`) so `/upgrade` knows to update it.

The framework's `/adopt` skill offers each module during adoption and installs the ones you choose.
