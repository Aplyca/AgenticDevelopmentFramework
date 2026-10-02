# Parallel Agents — the main checkout dispatches, worktrees do the work

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: running several agent sessions on this repository at once -->

Several agent sessions (and people) can work on this repository at the same time without colliding,
because every task gets its own **git worktree**: its own directory, branch, env file, port, and —
when the app runs in containers — its own Compose project.

## Two roles

| | Main checkout — **dispatcher** | A worktree — **worker** |
|---|---|---|
| Where | The clone itself | A sibling of the main checkout, named after the branch: `../feat-newsletter-signup` |
| Does | Names the task, creates the worktree, hands off (`/dispatch`) | Everything else: triage, spec folder, plan, approval gate, TDD, commits |
| Never | Reads code, analyzes, edits, starts environments | Goes back to the hub to work |
| Network | Reads only (the task, `git fetch`) | Whatever the workflow allows — outward actions only when asked |

The session-context hook tells each session which role it has when it starts.

**Why split them.** The main checkout is shared: an edit or a dev server there blocks everyone who
starts next. And analysis done in the hub is thrown away — the dispatcher can't run the app or the
tests, so its conclusions are unverified, and the worker re-reads everything where it can check it.
The dispatcher's context stays cheap; the handoff is explicit, so a task can be picked up by an
agent on any machine.

## The scripts

| Command | Does |
|---|---|
| `scripts/agent/worktree-new.sh <type>/<slug> [--no-start \| --setup-only] [--refresh-env] [--isolated] [--from <ref>]` | Creates `../<type>-<slug>` on branch `<type>/<slug>` (from `BASE_BRANCH`, or `--from` a tag for a hotfix), seeds its env file from the **main checkout's** file, reserves a port, writes the override block; then runs setup and start and waits until the app answers — unless `--no-start` (create only) or `--setup-only` (just what the git hooks need). `--isolated` gives the worktree its own services (below). Rerunning on an existing worktree never touches its branch: it sets up and starts it, and `--refresh-env` rewrites its env file (keeping its port while no sibling claims it) |
| `scripts/agent/worktree-ls.sh [--info]` | Lists every worktree: branch, port, whether something is listening, whether its services are its own or shared, uncommitted changes — and warns when two claim the same port, or when task work sits in one of Claude Code's own worktrees. `--info` adds each environment's app URL and what `ENV_INFO_CMD` prints for it (service endpoints, the accounts to sign in with) |
| `scripts/agent/worktree-rm.sh <type>/<slug> [--force]` | Stops the environment (`STOP_CMD`) and, for an isolated worktree, its own services and their data (`ISOLATED_STOP_CMD`); removes the worktree; deletes the branch only if git sees it as merged |

**Match the environment to the lane.** A fast-lane fix usually needs only `--setup-only` — the
dependencies the git hooks and unit tests use — not a running app or database; start the app when a
test or check actually needs it. Schema work — a migration, a reset, tests that rewrite shared
data — gets its own services: `worktree-new.sh <branch> --isolated`. Every service a worktree starts
is setup time, memory, and log output the session pays for. The worker decides this after triage;
the dispatcher always creates with `--no-start`.

Settings live in `scripts/agent/worktree.conf`. Never create or remove agent worktrees with raw
`git worktree add` / `docker compose` — the scripts keep ports, env files, and projects consistent.

### Why the details matter

- **Env files are seeded from the main checkout**, never from the worktree the script runs in.
  Otherwise a worker that spawns another worktree would copy its own port and local experiments, and
  each hop would drift further from the real configuration. Keep secrets correct in the main
  checkout's env file; every worktree inherits them.
- **Ports derive from the branch name** (stable across restarts) and are **reserved under a lock**.
  "Taken" means listening now *or* reserved in a sibling's env file whose app isn't up yet — checking
  only the first is a race when two agents start together, which is the common case.
- **Don't hand-edit** `APP_PORT` or the project name in a worktree's env file — rerun the script
  with `--refresh-env`. The same flag picks up secrets changed in the main checkout.
- **Host dependencies** (`SETUP_CMD`): even when the app runs in containers, git hooks run on the
  host. A worker that never needed the environment still runs `worktree-new.sh <branch> --setup-only`
  before its first commit, or the hooks fail — and agents never bypass hooks.
