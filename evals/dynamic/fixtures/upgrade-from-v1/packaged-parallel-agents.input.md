# Input — upgrade from v1: a packaged project with the parallel-agents module moves from v1.4.0 to v2.0.0

<!-- run: plugin-dir v1.4.0 -->

This fixture rehearses the upgrade for a v1 team on the packaged install with the `parallel-agents`
module, whose main checkout is the hub. v1.4.0's `/upgrade` runs only in a worktree of its own, so the
session starts in one, on the upgrade's branch, as `/dispatch` would hand it over. On top of the
packaged case's migrations, the newest release moves the module from `scripts/agent/` to `ops/agent/`.
The worktree scripts, which the `adf` plugin now carries as commands, leave the project.

## Repository context to give the AI

The packaged case's project, with the `parallel-agents` module as v1.4.0 shipped it:
- `scripts/agent/` holds the four worktree scripts and `worktree.conf`;
- `docs/PARALLEL-AGENTS.md` and `.worktreeinclude` are present;
- `/dispatch` comes from the plugin;
- the stamp names the module.

The session's folder is a worktree of the main checkout, on `chore/skeleton-upgrade-<release commit>`.
The main checkout is beside it, with `main` at the adoption commit. The plugin is loaded from v1.4.0
for the session only (`--plugin-dir`); the framework's releases are tagged on GitHub. There is no
remote.

## Prompt to give the AI

```
/aplyca-adf:upgrade
```

## Follow-up

```
Stay on the packaged install. No new modules. The decider is the tech lead. Go ahead with the plan;
don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite upgrade-from-v1 --cases packaged-parallel-agents --models sonnet`.
2. `inspect.sh` checks the end state, with `check-packaged.sh` at the newest release, and prints ✓ or ✘.
3. Compare against `packaged-parallel-agents.expected.md`.
