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

## One task, one session

| | Main checkout | A task's worktree |
|---|---|---|
| A session here | Starts here, triages its task, and answers from here when the answer only reads | Does the task: spec folder, gate, TDD, commits, the draft pull request |
| Never | Edits, commits, or branches | Takes a second, unrelated task |

The `session-context` hook tells each session where it is and what comes next.

**Why.** The main checkout is shared: an edit or a dev server there collides with whoever starts
next, and its base branch takes no commits. A session reused for an unrelated task mixes two tasks'
context, branch, and pull request. So each task gets its own session, worktree, folder, branch, and
pull request, and no session sits in the main checkout handing tasks out
([0042](../decisions/0042-each-session-moves-to-its-task-worktree.md)).

## Steps

### A new session for each task

Start a session in the main checkout and give it the task — `/adf:triage <tracker link>`, or just
the task. It triages from there: reading needs no worktree. The triage names the branch — a task on
a delivered feature starts its slug with that feature's spec-folder slug and adds the change
(`feat/newsletter-signup-topics`) — and says whether the task needs a worktree: a change, in any
lane, or an answer that runs the app, the tests, or the database. An answer that only reads stays in
the main checkout and changes nothing.

### The move — `/dispatch`

Right after the triage, `/dispatch`:

1. **Creates the worktree** — `ops/agent/worktree-new.sh <type>/<slug> --no-start`: a sibling
   directory named after the branch (`../feat-newsletter-signup-topics`), a fresh branch from the base
   branch, and the env file seeded from the main checkout's, with the worktree's own Compose project
   name. No port is reserved: the newsletter site's stack runs in Docker, which picks each worktree's
   ports when it starts. `--no-start` because the task's own steps decide what runs.
2. **Moves the session into it** — `change_directory` to the path the script printed, in the desktop
   app (a hook approves a worktree of this repository, so no prompt asks), or `EnterWorktree` in a
   terminal. `pwd` confirms it. If the move is refused, the session gives you the worktree's path and
   stops: open a session on that folder.

The session carries on there from where its triage left off. Until the move it edits nothing — the
protect-hub hook stops any edit in the main checkout. Hooks don't run again after the move, so the
session finds its spec folder itself.

### Another task — another session

A session that already has a task doesn't take another. When you bring it an unrelated one, or it
finds one along the way, `/dispatch` offers it a new session: in the desktop app, a task chip titled
with the task (`Show the chosen topics after signup`), which you start with one click; in a terminal,
`claude "<prompt>"` in the main checkout. The prompt is two lines — the task, and "follow
`AGENTS.md` end to end, starting with triage" — and the new session triages and moves the same way.
The workflow isn't restated: a copy is one more thing that drifts from `AGENTS.md`.

### In the worktree — work

The session follows whichever scenario its triage picked. What's specific to worktrees:

- **The environment on demand.** When a step needs the app or the tests, run
  `ops/agent/worktree-new.sh <branch>` from the worktree: for an existing worktree it leaves the
  branch alone and runs `SETUP_CMD` and `START_CMD` from `ops/agent/worktree.conf`, then waits
  for the app. On the newsletter site `START_CMD` is `make up`: Compose takes the worktree's project
  name from the env file and Docker picks free ports, so the stack comes up beside every other
  worktree's, and `make urls` says where. A project that runs nothing locally sets neither.
- **Host dependencies before the first commit**, even with no environment —
  `ops/agent/worktree-new.sh <branch> --setup-only`: git hooks run on the host, and an agent
  never bypasses a failing hook.
- **Configuration comes from the main checkout.** Keep secrets right in the main checkout's env file;
  every new worktree inherits them, and `--refresh-env` brings an existing worktree up to date. Don't
  hand-edit what the script generates — the project name, and a port when the scripts reserve one: it
  sits in a block at the end of the env file. Don't pin a port in the main checkout's env file either:
  every worktree's copy would repeat it, and `make up` refuses to run there.
- **Ports.** A Docker stack's are Docker's, picked free each time a service starts;
  `worktree-ls.sh --info` runs `make urls` in each worktree. A server that runs on the host takes a
  port the scripts reserve per worktree (`PORT_SLOTS`), derived from the branch name under a lock so
  two worktrees created at once can't take the same one; `worktree-ls.sh` then shows each worktree's port
  and whether it's up, and warns when two claim one.

### Shared services

Worktrees share whatever their env files point at. That's fine until a task would change the shared
thing for everyone; then that worktree gets its own copy — started in `START_CMD` under its own name,
removed in `STOP_CMD`, pointed at through `ENV_OVERRIDES` — at the memory and startup time each copy
costs. Record what the team shares and what a task may copy in `docs/PARALLEL-AGENTS.md`.

On the newsletter site the shared service that matters is the Contentful environment: a session
running a content-model migration against the shared development environment changes the model under
every other worktree's app. Content-model work gets its own Contentful environment, set in that
worktree's env file.

### Claude Code's own worktrees

A chip's session in the desktop app starts in one of Claude Code's own worktrees, and so can a
session started with its worktree option, or `claude --worktree`. Each sits at the app's worktree
location — `.claude/worktrees/`, inside the main checkout, by default — on a generated branch,
without the start command. That's where the session starts, not where it works: after triage,
`/dispatch` creates the task's worktree beside the main checkout and moves there
([0040](../decisions/0040-workers-move-out-of-the-apps-worktree.md)). It never renames the generated
branch, and the app removes that worktree when the session is archived. A worktree from before, already
on a task branch, stays a worker ([0015](../decisions/0015-tool-worktrees-are-workers.md)), and the
session-context hook names what it lacks. `worktree-ls.sh` flags the ones left on a generated branch. `.claude/worktrees/` stays in
`.gitignore` and `.claudeignore`.

