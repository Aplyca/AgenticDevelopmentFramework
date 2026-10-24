# Parallel Agents — one task, one session, one worktree

Several agent sessions (and people) can work on this repository at the same time without colliding,
because every task gets its own **session, git worktree, folder, branch, and pull request** — and,
when the project needs them, its own copy of the env file and a port of its own.

This guide comes with the parallel-agents module and is the same in every project that installs it.
What a project decides for itself lives in its own files: the settings in `ops/agent/worktree.conf`,
and what its worktrees share in `docs/SHARED-SERVICES.md`.

## Where a session works

| | Main checkout | A task's worktree |
|---|---|---|
| Where | The clone itself | A sibling the scripts create, named after the branch (`../feat-newsletter-signup`) |
| A session here | Starts here, triages its task, and answers from here when the answer only reads. Moves to the task's worktree before any change (§ How a task gets its worktree) | Does the task: spec folder, plan, approval gate, TDD, commits, the draft pull request |
| Never | Edits, commits, or branches | Takes a second, unrelated task |

The session-context hook tells each session where it is and what comes next, and the protect-hub
hook stops every file edit in the main checkout (`HUB_READONLY` in `.claude/hooks/config.sh`). The
same goes for maintenance such as a framework upgrade: it moves to a worktree of its own like any
other task.

## How a task gets its worktree

**Each new task starts a new session.** The developer opens it in the main checkout, or wherever the
desktop app opens it, and gives it the task. That session becomes the task's:

1. **It triages the task,** reading from where it is. The triage says whether the task is a change
   or an answer, whether it runs the app, and names the branch (`<type>/<slug>`).
2. **It moves, when the task needs a worktree:** a change, in any lane, or an answer that runs the
   app, the tests, or the database. An answer that only reads stays where it is, and changes nothing.
   `/adf:dispatch` creates the worktree with `adf-worktree-new <type>/<slug> --no-start` — a
   sibling of the main checkout named after the branch (`feat/newsletter-signup` →
   `../feat-newsletter-signup`), on a new branch from `BASE_BRANCH`, with the env file seeded from
   the main checkout's and, when worktrees run a server, a port reserved. Nothing starts. Then it
   moves the session there:
   - **Desktop app:** `change_directory` to the path the script printed. The approve-worktree-move
     hook approves a worktree of this repository, so Claude Code's permission check doesn't ask, and
     the app then shows the session in that folder. The app's own folder-trust check still asks,
     once per worktree, until the developer trusts the folder that holds the main checkout and its
     worktrees: they open a session on it once and accept the prompt to trust the folder.
   - **Terminal:** `EnterWorktree` with that path.

   `pwd` confirms the move. If it's refused, the session gives the developer the worktree's path and
   stops; the developer opens a session on that folder.
3. **It carries on with the task there,** from where the triage left it. Session-start hooks don't
   run again after the move, so it reads its spec folder itself.

**Another task goes to another session.** When a session that has a task is handed an unrelated
one, or finds one along the way, `/adf:dispatch` offers it a new session — a task chip in the desktop
app, titled with the task (`Show the chosen topics after signup`), or `claude "<prompt>"` to run in
the main checkout — whose prompt is the task and "follow `AGENTS.md`, starting with triage". That
session triages it and moves to its own worktree the same way.

**Claude Code's own worktree is only where a session may start.** The desktop app can start a
session — a chip's always — in a worktree of its own, at its worktree location (`.claude/worktrees/`
by default), on a generated branch. The session triages there and moves to the task's worktree the
same way. Until it moves, it edits and commits nothing and never renames the generated branch: the
app removes that worktree when the session is archived.

**While its pull request is open,** the base branch moves on as other tasks merge. When the task
needs what landed there, or its pull request conflicts, its session brings the base branch in by
`/adf:open-pr sync`. The task's worktree is the scripts',
not the desktop app's, so the app's `sync_with_base_branch` tool doesn't reach it: merge with git.

**When the task's pull request merges,** its session wraps up with `/adf:wrap-up`. It checks that
nothing is left: no uncommitted or unpushed work, no stash, nothing open in `tasks.md`. Then — on the developer's own
word that it merged, or one yes when the merge was only reported — it stops what the task started, removes the worktree and its branch,
updates the base branch here, and archives the session. If anything is left, it lists it and
removes nothing.

The worktree can run the app, because the scripts gave it the env file and its port; the session
starts the environment only when a step needs it.

**Claude Code's own worktrees** — every chip's session in the desktop app, a session started with
its worktree option, or `claude --worktree` — sit at the app's worktree location (inside the main
checkout by default), on a generated branch, with no port or setup. A session that starts in one
moves to the task's worktree beside the main checkout before its work. One already
on a task branch, from before, stays a worker, and the session-context hook names what it lacks. `.worktreeinclude` copies the env file into
them; keep it in step with `ENV_FILE`. The desktop app removes its own worktrees when a session is
archived — or once the pull request merges, with auto-archive on; `adf-worktree-rm` removes the
scripts'.

**Why one task, one session.** The main checkout is shared: an edit, a running process, or a
half-finished change there gets in the way of everyone who starts next, and its base branch takes no
commits. A session reused for an unrelated task mixes two tasks' context, and its branch and pull
request with them. No session sits in the main checkout handing tasks out: the one that takes a task
moves with it. Passing work on later in a task is `/adf:handoff`.

## The scripts

