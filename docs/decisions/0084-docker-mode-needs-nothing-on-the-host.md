# 0084: Docker mode needs nothing on the host — a tools service runs the checks and `make run`

- **Status:** accepted; amended 2026-11-16 (the cache volume is external, the tasks that start the
  tools run `guard`, D8's ask rules match the command's variable, and the hook names the service)
- **Date:** 2026-11-15
- **Amends:** [0077](0077-the-container-is-the-boundary-for-make-run.md) — in Docker mode `make run`
  runs in the tools service's container, not the app's; [0034](0034-local-environment-modes.md) —
  `test`, `lint`, `format`, and `typecheck` run where the mode runs its tools, not where it runs
  the app

## Context

- **An adopting project asked for it** ([#149](https://github.com/aplyca/AgenticDevelopmentFramework/issues/149)):
  in Docker mode, nothing installed on the developer's host. It had made the change in its own
  repository and reported what it found.
- **The specification already implied it, for the app.** C10 sent tests, linters, and the package
  manager to the app's container, never the host. Part 1 of the issue ([#157](https://github.com/aplyca/AgenticDevelopmentFramework/pull/157)) took the host
  commands out of the `unit`, `e2e`, `git-hooks`, and `parallel-agents` modules.
- **"Where the app runs" wasn't enough:**
  - the checks ran with `docker compose exec` in the app's container, so they needed `make up`
    first, and so did a git hook that ran them;
  - an app's service often mounts only its source and a few config files, so a lint there saw
    `tests/` as it was at the last image build, not on disk;
  - a tool that isn't the app — a local backend's CLI, a migration tool — had no container, and
    projects went back to `npm install` on the host for it.
- **What a host install cost the project:** about 1 GB of dependencies per worktree, built for
  macOS while CI runs Linux, and a developer who keeps the host clean couldn't work.
- **The boundary from 0077 and 0078 holds only while D5 does.** `make run` runs any command without a
  prompt because the container it runs in reaches nothing of the host but the checkout. The issue's
  tools service had the Docker socket and host networking, which reach the host's Docker and every
  service on it. With `Bash(make *)` allowed, a `make tools cmd=…` there would be a prompt-free way
  onto the host.
- **What Compose does** (v5.7.0, checked with throwaway projects):
  - `docker compose run <service>` starts a service in a profile without `--profile`, and builds its
    image when it's missing;
  - a volume with a fixed `name:` is shared by every project that declares it, but belongs to the
    project that created it: that project's `docker compose down -v` removes it, with or without the
    profile of the services that mount it, and every other project warns on each run that it was
    created for another (corrected 2026-11-16; see the amendment below).
- **The issue's three open questions,** settled with the developer:
  1. the rule is the docker module's default, not an opt-in;
  2. the tools image is a stage of the app's Dockerfile, not a generic tools image;
  3. a command-taking task outside D5 gets an ask rule, and its frequent safe commands become named
     tasks; the framework enumerates no CLI's subcommands.

## Decision

- **In Docker mode the host needs Docker, git, and make, and nothing else (M11).** Every task runs in
  a container; no task, `SETUP_CMD`, or git hook runs the stack's runtime, package manager, or a
  project CLI on the host; an agent never fixes a missing tool by installing it there, or by
  switching modes. Native mode and CI install what they need.
- **A `tools` service runs the checks and `make run` (D6):**
  - in Compose's `tools` profile, the same pattern as `web-prod` in `prod`, so `make up` never
    starts it; in `compose.yaml`, not a second Compose file — L1 and L5 stay as they are, and the
    issue's reason for a second file, a `${VAR:?}` that stops a fresh clone, doesn't arise with V1's
    `${NAME:-}`;
  - built from a `tools` stage of the app's Dockerfile: the app's runtime and dependencies, plus
    whatever only the checks need;
  - the whole checkout mounted where the app mounts it, and the app's variables in container form;
  - `deps`, `test`, `lint`, `format`, `typecheck`, and `run` start it with
    `$(COMPOSE) run --rm tools …`, one container per command. None needs `make up` first. The checks
    that reach no backing service pass `--no-deps`.
  - It meets D5, which now names it beside the app's service.
- **`make run` runs in the tools service in Docker mode** (C10): `$(COMPOSE) run --rm tools sh -c
  "$$cmd"`. There is no second command-taking task. The approve-container-run hook already approves
  a recipe that hands `"$$cmd"` to Compose's `exec` or `run`, so its check is unchanged; its text and
  reasons now say "a container". A project whose `run` still execs into the app's container keeps
  its approval: the app's service meets D5 too.
- **Dependencies live in Docker volumes (D7):**
  - this checkout's, in a named volume, `deps`, that the app's service and `tools` mount over the
    folder the install writes. Docker fills a new one from the image that mounts it first. The app's
    service mounts it, so `docker compose down -v` (`make reset`, W2's `STOP_CMD`) removes it;
  - the package manager's cache, in one external volume with a fixed `name:` that every checkout
    of the repository shares, mounted only in `tools`: the tasks that start the tools create it when
    it's missing, and no `down -v` removes it;
  - commands stay the project's (C8).
- **A `deps` task in every mode (C3):** into the dependency volume (Docker), on the host (native).
  Docker's `build` rebuilds the images, then runs `deps`; native's `build` is `deps`. W2's
  `SETUP_CMD` is `make deps`.
- **A tool that needs more of the host than D5 allows gets its own service (D8)** — the Docker
  socket, host networking, a path outside the checkout, as a local backend's CLI that starts
  containers of its own does. Its command-taking task reads the command from a variable of its
  own, `<task>_cmd`, which gets ask rules wherever the call puts it; its frequent commands that
  delete nothing become named tasks, which run without a prompt like every task (C9).
- **The audit checks M11** by running `make deps`, `make lint`, `make typecheck`, and `make test`
  with the stack down and a `PATH` that reaches only `docker`, `git`, and `make` besides the system's
  folders.
- **Out of scope:** host networking as a default — the services reach each other on Compose's
  network, and the host reaches them on published ports (P1) — and a Dev Container module, a
  separate issue.

## Consequences

- **Positive:**
  - A developer needs Docker, git, and make; the checks run on the CI's operating system, Linux.
  - `make lint`, `make test`, and a git hook that runs them work with the stack down.
  - The checks see every file on disk, not what the app's mount includes.
  - One install serves the app and the tools, and a worktree's dependencies go with its volumes.
  - The prompt-free `make run` keeps the boundary of 0077.
- **Negative / cost:**
  - **The editor resolves no package.** With nothing installed on the host, it has no
    autocomplete, library types, or on-save lint and format from the project's dependencies.
    `DEV-SETUP.md` says what the team uses instead; a Dev Container is the natural next step.
  - **Each check starts a container,** about a second, and builds the tools image the first time.
  - **A volume per worktree,** about as large as a host install was.
  - **A volume that Docker filled from the image goes stale** when the lockfile changes: `make deps`
    or `make build` brings it up to date.
  - **The empty folder on the host where the dependency volume mounts** stays: deleting it changes
    nothing, and Docker recreates it.
  - **The cache volume outlives every checkout.** No task removes it; `docker volume rm` does.
  - **`make test` starts the backing services the tests need,** which then run until `make stop`.
  - **`docker *` is still allowed (0038, 0078),** so an agent can run `docker compose run` on a D8
    service without the ask its make task carries. The ask rule covers the documented way in, not
    every way.
  - **Files the tools write in the checkout** — a formatter's — belong to the container's user. On
    Docker Desktop they map to the developer; on Linux they may be root's.
  - **The PATH check doesn't catch a runtime the operating system ships** in `/usr/bin`; the audit
    reads the recipes for one.

## Alternatives considered

- **The issue's design: a socket-mounted, host-network tools container and `make tools cmd=`.**
  Declined: with `Bash(make *)` allowed, any command would reach the host's Docker without a
  prompt, which is what D5 keeps out.
- **A separate `compose.tools.yaml`.** Declined: every tools task would need `-f`, L1's list of
  files would grow, and the bootstrap loop it avoids comes from `${VAR:?}`, which V1 already rules
  out.
- **`make tools cmd=` beside `make run`.** Declined: two command-taking tasks, one of them in a
  container that may not meet D5; one `run` in a container that does is simpler to read and to
  approve.
- **Enumerate each CLI's safe subcommands in the framework or the hook.** Declined: the framework
  names no tool (C8), and the list would never close. A project's named tasks are its list.
- **An opt-in setting.** Declined: C10 already said "never on the host"; an opt-in would keep two
  ways to run the checks.
- **A generic tools image per stack.** Declined: the tools would drift from the app's runtime, and
  the framework would have to name images.
- **A Compose-created cache volume with a fixed `name:`.** First chosen, then replaced by the
  amendment: Compose gives it to the project that created it, whose `down -v` removes it, and
  warns in every other. The external volume's name lives in `compose.yaml` alone: the `Makefile`
  reads it from there.
- **Install before each run** (the issue's `install --frozen-lockfile && exec "$@"`). Left to the
  project: it costs time on every command, and a stack whose package manager checks its lockfile
  doesn't need it.
- **Host networking by default.** Declined: it's against D5, needs a Docker Desktop setting, and
  P1's published ports already reach the services from the host.

*Amended 2026-11-16:* a review of the merged change found four gaps, each fixed in the
specification and the templates.

- **The cache volume is external.** The "what Compose does" note above was wrong. Checked again on
  v5.7.0, a volume with a fixed `name:` belongs to the project that created it. That checkout's
  `docker compose down -v` deletes it, with any profile: removing a worktree that ran a check first,
  or a `make reset` there, emptied every checkout's cache. Every other checkout printed a warning on
  each tools command. `external: true` takes it away from every project; the tasks that start the
  tools run `docker volume create` first, which changes nothing when it's there. The name stays in
  `compose.yaml`: `ops/docker/Makefile` reads it from there (D7).
- **The tasks that start the tools run `guard`** (C6). They create containers and start backing
  services without `make up`. So a worktree whose `.env` copied the main checkout's
  `COMPOSE_PROJECT_NAME` would install into the main checkout's dependency volume, which `guard`
  stops before `up` but nothing stopped before `deps`.
- **D8's ask rules match the command's variable, not the task's name.** `Bash(make <task> *)` missed
  `make -s <task> cmd=…` and `make cmd=… <task>`, which the `Bash(make *)` allow then ran with the
  host's Docker. A variable of its own, `<task>_cmd`, gets `Bash(make *<task>_cmd=*)` and
  `Bash(<task>_cmd=*)`, as the docker module's deny rules match `DEV_MODE` (M10). C10's host-command
  tasks take the same form.
- **The approve-container-run hook names the service.** It approved a `run` recipe handing
  `"$$cmd"` to any service, with any option, beside any other line. It now approves only
  `$(COMPOSE) run --rm [--no-deps] tools` and an older stack's `$(COMPOSE) exec -T $(APP)`, and asks
  when another line of the task uses the command — so `make run` never reaches a D8 service, or a
  mount the recipe adds, without a prompt.
