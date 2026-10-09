# Parallel Agents — the main checkout dispatches, worktrees do the work

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: running several agent sessions on this repository at once -->

Several agent sessions (and people) can work on this repository at the same time without colliding,
because every task gets its own **git worktree**: its own directory, branch, and session — and, when
the project needs them, its own copy of the env file and a port of its own.

## Two roles

| | Main checkout — **dispatcher** | A worktree — **worker** |
|---|---|---|
| Where | The clone itself | Any linked worktree — normally a sibling the scripts create (`../feat-newsletter-signup`) |
| Does | Takes every task with `/dispatch`: names it and hands it to a new session, which creates the task's worktree and moves into it (§ How a task gets its worktree) | Everything else: triage, spec folder, plan, approval gate, TDD, commits |
| Never | Reads code, analyzes, edits, starts anything | Goes back to the hub to work |
| Network | Reads only (the task) | Whatever the workflow allows — outward actions only when asked |

The session-context hook tells each session which role it has when it starts, and the protect-hub
hook holds the dispatcher to it: a file edit in the main checkout is stopped (`HUB_READONLY` in
`.claude/hooks/config.sh`). The same goes for maintenance such as a framework upgrade — dispatch it
to a worktree of its own like any other task.

## How a task gets its worktree

Every task starts in the main checkout with `/dispatch`, and every task takes the same route:

