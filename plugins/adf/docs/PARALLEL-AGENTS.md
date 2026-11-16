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
| Where | The clone itself | A folder the scripts create in its `.claude/worktrees/`, named after the branch (`.claude/worktrees/feat-newsletter-signup`) |
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
   folder in the main checkout's `.claude/worktrees/` named after the branch (`feat/newsletter-signup`
   → `.claude/worktrees/feat-newsletter-signup`), on a new branch from `BASE_BRANCH`, with the env
   file seeded from the main checkout's and, when worktrees run a server, a port reserved. Nothing
   starts. Then it moves the session there:
   - **Desktop app:** `change_directory` to the path the script printed. The approve-worktree-move
     hook approves a worktree of this repository, so Claude Code's permission check doesn't ask, and
     the app then shows the session in that folder.
   - **Terminal:** `EnterWorktree` with that path.

   `pwd` confirms the move. If it's refused, the session gives the developer the worktree's path and
   stops; the developer opens a session on that folder.
3. **It carries on with the task there,** from where the triage left it, to delivery: the task's
   phases never move to another session (`COST-MODEL.md` § Between phases). Session-start hooks
   don't run again after the move, so it reads its spec folder itself.

**Another task goes to another session.** When a session that has a task is handed an unrelated
one, or finds one along the way, `/adf:dispatch` offers it a new session — a task chip in the desktop
app, titled with the task (`Show the chosen topics after signup`), or `claude "<prompt>"` to run in
the main checkout — whose prompt is the task and "follow `AGENTS.md`, starting with triage". That
session triages it and moves to its own worktree the same way.

**Claude Code's own worktree is only where a session may start.** The desktop app can start a
session — a chip's always — in a worktree of its own, at its worktree location (`.claude/worktrees/`
by default), on a generated branch. The session triages there and moves to the task's worktree the
same way. Until it moves, it edits and commits nothing and never renames the generated branch: the
app reuses that folder for a later session once this one is archived.

**While its pull request is open,** the base branch moves on as other tasks merge. When the task
needs what landed there, or its pull request conflicts, its session brings the base branch in by
`/adf:open-pr sync`. The task's worktree is the scripts',
not the desktop app's, so the app's `sync_with_base_branch` tool doesn't reach it: merge with git.

**When the task's pull request merges,** its session wraps up with `/adf:wrap-up`. It checks that
nothing is left: no uncommitted or unpushed work, no stash, nothing open in `tasks.md`. Then — on the developer's own
word that it merged, or one yes when the merge was only reported — it stops what the task started, updates the base branch here,
starts the follow-ups the developer keeps, removes the worktree and its branch, and archives the session. If anything is left, it lists it and
removes nothing.

**An answer that only reads ends in the main checkout,** and `/adf:wrap-up` closes its session up
there: it checks what that session left — a stash it made, a command it started, a follow-up it
promised — posts the delivered update for a tracker task, and archives the session. It switches,
pulls, and deletes no branch, and leaves anything another session or the developer made.

The worktree can run the app, because the scripts gave it the env file and its port; the session
starts the environment only when a step needs it.

**Claude Code's own worktrees** — every chip's session in the desktop app, a session started with
its worktree option, or `claude --worktree` — sit at the app's worktree location (`.claude/worktrees/`
by default), on a generated branch, with no port or setup. A session that starts in one moves to the
task's worktree before its work. One already on a task branch the scripts didn't create stays a
worker, and the session-context hook names what it lacks. `.worktreeinclude` copies the env file
into them; keep it in step with `ENV_FILE`. The desktop app takes its own worktrees back when a
session is archived — or once the pull request merges, with auto-archive on — and reuses their
folders for later sessions; `adf-worktree-rm` removes the scripts'.

**Why one task, one session.** The main checkout is shared: an edit, a running process, or a
half-finished change there gets in the way of everyone who starts next, and its base branch takes no
commits. A session reused for an unrelated task mixes two tasks' context, and its branch and pull
request with them. No session sits in the main checkout handing tasks out: the one that takes a task
moves with it. Passing work on later in a task is `/adf:handoff`.

## The scripts

