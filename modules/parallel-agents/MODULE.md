# Module: parallel-agents

For teams that run several agent sessions on one repository at once, each on its own task. Any kind
of project: the defaults give each task a worktree, a branch, and a session; ports, containers, and
start commands are there for projects that run a server, and stay off until configured. Each task
gets its own session, worktree, folder, branch, and pull request.

## What it adds

| File | Purpose |
|---|---|
| `ops/agent/worktree-new.sh` | A worktree per task: branch `<type>/<slug>`, the env file seeded from the main checkout (when the project has one), optional setup and start commands, and — for projects that run a server — a port reserved under a lock. Idempotent; `--no-start`, `--setup-only`, `--refresh-env`, `--from <ref>` |
| `ops/agent/worktree-ls.sh` | Every worktree's branch and uncommitted changes (and port and state, when worktrees run a server); flags worktrees the scripts didn't set up while they sit on a generated branch or a detached HEAD. `--info` adds what `ENV_INFO_CMD` prints for each |
| `ops/agent/worktree-rm.sh` | Stop (when a stop command is set), remove, bring the main checkout's base branch up to date, and safely delete the branch |
| `ops/agent/worktree.conf` | The project's settings — base branch, env file, setup/start/stop commands, environment info, and the server-only port settings |
| `ops/agent/_worktree-lib.sh` | Shared helpers |
| `.claude/skills/dispatch/SKILL.md` | `/dispatch`: after triage, creates the task's worktree beside the main checkout with the scripts and moves this session there; offers another task a new session. The `adf` plugin carries its source; a committed install writes it with `build-committed.py` |
| `.worktreeinclude` | The env file Claude Code copies into the worktrees it creates — the desktop app's worktree option, `claude --worktree` |
| `docs/SHARED-SERVICES.md` | What the project's worktrees share, what a task may copy, and what a copy costs |

A developer starts a new session for each task, and that session takes it (decision 0042). After
triage, a change — or an answer that runs the app, the tests, or the database — goes to `/dispatch`,
which creates the task's worktree beside the main checkout with `worktree-new.sh --no-start`, on a
new branch, and moves the session into it; an answer that only reads stays in the main checkout.
Another task, in a session that already has one, gets a new session: a task chip in the desktop app,
a `claude "<prompt>"` command in a terminal. With the module installed, the core session-context
hook tells each session where it is and what comes next — in the main checkout, triage and then the
move — and, in a worktree the scripts didn't set up, what it lacks: a task branch name, the env
file, or the scripts' setup. The core `protect-hub.sh`
hook stops file edits in the main checkout once the module is there, and the core
`approve-worktree-move.sh` hook lets a session move into a worktree of the repository without a
prompt in the desktop app. The core `/handoff` skill
covers passing work in progress on.

The module's guide, `PARALLEL-AGENTS.md` — one task per session and worktree, the scripts, a server
per worktree, shared and copied services — is the same in every project, so the `adf` plugin carries
it with the framework's reference docs (decision 0044). A packaged project reads the plugin's copy and
links it at the release it pins; a committed one gets `docs/PARALLEL-AGENTS.md` from
`build-committed.py`. The project keeps only what it decides: `ops/agent/worktree.conf` and
`docs/SHARED-SERVICES.md`.

## Install

```bash
cp -R modules/parallel-agents/files/. /path/to/your-repo/
chmod +x ops/agent/*.sh
python3 scripts/build-committed.py /path/to/your-repo --modules parallel-agents   # committed install: /dispatch, the guide
```

A repository that already has a `.worktreeinclude` keeps it: add the env file's line to it.

With the packaged install, the `adf` plugin carries `/dispatch` (decision 0020) and the guide: skip
the last line, type `/adf:dispatch`, and point the mentions of the guide at the release you pin with
`python3 scripts/link-reference-docs.py /path/to/your-repo --packaged v<X.Y.Z>`. The skill stops in a project without the module, so the plugin can carry it
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
2. **`AGENTS.md` § Delivery rules** — replace the "Parallel sessions" line with: *"Each task gets
   its own session, worktree, branch, and pull request: after triage, a change — or an answer that
   runs the app — moves this session to the task's worktree with `/dispatch`; the main checkout takes
   no edits, and another task goes to a new session — see `docs/PARALLEL-AGENTS.md`."* Add the three scripts to
   the Quick reference — packaged, by the commands' names: `adf-worktree-new`, `adf-worktree-ls`,
   `adf-worktree-rm`.
3. **`docs/SHARED-SERVICES.md`** — record what worktrees share, what a task may copy, and what a
   copy costs; optionally set `ENV_INFO_CMD` so `worktree-ls.sh --info` prints what someone needs to
   use each environment.
4. **`.gitignore`** — the env file, and `.claude/worktrees/`.
5. **`.worktreeinclude`** — the same env file as `ENV_FILE`, plus any other gitignored file a worktree
   needs (gitignore syntax). Claude Code copies only files that are gitignored.

## Requirements

`bash`, `git` 2.31+; `curl` only for `READY_URL`. macOS and Linux. `.worktreeinclude` needs a Claude Code
version that supports it.
