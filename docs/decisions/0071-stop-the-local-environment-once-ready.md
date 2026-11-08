# 0071: The agent stops the local environment once its pull request is ready, keeping everything to resume it

- **Status:** accepted
- **Date:** 2026-11-07
- **Amends:** [0045](0045-agent-local-check-opens-the-draft.md) — the agent no longer leaves the local
  environment running after its report; [0032](0032-local-environment-layout.md) — the docker
  module's command surface gains `make stop`

## Context

- **A local environment stayed up for as long as its pull request waited.** Decision 0045 had the
  agent leave it running after its report, so the developer could test there; only `/wrap-up`, after
  the merge, stopped it. A review can take hours or days, and the app, its database, and its other
  services held memory and CPU the whole time — one stack per worktree with the `parallel-agents`
  module.
- **Once the pull request is ready, the preview is where the developer tests** (decision 0070). The
  local copy is the agent's tool for the next adjustment, more than the developer's.
- **That adjustment needs the environment as it was.** A review comment means a fix, walked locally
  again. Recreating containers, reseeding a database, or reinstalling dependencies costs minutes,
  and state outside a named volume is lost.
- **Nothing stopped a stack without removing something.** The docker module's `make down` removes
  the containers; `make reset` and the worktree's `STOP_CMD` delete volumes too.

## Decision

- **Once the pull request is ready, the agent stops the local environment it started** — the last
  step before its report: the background commands it started (a dev server), and the services
  through the project's stop task, `make stop` with the docker module.
- **Stop, never down, kill, or remove.** The running processes and containers end, freeing memory
  and CPU; containers, volumes, data, images, dependencies, the worktree, and its branch stay, and
  `make up` starts it again. Never `make down`, `make reset`, the worktree's `STOP_CMD`, or any command
  that removes containers, volumes, or data. When a project's only stop command removes something,
  the agent ends just the background commands it started, and the report says what still runs.
- **Only what this session started.** An environment already running when the session began is the
  developer's, and stays as it was.
- **A draft keeps its environment running:** the agent is still testing it, and the developer may
  want to see what holds it.
- **The report gives the preview to test on, and how to resume it locally** — `make up`, or the
  project's start command, which prints where it runs: a port Docker picked can change.
- **A fix after ready resumes it,** walks the change, and stops it again once the pull request's
  checks pass.
- **Nothing else touches it until the merge.** `/wrap-up` still closes up after it: `make down` — the
  containers go, the data stays — or, with a worktree, the remove `adf-worktree-rm` runs.
- **One word for each state of the local environment** — Docker's own, in the dev-env
  specification's C12, the tasks, the docs, and what an agent says:
  - **Stop** — the processes and containers end, after a graceful shutdown; memory and CPU are
    freed, and everything else stays. `make stop`, run by the agent once its pull request is ready.
  - **Pause** — Docker's `pause`: the processes freeze in place, freeing CPU but holding memory.
    No task: it doesn't save what stopping is for.
  - **Down** — stop, then remove the containers and networks; named volumes, the data, stay.
    `make down`, run by `/wrap-up` after the merge, or by the developer.
  - **Kill** — the processes end at once, with no graceful shutdown; a database can lose unsaved
    writes. No task: an agent kills only a process it started that ignores a stop.
  - **Remove** — containers, networks, and volumes deleted, so the data is gone; images stay.
    `make reset` (remove, then start fresh), and a worktree's `STOP_CMD` when `/wrap-up` removes
    the worktree — only on the developer's yes.
- **The docker module gains `make stop`, in both modes.** Docker mode stops the stack's containers,
  the production build's too (`docker compose --profile prod stop`); native mode stops the app's
  process group and the backing services' containers. It runs `guard` first, and takes what it
  stopped out of Claude Desktop's Browser.

## Consequences

- **Positive:**
  - A pull request waiting for review holds no memory or CPU on the developer's machine; with
    `parallel-agents`, only the worktrees being worked on run.
  - The next adjustment resumes in seconds, with the same containers and data.
- **Negative / cost:**
  - **A developer who wants to test locally runs `make up` first,** and the port may differ from the
    one before.
  - **Stopped containers and their volumes keep their disk space** until `/wrap-up`.
  - **A project without the docker module needs its own stop** for services the agent started; a
    dev server it ran in the background just ends.
  - **The rule rests on the agent following `/open-pr`.** No hook can tell whether it stopped what it
    started.

## Alternatives considered

- **Leave it running until the merge (0045 as it was).** Declined: the environment holds resources
  for the whole review, when the developer tests on the preview.
- **`make down` once ready.** Declined: it removes the containers, so the next adjustment pays to
  recreate them and loses state outside named volumes — what stopping is meant to avoid.
- **A pause once ready** (Docker's `pause`). Declined: the processes stay in memory, so it frees CPU
  alone.
- **Stop when the draft opens.** Declined: the preview walk and CI can still send the agent back to
  fix the change.
- **Stop everything that runs.** Declined: an environment the developer started is theirs.