1. **The dispatcher hands the task over.** It names the task (`<type>/<slug>`) and offers a three-line
   prompt: the task, the branch, and the first step.
   - **Desktop app:** a task chip for the main checkout, started in that folder — not in a new
     worktree — with one click. Its title is the task's title (`Show the chosen topics after
     signup`), without the branch: once the session moves in (step 3), the app shows the worktree as
     its folder, and the folder is named after the branch.
   - **Terminal:** `claude "<prompt>"`, run in the main checkout.
2. **The new session creates the worktree.** It opens in the main checkout, so its first lines say
   `Role: DISPATCHER` — and that a session handed one task and its branch is that task's worker. Its
   first step is `scripts/agent/worktree-new.sh <type>/<slug> --no-start`: a sibling of the main
   checkout named after the branch (`feat/newsletter-signup` → `../feat-newsletter-signup`), on a new
   branch from `BASE_BRANCH`, with the env file seeded from the main checkout's and, when worktrees run
   a server, a port reserved. Nothing starts.
3. **The session moves into it.**
   - **Desktop app:** `change_directory` to the path the script printed. The developer approves the
     folder once, and the session carries on there by itself; the app then shows the session in that
     folder.
   - **Terminal:** `EnterWorktree` with that path.

   `pwd` confirms the move. Session-start hooks don't run again after it, so the worker reads its
   spec folder at triage rather than from the first lines. If the move is refused, the worker gives
   the developer the worktree's path and stops; the developer opens a session on that folder and
   pastes the prompt.

Until the move, the session is in the shared main checkout: it runs the script and nothing else, and
the protect-hub hook stops any edit there.

Whether a task will run the app is its triage's question, after the hand-off. The worktree can,
because the scripts gave it the env file and its port; the worker starts the environment only when a
step needs it.

**Claude Code's own worktrees** — a session started with the desktop app's worktree option, a chip
started in a new worktree, or `claude --worktree` — are workers too, but they sit under
`.claude/worktrees/`, inside the main checkout, on a generated branch, with no port or setup. The
session-context hook names what such a worktree lacks. `.worktreeinclude` copies the env file into
them; keep it in step with `ENV_FILE`. The desktop app removes its own worktrees when a session is
archived — or once the pull request merges, with auto-archive on; `worktree-rm.sh` removes the
scripts'.

**Why split them.** The main checkout is shared: an edit, a running process, or a half-finished
change there gets in the way of everyone who starts next. And analysis done in the hub is thrown
away — the dispatcher can't run the tests, so its conclusions are unverified, and the worker re-reads
everything where it can check it. The dispatcher's context stays cheap; the handoff is explicit, so
a task can be picked up by an agent on any machine. Passing work on later in a task is `/handoff`.

## The scripts

| Command | Does |
|---|---|
| `scripts/agent/worktree-new.sh <type>/<slug> [--no-start \| --setup-only] [--refresh-env] [--from <ref>]` | Creates `../<type>-<slug>` on branch `<type>/<slug>` (from `BASE_BRANCH`, or `--from` a tag for a hotfix) and, when the project has an env file, seeds the worktree's copy from the **main checkout's**. Then runs `SETUP_CMD` and `START_CMD` when the project sets them — unless `--no-start` (create only) or `--setup-only` (just what the git hooks and tests need). Rerunning on an existing worktree never touches its branch, and `--refresh-env` rewrites its env file |
| `scripts/agent/worktree-ls.sh [--info]` | Lists every worktree: branch, uncommitted changes, and — when worktrees run a server — port and whether it's up. Warns when two claim one port, and flags worktrees the scripts didn't set up while they sit on a generated branch or a detached HEAD. `--info` adds what `ENV_INFO_CMD` prints for each |
| `scripts/agent/worktree-rm.sh <type>/<slug> [--force]` | Runs `STOP_CMD` when set, removes the worktree, deletes the branch only if git sees it as merged |

Settings live in `scripts/agent/worktree.conf`, and the defaults assume nothing: no ports, no
containers, no commands. **With the packaged install,** the scripts are the `adf` plugin's commands
and `scripts/agent/` holds only `worktree.conf`: run `adf-worktree-new`, `adf-worktree-ls`, and
`adf-worktree-rm`, with the same arguments. Claude Code's sessions have them; your own terminal
doesn't, so go through `/adf:dispatch`, or ask Claude to list or remove a worktree. Never create or remove the scripts' worktrees with raw `git worktree add` —
the scripts keep branches, env files, and ports consistent.

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
  else still runs `worktree-new.sh <branch> --setup-only` before its first commit, or the hooks fail —
  and agents never bypass hooks.
- **A change request gets a fresh branch** (`feat/newsletter-signup-topics`), never the feature's old
  one: a branch kept after a squash merge carries pre-merge history. The script warns when it reuses
  a local branch that is behind the base.

## When each worktree runs a server

Only for projects where a worktree runs something that listens — a web app, an API. Two copies can't
listen on one port, so set `PORT_SLOTS` in `worktree.conf` and make the app read its port from the
env file:

- **Ports derive from the branch name** (stable across restarts) and are **reserved under a lock**.
  "Taken" means listening now *or* reserved in a sibling's env file whose app isn't up yet — checking
  only the first is a race when two agents start together, which is the common case.
- `ENV_OVERRIDES` writes the worktree's own values next to its port — its URL, a per-worktree
  container project name (`${PROJECT}`) — and `READY_URL` makes `worktree-new.sh` wait until the app
  answers.
- **Don't hand-edit** `APP_PORT` or the other generated lines — rerun the script with
  `--refresh-env`. The same flag picks up secrets changed in the main checkout.

## Shared services

Worktrees share whatever their env files point at — a local service, a test account, a sandbox. When
one task needs its own copy of something the others share (because it would change it for everyone),
start that copy in `START_CMD` under the worktree's own name (`${PROJECT}`), stop it and remove its
data in `STOP_CMD`, and point the worktree at it through `ENV_OVERRIDES`. Each copy costs memory and
startup time per worktree; record here what your project shares, what it copies, and what one copy
costs.
<!-- CUSTOMIZE: what worktrees share, what a task may copy, and what that costs -->

## Seeing your environments

`scripts/agent/worktree-ls.sh` lists every worktree at once. `--info` runs `ENV_INFO_CMD` in each
one — the place for whatever someone needs to use that environment: its URLs, the accounts to sign
in with. Derive these every time: environments come and go, so a table committed to the repository
would be wrong by the time anyone read it.

## Claude Code's worktrees

Claude Code also creates worktrees for subagents with `isolation: worktree` and for background
sessions, under `.claude/worktrees/`. Those are its own, short-lived ones; `.claude/worktrees/` stays
in `.gitignore` and `.claudeignore`. A task worktree from the desktop app or `claude --worktree`
lands there too, unless the app's **Worktree location** setting moves it: wherever it is, it's a
worker (§ How a task gets its worktree). Archive sessions you're done with, so their worktrees don't pile up —
`worktree-ls.sh` flags the ones left on a generated branch or a detached HEAD.