| Command | Does |
|---|---|
| `adf-worktree-new <type>/<slug> [--no-start \| --setup-only] [--refresh-env] [--from <ref>]` | Creates `.claude/worktrees/<type>-<slug>` on branch `<type>/<slug>` (from `BASE_BRANCH`, or `--from` a tag for a hotfix) and, when the project has an env file, seeds the worktree's copy from the **main checkout's**. Then runs `SETUP_CMD` and `START_CMD` when the project sets them — unless `--no-start` (create only) or `--setup-only` (just what the git hooks and tests need). Rerunning on an existing worktree never touches its branch, and `--refresh-env` rewrites its env file |
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
- **What the git hooks need** (`SETUP_CMD`): git hooks run on the host. A worker that never needed
  anything else still runs `adf-worktree-new <branch> --setup-only` before its first commit, or the
  hooks fail — and agents never bypass hooks. With the `docker` module, `SETUP_CMD` installs nothing
  on the host: the hooks run make tasks, and in Docker mode those run in the app's container, so a
  worker whose hooks run checks starts its environment (`adf-worktree-new <branch>`) before it pushes.
- **A task's worktree sits inside the main checkout** (decision 0082), so a tool that looks in parent
  folders can reach the main checkout's files. Most stop at the worktree's own configuration. Three
  don't, and each has a fix:
  - Packages and commands: a worktree without its own dependencies uses the main checkout's, because
    Node resolves packages, and `npm run` finds commands, in every parent folder. Run the tools in the
    container (the docker module), or, without it, install in the worktree (`SETUP_CMD`,
    `--setup-only`).
  - TypeScript before 6.0 adds every parent folder's `node_modules/@types` to a project: list them in
    `compilerOptions.types`, or upgrade.
  - ESLint's `.eslintrc` merges the configs of parent folders: set `"root": true`, or move to the flat
    config (`eslint.config.js`).
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
  "Taken" means listening now *or* reserved in another worktree's env file whose app isn't up yet — checking
  only the first is a race when two agents start together, which is the common case.
- `ENV_OVERRIDES` writes the worktree's own values next to its port — its URL, a per-worktree
  container project name (`${PROJECT}`) — and `READY_URL` makes `adf-worktree-new` wait until the app
  answers.
- **Claude Desktop's Browser lists the app** on a new tab, as `app · http://localhost:<port>` on the
  worktree's port: `adf-worktree-new` writes the row to the worktree's `.claude/launch.json`, where
  git ignores that file, and keeps any entries of the developer's own. A Docker Compose stack gets a
  row per labeled web service from `make up` instead.
- **Don't hand-edit** `APP_PORT` or the other generated lines — rerun the script with
  `--refresh-env`. The same flag picks up secrets changed in the main checkout.

## Shared services

Worktrees share whatever their env files point at — a local service, a test account, a sandbox. When
one task needs its own copy of something the others share (because it would change it for everyone),
start that copy in `START_CMD` under the worktree's own name (`${PROJECT}`), stop it and remove its
data in `STOP_CMD`, and point the worktree at it through `ENV_OVERRIDES`. Each copy costs memory and
startup time per worktree. The project records what it shares, what a task may copy, and what one
copy costs in its own `docs/SHARED-SERVICES.md`.

A shared service that mounts files from a checkout — a local backend serving the project's functions
or migrations — reads them from the checkout that started it. Start it from the main checkout, which
no task removes: started from a worktree, it serves an empty folder once that worktree is removed, and
another task's edits never reach it.

## Seeing your environments

`adf-worktree-ls` lists every worktree at once. `--info` runs `ENV_INFO_CMD` in each
one — the place for whatever someone needs to use that environment: its URLs, the accounts to sign
in with. Derive these every time: environments come and go, so a table committed to the repository
would be wrong by the time anyone read it.

## Claude Code's worktrees

Claude Code also creates worktrees for subagents with `isolation: worktree` and for background
sessions, under `.claude/worktrees/`, beside the tasks' worktrees. Those are its own, short-lived ones;
`.claude/worktrees/` stays in `.gitignore` and `.claudeignore`. A session the desktop app or
`claude --worktree` starts in a worktree of its own lands there too, unless the app's **Worktree
location** setting moves it: wherever it is, the session moves to its task's worktree before its work
(§ How a task gets its worktree). Archive sessions you're done with, so their worktrees don't pile up —
`adf-worktree-ls` flags the ones left on a generated branch or a detached HEAD.
