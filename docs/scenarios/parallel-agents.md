# Scenario: Several agent sessions at once

## When to use this

More than one agent session works on the same repository at the same time — a change request in
one, a hotfix in another, an impact analysis in a third.

**The rule, with or without tooling: one task per worktree, and never two sessions in one
checkout.** A checkout's working tree, branch, and uncommitted changes — and any running server —
are shared state: a second session there edits under the first one's feet, switches its branch, or,
when the app runs locally, takes its port.

Most of this page is about the [parallel-agents module](../../modules/parallel-agents/MODULE.md),
which makes that rule cheap to follow. Without it, see [the last section](#without-the-module).

**Not this scenario:** one session at a time. Work on a branch in your checkout as usual; the moment
a second session starts, it gets its own worktree.

## Two roles

| | Main checkout — **dispatcher** | A worktree — **worker** |
|---|---|---|
| Does | Takes every task with `/dispatch` and hands it to a new session, which creates the task's worktree and moves into it | Everything from triage on: spec folder, gate, TDD, commits |
| Never | Reads code, analyzes, edits, starts environments | Goes back to the main checkout to work |

The `session-context` hook tells each session its role when it starts.

**Why split them.** The main checkout is the hub every session starts from: an edit or a dev server
there collides with whoever starts next. And analysis done in the hub is wasted — the dispatcher
can't run the app or the tests, so its conclusions are unverified, and the worker reads everything
again anyway, where it can check it. The dispatcher's context stays cheap: a branch name, not a plan.
([Decision 0008](../decisions/0008-dispatcher-and-worker-worktrees.md) has the full reasoning.)

## Steps

### In the main checkout — dispatch

Every task starts here, with `/dispatch <tracker link>`, and takes the same route
([0020](../decisions/0020-every-task-through-dispatch.md),
[0021](../decisions/0021-sibling-worktree-and-chip.md)). `/dispatch` does three things and runs
nothing:

1. **Names the task** — its title and type only; no code reading, no requirements analysis. A short
   kebab-case slug. A task that names a delivered feature starts its slug with that feature's
   spec-folder slug and adds the change (`feat/newsletter-signup-topics`) — `ls specs/` is enough;
   whether it really is a change request is the worker's triage to decide.
2. **Writes the handoff** — three lines: pointers, and the one setup step the worker takes first:

   ```
   Task: <tracker link>
   Branch: feat/newsletter-signup-topics
   First create this task's worktree — scripts/agent/worktree-new.sh feat/newsletter-signup-topics --no-start — and move this session into it; then follow AGENTS.md end to end, starting with triage.
   ```

   The workflow isn't restated: a copy in a handoff is one more thing that drifts from `AGENTS.md`.
3. **Hands it over** — in the desktop app, a task chip for the main checkout, titled with the task's
   title (`Show the chosen topics after signup`). You start it in that folder, not in a new worktree,
   with one click. Once the session moves into its worktree, the app shows that folder —
   `feat-newsletter-signup-topics` — as the session's. In a terminal: `claude "<prompt>"` in the main
   checkout.

### In the new session — the worktree first

The new session opens in the main checkout, so its first lines say `Role: DISPATCHER` — and that a
session handed one task and its branch is that task's worker. Before anything else it:

1. **Creates the worktree** — `scripts/agent/worktree-new.sh <type>/<slug> --no-start`: a sibling
   directory named after the branch (`../feat-newsletter-signup-topics`), a fresh branch from the base
   branch, the env file seeded from the main checkout's — and, since the newsletter site runs a server
   in each worktree, a reserved port. `--no-start` because whether the task needs anything running is
   triage's call.
2. **Moves into it** — `change_directory` to the path the script printed, in the desktop app (you
   approve the folder once, and the session carries on there by itself), or `EnterWorktree` in a
   terminal. `pwd` confirms it. If the move is refused, the session gives you the worktree's path and
   stops: open a session on that folder and paste the prompt.

Until the move it edits nothing — the protect-hub hook stops any edit in the main checkout. Hooks
don't run again after the move, so the worker finds its spec folder at triage.

### In the worktree — work

The worker follows whichever scenario its triage picks. What's specific to worktrees:

- **The environment on demand.** When a step needs the app or the tests, run
  `scripts/agent/worktree-new.sh <branch>` from the worktree: for an existing worktree it leaves the
  branch alone and runs `SETUP_CMD` and `START_CMD` from `scripts/agent/worktree.conf`, then waits
  for the app. On the newsletter site the app reads its port (and Compose its project name) from the
  env file, so it comes up on the worktree's port; a project that runs nothing locally sets neither.
- **Host dependencies before the first commit**, even with no environment —
  `scripts/agent/worktree-new.sh <branch> --setup-only`: git hooks run on the host, and an agent
  never bypasses a failing hook.
- **Configuration comes from the main checkout.** Keep secrets right in the main checkout's env file;
  every new worktree inherits them, and `--refresh-env` brings an existing worktree up to date. Don't
  hand-edit `APP_PORT` or the project name: they sit in a block the script generates at the end of
  the env file, and the scripts read the ports there to know which ones are taken.
- **When worktrees run a server, ports are per worktree**, derived from the branch name and reserved
  under a lock, so two dispatches at once can't take the same one. `worktree-ls.sh` lists every
  worktree's branch and uncommitted changes — with its port and whether it's up, when there are
  ports — and warns when two claim one port.

### Shared services

Worktrees share whatever their env files point at. That's fine until a task would change the shared
thing for everyone; then that worktree gets its own copy — started in `START_CMD` under its own name,
removed in `STOP_CMD`, pointed at through `ENV_OVERRIDES` — at the memory and startup time each copy
costs. Record what the team shares and what a task may copy in `docs/PARALLEL-AGENTS.md`.

On the newsletter site the shared service that matters is the Contentful environment: a worker
running a content-model migration against the shared development environment changes the model under
every other worker's app. Content-model work gets its own Contentful environment, set in that
worktree's env file.

### Claude Code's own worktrees

A session started with Claude Code's worktree option — the desktop app's toggle, a chip started in a
new worktree, or `claude --worktree` — is a worker too
([0015](../decisions/0015-tool-worktrees-are-workers.md)). Its worktree sits under
`.claude/worktrees/`, inside the main checkout, on a generated branch, without the port or the start
command. `.worktreeinclude` copies the env file; the session renames the branch to `<type>/<slug>`
after triage; and the session-context hook names what's missing — here, the port and the start
command. `worktree-ls.sh` flags the ones left on a generated branch. `.claude/worktrees/` stays in
`.gitignore` and `.claudeignore`.

### Cleanup

When the pull request has merged, or the task is dropped:

```
scripts/agent/worktree-rm.sh feat/newsletter-signup
```

It stops the environment, removes the worktree, and deletes the branch only if git sees it as
merged. After a squash merge it keeps the branch and says so: delete it (`git branch -D`) once the
work is upstream. A later change request never reuses that branch — it gets a fresh one
(`feat/newsletter-signup-topics`), and `worktree-new.sh` warns if it's asked to reuse a local branch
that is behind the base. Uncommitted changes block removal; `--force` discards them.

## Example

Monday morning, three tasks arrive for the newsletter site:

| Task | Dispatched as |
|---|---|
| "Show the chosen topics after signing up" — feedback on delivered work | `feat/newsletter-signup` — reuses the feature's slug |
| "Every signup fails since 09:12" | `fix/newsletter-rate-limit-outage` |
| "What would it take to switch email providers?" | `docs/email-provider-impact` |

The team keeps the main checkout in a folder of its own, `/home/dev/code/newsletter-site/main`, as
`worktree.conf` suggests, and sets `PROJECT_PREFIX="newsletter-site"` there — otherwise every project
name would start with `main-`. The dispatcher session in the main checkout runs `/dispatch` three
times, and you start the three chips. The first worker's first step:

```
$ scripts/agent/worktree-new.sh feat/newsletter-signup --no-start
==> Fetching origin
==> Creating 'feat/newsletter-signup' from origin/main
==> Seeding .env from the main checkout

==> Worktree ready: /home/dev/code/newsletter-site/feat-newsletter-signup
    Branch:  feat/newsletter-signup
    Project: newsletter-site-feat-newsletter-signup
    Port:    47480

--no-start: the environment is left down. The worker starts it when a step needs it.
```

Each worker moves into its worktree and starts triage. An hour later:

```
$ scripts/agent/worktree-ls.sh

  BRANCH                               PORT    STATE  CHANGES  PATH
  main                                 -       -      0        /home/dev/code/newsletter-site/main (main checkout)
  feat/newsletter-signup               47480   down   0        /home/dev/code/newsletter-site/feat-newsletter-signup
  fix/newsletter-rate-limit-outage     43180   up     0        /home/dev/code/newsletter-site/fix-newsletter-rate-limit-outage
  docs/email-provider-impact           51280   down   0        /home/dev/code/newsletter-site/docs-email-provider-impact
```

- The **change request** worker triaged a CR 2 on `specs/007-newsletter-signup/` and is at the
  approval gate — no environment yet, because planning doesn't need one ([Change request](change-request.md)).
- The **hotfix** worker started its environment for the regression test and has committed the fix ([Hotfix](hotfix.md)).
- The **analysis** worker never needed an environment; its answer is waiting for the developer's
  approval to post ([Answer-only task](answer-only-task.md)).

## Commits it produces

The dispatcher produces none — the main checkout stays clean. Each worker produces the commits of
its own scenario, on its own branch:

```
$ git -C /home/dev/code/newsletter-site/main status --short
$ git -C /home/dev/code/newsletter-site/fix-newsletter-rate-limit-outage log --oneline main..
4c2e8f1 fix: accept signups when the rate-limit store is unavailable
```

## Without the module

The rule still holds — one worktree per session — and you do by hand what the scripts automate:

```
git worktree add --no-track -b feat/newsletter-signup ../feat-newsletter-signup origin/main
cp .env ../feat-newsletter-signup/.env      # this site runs a server: give the copy its own port
cd ../feat-newsletter-signup && claude
```

- Never start a second session in a checkout another session is using — the main checkout included.
- Branches are `<type>/<slug>` as usual; each worktree has its own.
- The `session-context` hook still tells each session whether it's in the main checkout or a linked
  worktree.
- The shared-services hazard is the same: a task that would change a shared service gets its own copy.
- Afterwards: `git worktree remove ../feat-newsletter-signup`, and delete the branch once it's merged.

## Common mistakes

| Mistake | What happens | Instead |
|---|---|---|
| Analyzing in the main checkout "to give the worker a head start" | Unverified conclusions, a burned context, drift in the handoff | Name the task; hand off |
| A one-line fix in the main checkout | A stray edit collides with every other session | Even one line goes to a worktree |
| Creating the worktree without `--no-start` out of habit | An environment built for a task that may not need one | The worker starts it after triage |
| Built-in worktree tools for task work | A worktree inside the main checkout, on a generated branch, with no port or start command; the app collides with another worktree's | `/dispatch`, whose session creates the task's worktree beside the main checkout |
| Starting the chip in a new worktree | The app's own worktree under `.claude/worktrees/`, on a generated branch, without the env file or port | Start it in the main checkout's folder; its first step makes the task's worktree |
| The dispatcher creating the worktree itself | The hub runs scripts and fetches — the task's work, in the shared checkout | The new session's first step creates it and moves in |
| A worker that starts triage before moving | It works in the shared main checkout, where the protect-hub hook stops its first edit | Create the worktree, move into it, confirm with `pwd` — then triage |
| Raw `git worktree add` with the module installed | Ports and env files drift from what the scripts track | The scripts |
| Changing a service every worktree shares | Every other worker's environment changes under them | That worktree gets its own copy (§ Shared services) |
| Keeping a squash-merged branch | The next change request on that feature starts from stale code | Delete it after merge |
| Restating the workflow in the handoff | The copy drifts from `AGENTS.md` | Three lines, pointers only |

**Reference:** [`docs/PARALLEL-AGENTS.md`](../../modules/parallel-agents/files/docs/PARALLEL-AGENTS.md) ·
[`/dispatch`](../../modules/parallel-agents/files/.claude/skills/dispatch/SKILL.md) ·
[`worktree.conf`](../../modules/parallel-agents/files/scripts/agent/worktree.conf)
