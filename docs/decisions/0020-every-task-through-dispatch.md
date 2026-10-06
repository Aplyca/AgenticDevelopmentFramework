# 0020: Every task goes through `/dispatch` in the main checkout (parallel-agents module)

- **Status:** accepted
- **Date:** 2026-10-06
- **Amends:** [0008](0008-dispatcher-and-worker-worktrees.md) — what the dispatcher takes; [0015](0015-tool-worktrees-are-workers.md) — who picks a task's route; [0016](0016-packaged-install.md) — a module's skill comes from the plugin

## Context

Decision 0008 made the main checkout a dispatcher: it names each task and hands it to a worker in a
worktree of its own. Decision 0015 then let developers skip it. A task whose worktree needs nothing
from the scripts starts in a new session with Claude Code's worktree option, and `/dispatch` covers
only the scripts' route. So the developer picks each task's route, and for the common route starts
the session by hand.

A team using the module asked for one way in: every requirement goes to the session in the main
checkout. That session works out what the task needs and hands it to a new session, which runs the
whole process. No task work happens in the main checkout.

**What the tooling can hand over** (Claude Code 2.1.286 and the desktop app, October 2026):

- **A task chip.** In the desktop app, a session can offer work as a task chip. One click starts it in
  a new session with a worktree of its own and the chip's prompt, and the first session carries on.
  It's the only session a desktop session can start.
- **The chip's worktree is always its own.** It's created under `.claude/worktrees/`, from the default
  branch, without the scripts' env file, port, or setup. Another project, whose worktrees run
  containers, tested this on 2026-09-22 with a logging hook:
  - A chip creates its own worktree even when it's given another worktree as its folder.
  - A `WorktreeCreate` hook runs for a chip, but it's told neither that folder nor the task.
  - The app skips the hook when it reuses a parked worktree.
  
  So a worktree the scripts set up can't be handed over by a chip. That project hands it over as a
  prompt the developer pastes into a session opened on the worktree.
- **In a terminal**, `claude --worktree <name> "<prompt>"` starts a session in a new worktree with
  that prompt.

**Who should pick the route.** Whether a task will run the app is a triage question. It's answered
after reading the task in full, and often the code. Decision 0008 keeps that reading out of the main
checkout. A wrong guess also costs more one way than the other:

- **A chip for a task that turns out to need the app** means a second dispatch and a new session, and
  the triage starts again.
- **The scripts' worktree for a task that didn't need it** costs one pasted prompt. Nothing starts,
  because the scripts create it with `--no-start`.

In the project above, 7 of the last 40 merged changes touched only docs or agent-instruction files.
The other 33 touched code, tests, migrations, CI, or dependencies.

**Where `/dispatch` lives.** Decision 0016 keeps every module's files committed, a rule written for the
scripts, templates, and configuration a project owns. `/dispatch` is none of those: it's generic
machinery, like the skills the plugin already carries, and it's the only skill any module ships. A
packaged project still committed it, the one framework skill in its repository, and upgraded it by
merging files while every other skill moved with the pin.

## Decision

- **Every task goes through `/dispatch` in the main checkout.** It names the task, takes the route,
  and hands the task to a new session in a worktree of its own. The worker does everything from
  triage on, as before.
  - The session-context hook gives the dispatcher that instruction and its project's route.
  - `protect-hub.sh`'s message points at `/dispatch`.
  - A session a developer starts with the worktree option is still a worker.
- **The project picks the route, from `scripts/agent/worktree.conf`:**
  - **Its worktrees need nothing from the scripts:** Claude Code's worktree. In the desktop app,
    `/dispatch` offers a task chip carrying the worker prompt. In a terminal, it gives a
    `claude --worktree` command.
  - **They need a port, setup or start commands:** the scripts' worktree, created with
    `worktree-new.sh --no-start`. `/dispatch` gives its path and the prompt for the developer to paste
    into a new session opened on it.
  - **Tasks start from a branch other than the default:** the scripts' worktree, always.
- **The developer can pick the other route for one task**, because they know the task. Examples: a
  chip for a copy change in a project whose worktrees run a server, or the scripts anywhere. A chip is
  never allowed where tasks start from another branch, and the dispatcher doesn't pick another route
  on its own.
- **The scripts' worktree is never handed over as a chip.** `/dispatch` and `PARALLEL-AGENTS.md`
  say why, so nobody switches the hand-off back to a chip.
- **The plugin carries the modules' skills.** `scripts/build-aplyca-adf.sh` copies each one from its
  module, which stays the one source, so a committed install doesn't change.
  - A packaged project commits no `.claude/skills/dispatch/`. `/aplyca-adf:upgrade` deletes a copy
    that's unchanged since the baseline.
  - The skill stops in a project without its module, as the plugin's hooks already do. The rest of
    the module stays committed: `worktree.conf` is the project's configuration,
    `PARALLEL-AGENTS.md` has a section each project fills in, and developers run the scripts from their
    own terminal.

## Consequences

- **Positive:**
  - One way in for every task and every developer.
  - The dispatcher's job stays a lookup: it reads only the task's title and type.
  - The common route is one click in the desktop app.
  - No route comes from a guess.
- **Negative / cost:**
  - **Two sessions per task again.** Decision 0015 had removed the dispatcher for the common route.
    The dispatcher's turn is short, but its conversation keeps growing, so `/dispatch` suggests
    clearing it between tasks.
  - **A pasted prompt per task in a project whose worktrees need the scripts,** docs-only tasks
    included, unless the developer asks for a chip.
  - **The one-click hand-off is the desktop app's.** A terminal gets a command to run.
  - **A packaged project without the module lists `/aplyca-adf:dispatch`,** a skill it can't use. It
    stops when called.

## Alternatives considered

- **Keep 0015, where developers pick the route.** That's what the team asked to change: the developer
  routes each task and starts the common route's session by hand.
- **The dispatcher picks per task.** It would read the task to guess whether it runs the app, which is
  a triage question, and a wrong chip costs a second dispatch. The saving is one pasted prompt on the
  tasks that touch only docs, about 1 in 5 in the project above. The developer can still make that
  call for one task.
- **Set up the chip's worktree after triage**, for example a `worktree-new.sh --here` that adds the port
  and setup in place. The app archives and reuses its own worktrees, so the containers and port
  reservations the scripts added there would have no owner to stop them. `STOP_CMD` runs only from
  `worktree-rm.sh`.
- **A `WorktreeCreate` hook that routes a chip through the scripts.** Ruled out by the test above: the
  hook isn't told the folder or the task, and doesn't run for a reused worktree.
- **Agent teams.** Teammates share the lead's directory, with no worktree each, and the feature is
  experimental.
- **Background sessions from agent view (`claude --bg`).** A research preview. A session started in
  the main checkout is told it's the dispatcher until it moves into its worktree. Worth revisiting once
  it's stable.