- **A change request gets a fresh branch** (`feat/newsletter-signup-topics`), never the feature's old
  one: a branch kept after a squash merge carries pre-merge history. The script warns when it reuses
  a local branch that is behind the base.

## Shared vs isolated services

Worktrees share whatever their env files point at — usually one local database. That's fine for UI
work and wrong for anything that changes the schema. With one shared database:

- **a sibling's migration blocks yours** — the migration tool finds an applied version it has no
  file for and stops, and its suggested repair would disown the sibling's work;
- **a reset is off limits** — the documented way to verify a migration destroys every other
  worktree's data;
- **test data collides** — rows one worker rewrites are rows another asserts against.

So shared is the default, and **`--isolated` gives one worktree its own copy** — run on request,
when triage says the task touches the schema or needs a clean reset. The settings in
`scripts/agent/worktree.conf`:

| Setting | Does |
|---|---|
| `ISOLATED_PORTS` | How many ports the services bind. A worktree owns a block of `PORT_STEP` ports from `${PORT_BASE}`; its app listens at `PORT_BASE + PORT_OFFSET`, and its services take `${PORT_0}`, `${PORT_1}`, … below that — checked free in the same locked step that claims the app's port |
| `ISOLATED_ENV_OVERRIDES` | The worktree's env lines pointing the app at its own services, e.g. `DATABASE_URL=…:${PORT_2}/…` |
| `ISOLATED_SETUP_CMD` | Files only — runs even with `--no-start`, so the worker can start the services later. Keep it idempotent |
| `ISOLATED_START_CMD` | Starts them, before `START_CMD` |
| `ISOLATED_STOP_CMD` | Stops them and drops their data; `worktree-rm.sh` runs it. Without it, every removed worktree leaks its containers and volumes |

The choice is recorded in the worktree's env file (`WORKTREE_ISOLATED=1`), so later runs start the
services too, and `worktree-ls.sh` shows `own` or `shared`.

**When the service's config is tracked** (a local-stack config file in the repository), don't
write per-worktree ports into it — that dirties every worktree's diff, and a hand-edited copy drifts.
Generate a working copy outside the repository instead (keyed by `${SLUG}`, written by
`ISOLATED_SETUP_CMD`), with the migrations and seed data linked back to the worktree's own files so
they stay the repository's copies.

**Budget for it.** Each isolated stack is another set of containers. One measured local backend
stack — database, auth, API, storage, and their tools — ran ten containers in about 1 GB of memory;
on an 8 GB container VM that already runs one app per worktree, that made three isolated worktrees
the ceiling. Measure yours and record it here, and check free memory before starting another.
<!-- CUSTOMIZE: which services are isolated, what one stack costs here, how many fit on a typical laptop -->

## Seeing your environments

`scripts/agent/worktree-ls.sh` answers "which port is that branch on, and is it up" for every
worktree at once. `--info` adds each environment's app URL and runs `ENV_INFO_CMD` inside it — the
place for a project's service endpoints and the accounts to sign in with. Derive these every time,
from the env file and the database: ports and seeded accounts change, so a table of them committed
to the repository would be wrong by the time anyone read it. A credential `ENV_INFO_CMD` can't
confirm is better reported as stale than shown as if it worked.

## Claude Code's built-in worktrees

Claude Code can create worktrees itself (`claude --worktree <name>`, subagents with
`isolation: worktree`, and some desktop flows), under `.claude/worktrees/` on branches it names.
Those are fine for read-only exploration or isolated subagent work, but they don't get this
project's env file, port, or branch convention — so task work goes through `worktree-new.sh`, and
`.claude/worktrees/` stays in `.gitignore` and `.claudeignore`.

Task work still ends up in them: a session started from a suggested task, or a developer reusing a
parked one. So a session that starts in one is told it has **no role** — read and explore, but ask
for a dispatch before working (the session-context hook) — and `worktree-ls.sh` flags any
`<type>/<slug>` branch living in one, with how to move it. The app may park these worktrees rather
than delete them; remove the ones you don't need with `git worktree remove`.