### Cleanup

When the pull request has merged, or the task is dropped:

```
ops/agent/worktree-rm.sh feat/newsletter-signup
```

It stops the environment, removes the worktree, and deletes the branch only if git sees it as
merged. After a squash merge it keeps the branch and says so: delete it (`git branch -D`) once the
work is upstream. A later change request never reuses that branch — it gets a fresh one
(`feat/newsletter-signup-topics`), and `worktree-new.sh` warns if it's asked to reuse a local branch
that is behind the base. Uncommitted changes block removal; `--force` discards them.

## Example

Monday morning, three tasks arrive for the newsletter site:

| Task | Its session |
|---|---|
| "Show the chosen topics after signing up" — feedback on delivered work | `feat/newsletter-signup` — reuses the feature's slug |
| "Every signup fails since 09:12" | `fix/newsletter-rate-limit-outage` |
| "What would it take to switch email providers?" | An answer that only reads: stays in the main checkout |

The team keeps the main checkout in a folder of its own, `/home/dev/code/newsletter-site/main`, as
`worktree.conf` suggests, and sets `PROJECT_PREFIX="newsletter-site"` there — otherwise every project
name would start with `main-`. You start three sessions in the main checkout, one per task. The first
triages a change request, and `/dispatch` creates its worktree:

```
$ ops/agent/worktree-new.sh feat/newsletter-signup --no-start
==> Fetching origin
==> Creating 'feat/newsletter-signup' from origin/main
==> Writing .env from the main checkout's

==> Worktree ready: /home/dev/code/newsletter-site/feat-newsletter-signup
    Branch:  feat/newsletter-signup
    Project: newsletter-site-feat-newsletter-signup

--no-start: the environment is left down. The worker starts it when a step needs it.
```

The two changes' sessions move into their worktrees; the estimate's stays. An hour later:

```
$ ops/agent/worktree-ls.sh --info

  BRANCH                               CHANGES  PATH
  main                                 0        /home/dev/code/newsletter-site/main (main checkout)
  feat/newsletter-signup               0        /home/dev/code/newsletter-site/feat-newsletter-signup
  fix/newsletter-rate-limit-outage     0        /home/dev/code/newsletter-site/fix-newsletter-rate-limit-outage

  feat/newsletter-signup
      ○ web        not running  (APP_PORT)
      ○ redis      not running  (REDIS_PORT)
  fix/newsletter-rate-limit-outage
      ● web        http://localhost:51344  (APP_PORT)
      ● redis      localhost:51342  (REDIS_PORT)
```

- The **change request** session triaged a CR 2 on `specs/007-newsletter-signup/` and is at the
  approval gate — no environment yet, because planning doesn't need one ([Change request](change-request.md)).
- The **hotfix** session started its environment for the regression test and has committed the fix ([Hotfix](hotfix.md)).
- The **analysis** session read from the main checkout and never needed a worktree; its answer is
  waiting for the developer's approval to post ([Answer-only task](answer-only-task.md)). If the
  developer approves the provider switch it recommends, that change gets a session of its own.

## Commits it produces

The main checkout gets none — it stays clean. Each task's session produces the commits of its own
scenario, on its own branch:

```
$ git -C /home/dev/code/newsletter-site/main status --short
$ git -C /home/dev/code/newsletter-site/fix-newsletter-rate-limit-outage log --oneline main..
4c2e8f1 fix: accept signups when the rate-limit store is unavailable
```

## Without the module

The rule still holds — one worktree per session — and you do by hand what the scripts automate:

```
git worktree add --no-track -b feat/newsletter-signup ../feat-newsletter-signup origin/main
cp .env ../feat-newsletter-signup/.env      # Docker picks the copy's ports; its folder names the project
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
| A one-line fix in the main checkout | A stray edit collides with every other session, and the base branch takes no commits | Even one line moves to its worktree first |
| Creating the worktree before triage | A branch named before the task is understood, or a worktree an answer never needed | Triage first; `/dispatch` after |
| Creating the worktree without `--no-start` out of habit | An environment built for a task that may not need one | The session starts it when a step needs it |
| Working in Claude Code's own worktree | A worktree inside the main checkout, on a generated branch, with no start command | `/dispatch` moves the session to the task's worktree beside the main checkout |
| Taking the next task in the same session | Two tasks' context, branch, and pull request mixed | `/dispatch` offers it a new session |
| Raw `git worktree add` with the module installed | Ports and env files drift from what the scripts track | The scripts |
| Changing a service every worktree shares | Every other worktree's environment changes under it | That worktree gets its own copy (§ Shared services) |
| Keeping a squash-merged branch | The next change request on that feature starts from stale code | Delete it after merge |
| Restating the workflow in a new session's prompt | The copy drifts from `AGENTS.md` | The task, and "follow `AGENTS.md`" |

**Reference:** [`docs/PARALLEL-AGENTS.md`](../../modules/parallel-agents/files/docs/PARALLEL-AGENTS.md) ·
[`/dispatch`](../../plugins/adf/skills/dispatch/SKILL.md) ·
[`worktree.conf`](../../modules/parallel-agents/files/ops/agent/worktree.conf)
