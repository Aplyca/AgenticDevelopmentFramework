# Module: parallel-agents

For teams that run several agent sessions on one repository at once, each on its own task. Any kind
of project: the defaults give each task a worktree, a branch, and a session; ports, containers, and
start commands are there for projects that run a server, and stay off until configured. Proven in a
project where the main checkout dispatched tasks and workers in sibling worktrees did all the work.

## What it adds

| File | Purpose |
|---|---|
| `ops/agent/worktree-new.sh` | A worktree per task: branch `<type>/<slug>`, the env file seeded from the main checkout (when the project has one), optional setup and start commands, and — for projects that run a server — a port reserved under a lock. Idempotent; `--no-start`, `--setup-only`, `--refresh-env`, `--from <ref>` |
| `ops/agent/worktree-ls.sh` | Every worktree's branch and uncommitted changes (and port and state, when worktrees run a server); flags worktrees the scripts didn't set up while they sit on a generated branch or a detached HEAD. `--info` adds what `ENV_INFO_CMD` prints for each |
| `ops/agent/worktree-rm.sh` | Stop (when a stop command is set), remove, and safely delete the branch |
| `ops/agent/worktree.conf` | The project's settings — base branch, env file, setup/start/stop commands, environment info, and the server-only port settings |
| `ops/agent/_worktree-lib.sh` | Shared helpers |
| `.claude/skills/dispatch/SKILL.md` | `/dispatch`: takes every task in the main checkout and hands it to a new session, whose first step creates the task's worktree beside it with the scripts. The `adf` plugin carries its source; a committed install writes it with `build-committed.py` |
| `.worktreeinclude` | The env file Claude Code copies into the worktrees it creates — the desktop app's worktree option, `claude --worktree` |
| `docs/PARALLEL-AGENTS.md` | The dispatcher/worker process, the scripts, shared vs isolated services |

Every task goes through `/dispatch` in the main checkout (decisions 0020, 0021). It names the task
and hands it to a new session — a task chip in the desktop app, a `claude "<prompt>"` command in a
terminal — whose first step creates the task's worktree beside the main checkout with
`worktree-new.sh --no-start`, on a new branch, and moves the session into it. With the module
installed, the core session-context hook announces each session's role — dispatcher in the main
checkout, where a session handed one task is told to create its worktree and move, and worker in any
worktree — and, in a worktree the scripts didn't set up, what it lacks: a task branch name, the env
file, or the scripts' setup. The core `protect-hub.sh`
hook stops file edits in the main checkout once the module is there. The core `/handoff` skill
covers passing work in progress on.

## Install

```bash
cp -R modules/parallel-agents/files/. /path/to/your-repo/
chmod +x ops/agent/*.sh
python3 scripts/build-committed.py /path/to/your-repo --modules parallel-agents   # committed install: /dispatch
```

A repository that already has a `.worktreeinclude` keeps it: add the env file's line to it.

With the packaged install, the `adf` plugin carries `/dispatch` (decision 0020): skip the last line
and type `/adf:dispatch`. The skill stops in a project without the module, so the plugin can carry it
for everyone.

It carries the scripts too, as commands that Claude Code's sessions run by name (decision 0027):
remove the copied `worktree-new.sh`, `worktree-ls.sh`, `worktree-rm.sh`, and `_worktree-lib.sh`, keep
`ops/agent/worktree.conf`, and run `adf-worktree-new`, `adf-worktree-ls`, and `adf-worktree-rm`.
They read the project's `worktree.conf`, stop in a project without `ops/agent/`, and run the
committed script instead where a project keeps one. A developer's own terminal doesn't have them.

**Moved from `scripts/agent/`** (decision 0032): the module's folder was `scripts/agent/` before
operational code moved to `ops/`. The commands and the hooks still read `scripts/agent/` in a project
that hasn't moved it yet; `/adf:upgrade` moves it with `git mv scripts/agent ops/agent`.

## Customize

1. **`ops/agent/worktree.conf`** — at least `BASE_BRANCH`; `ENV_FILE` / `ENV_TEMPLATE` if the
   project has an env file; `SETUP_CMD` for what the git hooks and tests need. Only if each worktree
   runs a server: `PORT_SLOTS`, `ENV_OVERRIDES`, `START_CMD`, `READY_URL`, `STOP_CMD` — and make the
   app read its port from the env file.
2. **`AGENTS.md` § Delivery rules** — replace the "Parallel sessions" line with: *"In the main
   checkout you dispatch; you never work — see `docs/PARALLEL-AGENTS.md`."* Add the three scripts to
   the Quick reference — packaged, by the commands' names: `adf-worktree-new`, `adf-worktree-ls`,
   `adf-worktree-rm`.
3. **`docs/PARALLEL-AGENTS.md`** — record what worktrees share and what a task may copy (§ Shared
   services); optionally set `ENV_INFO_CMD` so `worktree-ls.sh --info` prints what someone needs to
   use each environment.
4. **`.gitignore`** — the env file, and `.claude/worktrees/`.
5. **`.worktreeinclude`** — the same env file as `ENV_FILE`, plus any other gitignored file a worktree
   needs (gitignore syntax). Claude Code copies only files that are gitignored.

## Requirements

`bash`, `git` 2.31+; `curl` only for `READY_URL`. macOS and Linux. `.worktreeinclude` needs a Claude Code
version that supports it.