| Command | Does |
|---|---|
| `adf-worktree-new <type>/<slug> [--no-start \| --setup-only] [--refresh-env] [--from <ref>]` | Creates `../<type>-<slug>` on branch `<type>/<slug>` (from `BASE_BRANCH`, or `--from` a tag for a hotfix) and, when the project has an env file, seeds the worktree's copy from the **main checkout's**. Then runs `SETUP_CMD` and `START_CMD` when the project sets them — unless `--no-start` (create only) or `--setup-only` (just what the git hooks and tests need). Rerunning on an existing worktree never touches its branch, and `--refresh-env` rewrites its env file |
| `adf-worktree-ls [--info]` | Lists every worktree: branch, uncommitted changes, and — when worktrees run a server — port and whether it's up. Warns when two claim one port, and flags worktrees the scripts didn't set up while they sit on a generated branch or a detached HEAD. `--info` adds what `ENV_INFO_CMD` prints for each |
| `adf-worktree-rm <type>/<slug> [--force]` | Runs `STOP_CMD` when set, removes the worktree, fast-forwards the main checkout's base branch to origin's (only when it's on that branch with no uncommitted changes), and deletes the branch only if git sees it as merged |

Settings live in `ops/agent/worktree.conf`, and the defaults assume nothing: no ports, no
containers, no commands. **With the packaged install,** the scripts are the `adf` plugin's commands
and `ops/agent/` holds only `worktree.conf`. Claude Code's sessions have the commands; your own
terminal doesn't, so ask Claude to create, list, or remove a worktree. With the committed install,
the scripts sit in `ops/agent/` beside `worktree.conf`. Never create or remove the scripts' worktrees
with raw `git worktree add` — the scripts keep branches, env files, and ports consistent.

**Match the environment to the lane.** Most tasks need only what the git hooks and the tests use
(`--setup-only`); start anything heavier when a test or check actually needs it. Everything a
worktree starts is setup time, memory, and log output the session pays for. The worker decides after
triage; a dispatched session always creates its worktree with `--no-start`.

### Why the details matter

- **Env files are seeded from the main checkout**, never from the worktree the script runs in.
  Otherwise a worker that spawns another worktree would copy its own local experiments, and each hop
  would drift further from the real configuration. Keep secrets correct in the main checkout's env
  file; every worktree inherits them. A project with no env file gets none.
- **Host dependencies** (`SETUP_CMD`): git hooks run on the host. A worker that never needed anything
  else still runs `adf-worktree-new <branch> --setup-only` before its first commit, or the hooks fail —
  and agents never bypass hooks.
- **A change request after the merge gets a fresh branch** (`feat/newsletter-signup-topics`), never
  the feature's old one (feedback before the merge rides the open branch): a branch kept after a
  squash merge carries pre-merge history. The script warns when it reuses a local branch that is
  behind the base.

## When each worktree runs a server

Only for projects where a worktree runs something that listens — a web app, an API. Two copies can't
listen on one port.

**A Docker Compose stack needs nothing reserved** (the docker module's conventions): each published
port is `"127.0.0.1:${<NAME>_PORT:-}:<port>"`, empty in the env file, so Docker picks a free one each
time a service starts, and the worktree's folder — or `COMPOSE_PROJECT_NAME=${PROJECT}` in
`ENV_OVERRIDES` — names its Compose project. Keep `PORT_SLOTS=0`, start it with `START_CMD="make up"`,
and set `ENV_INFO_CMD="make urls"` so `--info` shows where each worktree's services are. Don't pin a
port in the main checkout's env file: every worktree's copy would repeat it. If the main checkout needs
one, blank it for worktrees in `ENV_OVERRIDES` (`APP_PORT=`).

**A server on the host** takes a port the scripts reserve: set `PORT_SLOTS` in `worktree.conf` and make
the app read its port from the env file:

- **Ports derive from the branch name** (stable across restarts) and are **reserved under a lock**.
  "Taken" means listening now *or* reserved in a sibling's env file whose app isn't up yet — checking
  only the first is a race when two agents start together, which is the common case.
- `ENV_OVERRIDES` writes the worktree's own values next to its port — its URL, a per-worktree
  container project name (`${PROJECT}`) — and `READY_URL` makes `adf-worktree-new` wait until the app
  answers.
- **Don't hand-edit** `APP_PORT` or the other generated lines — rerun the script with
  `--refresh-env`. The same flag picks up secrets changed in the main checkout.

## Shared services

Worktrees share whatever their env files point at — a local service, a test account, a sandbox. When
one task needs its own copy of something the others share (because it would change it for everyone),
start that copy in `START_CMD` under the worktree's own name (`${PROJECT}`), stop it and remove its
data in `STOP_CMD`, and point the worktree at it through `ENV_OVERRIDES`. Each copy costs memory and
startup time per worktree. The project records what it shares, what a task may copy, and what one
copy costs in its own `docs/SHARED-SERVICES.md`.

## Seeing your environments

`adf-worktree-ls` lists every worktree at once. `--info` runs `ENV_INFO_CMD` in each
one — the place for whatever someone needs to use that environment: its URLs, the accounts to sign
in with. Derive these every time: environments come and go, so a table committed to the repository
would be wrong by the time anyone read it.

## Claude Code's worktrees

Claude Code also creates worktrees for subagents with `isolation: worktree` and for background
sessions, under `.claude/worktrees/`. Those are its own, short-lived ones; `.claude/worktrees/` stays
in `.gitignore` and `.claudeignore`. A task worktree from the desktop app or `claude --worktree`
lands there too, unless the app's **Worktree location** setting moves it: wherever it is, it's a
worker (§ How a task gets its worktree). Archive sessions you're done with, so their worktrees don't pile up —
`adf-worktree-ls` flags the ones left on a generated branch or a detached HEAD.
