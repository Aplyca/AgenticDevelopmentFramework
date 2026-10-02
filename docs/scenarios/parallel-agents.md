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
| Does | Names the task, creates the worktree, hands off (`/dispatch`) | Everything from triage on: spec folder, gate, TDD, commits |
| Never | Reads code, analyzes, edits, starts environments | Goes back to the main checkout to work |

The `session-context` hook tells each session its role when it starts.

**Why split them.** The main checkout is the hub every session starts from: an edit or a dev server
there collides with whoever starts next. And analysis done in the hub is wasted — the dispatcher
can't run the app or the tests, so its conclusions are unverified, and the worker reads everything
again anyway, where it can check it. The dispatcher's context stays cheap: a branch name, not a plan.
([Decision 0008](../decisions/0008-dispatcher-and-worker-worktrees.md) has the full reasoning.)

## Steps

### In the main checkout — dispatch

`/dispatch <tracker link>` does four things and nothing else:

1. **Names the task** — its title and type only; no code reading, no requirements analysis. A short
   kebab-case slug. A task that names a delivered feature starts its slug with that feature's
   spec-folder slug and adds the change (`feat/newsletter-signup-topics`) — `ls specs/` is enough;
   whether it really is a change request is the worker's triage to decide.
2. **Creates the worktree** — `scripts/agent/worktree-new.sh <type>/<slug> --no-start`: a sibling
   directory named after the branch (`../feat-newsletter-signup-topics`), a fresh branch from the base
   branch, the env file seeded from the main checkout's — and, on this site, which runs a server per
   worktree, a reserved port. `--no-start` because whether the task needs anything running is the
   worker's call.
3. **Starts the worker session** in the worktree — `cd <worktree> && claude` — or, where the tool
   can't start a session in a folder you choose, gives you the prompt to paste into a new session
   opened on the worktree.
4. **Writes the handoff** — three lines, pointers only:

   ```
   Task: <tracker link>
   Worktree: <absolute path> — branch <type>/<slug>
   Follow AGENTS.md end to end, starting with triage.
   ```

   The workflow isn't restated: a copy in a handoff is one more thing that drifts from `AGENTS.md`.

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

### Tools that create their own worktrees

Claude Code can create worktrees itself — `claude --worktree`, subagents with `isolation: worktree`,
and some desktop flows such as suggested-task chips — under `.claude/worktrees/`, on branches it
names. They're fine for read-only exploration and isolated subagent work. The project's scripts never
set them up — no copy of its env file, no branch convention — so **don't use them for task work**:
dispatch instead. A session that starts in one is told it has no role, and `worktree-ls.sh` flags
task branches found in them.
`.claude/worktrees/` stays in `.gitignore` and `.claudeignore`.

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
times. The first:

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

Each worker gets a new session on its worktree and its three-line prompt. An hour later:

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
| Dispatching without `--no-start` out of habit | An environment built for a task that may not need one | The worker starts it after triage |
| Built-in worktree tools for task work | No env file, port, or branch convention; ports collide | `/dispatch` and `worktree-new.sh` |
| Raw `git worktree add` with the module installed | Ports and env files drift from what the scripts track | The scripts |
| Changing a service every worktree shares | Every other worker's environment changes under them | That worktree gets its own copy (§ Shared services) |
| Keeping a squash-merged branch | The next change request on that feature starts from stale code | Delete it after merge |
| Restating the workflow in the handoff | The copy drifts from `AGENTS.md` | Three lines, pointers only |

**Reference:** [`docs/PARALLEL-AGENTS.md`](../../modules/parallel-agents/files/docs/PARALLEL-AGENTS.md) ·
[`/dispatch`](../../modules/parallel-agents/files/.claude/skills/dispatch/SKILL.md) ·
[`worktree.conf`](../../modules/parallel-agents/files/scripts/agent/worktree.conf)
