# Module: parallel-agents

For teams that run several agent sessions on one repository at once — each on its own task, each
needing its own running app. Proven in a project where the main checkout dispatched tasks and
workers in sibling worktrees did all the work.

## What it adds

| File | Purpose |
|---|---|
| `scripts/agent/worktree-new.sh` | Isolated worktree per task: branch `<type>/<slug>`, env file seeded from the main checkout, a port reserved under a lock, optional setup/start/readiness wait. Idempotent; `--no-start`, `--setup-only`, `--refresh-env`, `--from <ref>` |
| `scripts/agent/worktree-ls.sh` | Every worktree's branch, port, state, and uncommitted changes |
| `scripts/agent/worktree-rm.sh` | Stop, remove, and safely delete the branch |
| `scripts/agent/worktree.conf` | The project's settings — base branch, env file, ports, required variables, setup/start/stop commands |
| `scripts/agent/_worktree-lib.sh` | Shared helpers |
| `.claude/skills/dispatch/SKILL.md` | `/dispatch`: the four-step handoff from the main checkout |
| `docs/PARALLEL-AGENTS.md` | The dispatcher/worker process, the scripts, shared vs isolated services |

With the module installed, the core skeleton's session-context hook announces each session's role
(dispatcher in the main checkout, worker in a worktree).

## Install

```bash
cp -R modules/parallel-agents/files/. /path/to/your-repo/
chmod +x scripts/agent/*.sh
```

## Customize

1. **`scripts/agent/worktree.conf`** — at least `BASE_BRANCH`, `ENV_FILE` / `ENV_TEMPLATE`,
   `REQUIRED_ENV`, and, if each worktree runs the app, `ENV_OVERRIDES`, `SETUP_CMD`, `START_CMD`,
   `READY_URL`, `STOP_CMD`. Make the app read its port (and Compose its project name) from the env
   file. Set `PORT_SLOTS=0` when worktrees don't run anything.
2. **`AGENTS.md` § Delivery rules** — replace the "Parallel sessions" line with: *"In the main
   checkout you dispatch; you never work — see `docs/PARALLEL-AGENTS.md`."* Add the three scripts to
   the Quick reference.
3. **`docs/PARALLEL-AGENTS.md`** — record your shared-vs-isolated services decision and its cost.
4. **`.gitignore`** — the env file, and `.claude/worktrees/`.

## Requirements

`bash`, `git` 2.31+, `curl` (for `READY_URL`). macOS and Linux.
