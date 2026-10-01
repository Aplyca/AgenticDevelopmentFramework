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
| `scripts/agent/worktree-new.sh <type>/<slug> [--no-start \| --setup-only] [--refresh-env] [--from <ref>]` | Creates `../<type>-<slug>` on branch `<type>/<slug>` (from `BASE_BRANCH`, or `--from` a tag for a hotfix), seeds its env file from the **main checkout's** file, reserves a port, writes the override block; then runs setup and start and waits until the app answers — unless `--no-start` (create only) or `--setup-only` (just what the git hooks need). Rerunning on an existing worktree never touches its branch: it sets up and starts it, and `--refresh-env` rewrites its env file (keeping its port while no sibling claims it) |
| `scripts/agent/worktree-ls.sh` | Lists every worktree: branch, port, whether something is listening, uncommitted changes — and warns when two claim the same port |
| `scripts/agent/worktree-rm.sh <type>/<slug> [--force]` | Stops the environment (`STOP_CMD`), removes the worktree, deletes the branch only if git sees it as merged |

**Match the environment to the lane.** A fast-lane fix usually needs only `--setup-only` — the
dependencies the git hooks and unit tests use — not a running app or database; start the app when a
test or check actually needs it. Every service a worktree starts is setup time and log output the
session pays for.

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

Worktrees share whatever their env files point at — often one local database. That's fine for UI
work and wrong for anything that changes the schema: a migration one worker applies is visible to
every other worker, and a reset destroys their data. For schema work, give the worktree its own
database — an isolated stack per worktree, or a per-worktree database name generated through
`ENV_OVERRIDES` (`DB_NAME=app_${SLUG}`) — and budget for it: each extra stack costs memory and
containers. Record the team's choice here.
<!-- CUSTOMIZE: shared by default? isolated on request? what it costs on a typical laptop? -->

## Claude Code's built-in worktrees

Claude Code can create worktrees itself (`claude --worktree <name>`, subagents with
`isolation: worktree`, and some desktop flows), under `.claude/worktrees/` on branches it names.
Those are fine for read-only exploration or isolated subagent work, but they don't get this
project's env file, port, or branch convention — so task work goes through `worktree-new.sh`, and
`.claude/worktrees/` stays in `.gitignore` and `.claudeignore`.
