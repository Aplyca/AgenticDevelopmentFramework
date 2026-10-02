# Module: parallel-agents

For teams that run several agent sessions on one repository at once, each on its own task. Any kind
of project: the defaults give each task a worktree, a branch, and a session; ports, containers, and
start commands are there for projects that run a server, and stay off until configured. Proven in a
project where the main checkout dispatched tasks and workers in sibling worktrees did all the work.

## What it adds

| File | Purpose |
|---|---|
| `scripts/agent/worktree-new.sh` | A worktree per task: branch `<type>/<slug>`, the env file seeded from the main checkout (when the project has one), optional setup and start commands, and — for projects that run a server — a port reserved under a lock. Idempotent; `--no-start`, `--setup-only`, `--refresh-env`, `--from <ref>` |
| `scripts/agent/worktree-ls.sh` | Every worktree's branch and uncommitted changes (and port and state, when worktrees run a server); flags task work in Claude Code's own worktrees. `--info` adds what `ENV_INFO_CMD` prints for each |
| `scripts/agent/worktree-rm.sh` | Stop (when a stop command is set), remove, and safely delete the branch |
| `scripts/agent/worktree.conf` | The project's settings — base branch, env file, setup/start/stop commands, environment info, and the server-only port settings |
| `scripts/agent/_worktree-lib.sh` | Shared helpers |
| `.claude/skills/dispatch/SKILL.md` | `/dispatch`: the four-step handoff from the main checkout |
| `docs/PARALLEL-AGENTS.md` | The dispatcher/worker process, the scripts, shared vs isolated services |

With the module installed, the core skeleton's session-context hook announces each session's role:
dispatcher in the main checkout, worker in a worktree, and none in one of Claude Code's own worktrees
(never set up by these scripts — fine for reading, not for task work). The core `protect-hub.sh`
hook stops file edits in the main checkout once the module is there. The core `/handoff` skill covers passing
work in progress on; `/dispatch` is the first handoff of every task.

## Install

```bash
cp -R modules/parallel-agents/files/. /path/to/your-repo/
chmod +x scripts/agent/*.sh
```

## Customize

1. **`scripts/agent/worktree.conf`** — at least `BASE_BRANCH`; `ENV_FILE` / `ENV_TEMPLATE` if the
   project has an env file; `SETUP_CMD` for what the git hooks and tests need. Only if each worktree
   runs a server: `PORT_SLOTS`, `ENV_OVERRIDES`, `START_CMD`, `READY_URL`, `STOP_CMD` — and make the
   app read its port from the env file.
2. **`AGENTS.md` § Delivery rules** — replace the "Parallel sessions" line with: *"In the main
   checkout you dispatch; you never work — see `docs/PARALLEL-AGENTS.md`."* Add the three scripts to
   the Quick reference.
3. **`docs/PARALLEL-AGENTS.md`** — record what worktrees share and what a task may copy (§ Shared
   services); optionally set `ENV_INFO_CMD` so `worktree-ls.sh --info` prints what someone needs to
   use each environment.
4. **`.gitignore`** — the env file, and `.claude/worktrees/`.

## Requirements

`bash`, `git` 2.31+; `curl` only for `READY_URL`. macOS and Linux.
