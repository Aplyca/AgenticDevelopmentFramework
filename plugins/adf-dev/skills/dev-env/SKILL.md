---
name: dev-env
description: Set up, migrate, run natively, diagnose, or safely reset this project's local environment to the specification this skill carries — compose.yaml and a Makefile, Docker or native by DEV_MODE, one stack per worktree — deleting nothing beyond this project's own containers and volumes without a yes. Use when the next step needs the app running and no stack works, when a stack should meet the specification, to run the app on the host, when the stack won't start or misbehaves, before the local check, or to reset local data.
argument-hint: "[set up | worktrees | native | diagnose <symptom> | reset]"
---

> **Step 0 — which copy.** This is the packaged copy, from the `docker` module, carried by `adf-dev` ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-plugins-by-concern.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/dev-env/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# Local environment

The local environment is where the change runs before anyone else sees it: the tests that need a
database, and the agent's **local check** before the draft pull request (`AGENTS.md` § Delivery
rules). This skill gets a Compose stack to that point and keeps it there. It doesn't decide *whether*
a task needs an environment — triage does (`AGENTS.md` § How work flows → Environment).

## The specification

**`<this skill's base directory>/SPECIFICATION.md` is what a local environment must be** — its layout
(one folder per target in `ops/`), the command surface (a root `Makefile` that loads
`ops/<DEV_MODE>/Makefile`, and the tasks every mode defines), the local modes, ports, Compose,
variables, worktrees, and deployment targets — each requirement with an ID. The modes that check a
stack against it read it — set up, worktrees, and native (§ Modes); diagnose and reset don't need it.
It also says where each fact lives; this skill writes only what a command it ran has shown.

**The templates in `<this skill's base directory>/templates/` are an example** that meets the
specification, for one app (`web`) and one backing service (`redis`). Start from them, then make the
project's files fit the project: its services, its commands, its deployment targets. Where a
template and the specification disagree, the specification wins. Name the requirement's ID whenever you report a gap or propose a change.

## Safety (always)

- **This project only.** Every command is scoped to this checkout's Compose project. Never prune or
  remove anything machine-wide — other projects and other worktrees' stacks live on the same Docker.
- **No secrets in the conversation.** Never run `docker compose config` without `--quiet` or
  `--services`, and never `docker inspect` a container's environment: both print resolved secrets.
  Never read `.env` (the settings deny it); `.env.example` names the variables, and `make urls` gives
  the ports. Logs only as `make logs` or `docker compose logs --tail 100 --no-color <service>` —
  never `-f`, which never returns.
- **Destructive steps wait for a yes.** Before anything that deletes containers, volumes, or images,
  name what is lost and how it comes back (the seed command), and wait for the developer. `make reset`
  is `docker compose down -v`; a project task that deletes data under a name other than `reset`
  (`DEV-SETUP.md` names each one) waits the same way. No permission prompt stops either: docker and
  make commands run without one (C9), so the yes in chat is the only check.
- **Published ports bind to `127.0.0.1`**, never every interface.
- **In Docker mode, commands run in the container, never on the host.** Tests, linters, the package
  manager, a one-off script: a named task first, as `AGENTS.md` § Quick reference writes it
  (`make test t=<file>`, `make lint f=<file>` once the tasks meet C3), and
  `make run cmd='<command>'` for what no task covers. It runs in the tools container (D6) without a
  prompt, in single quotes, with a `$` for the container as `$$`; a pipe goes inside the quotes
  (C10). The host's runtime and dependencies aren't the project's, and Docker mode
  needs none (M11): never install a missing tool there. In native mode `make run` runs on the host,
  without a prompt unless the project added `Bash(make run *)` to `permissions.ask`.
- **Only the developer changes the mode.** An agent runs every task in the configured mode —
  `make help` names the mode and the file in force — and when asked for another, it names the
  setting to change and stops (M10).

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`; in a
   project adopted before v2.0.0, `head -1 CLAUDE.md`). Unless its `modules:` list names `docker`, say
   "the docker module isn't installed in this project — `/adf:upgrade` offers it" and stop.

2. **Check where you are.** If `ops/agent/worktree.conf` (or `scripts/agent/worktree.conf`) exists
   and `git rev-parse --git-dir` equals `git rev-parse --git-common-dir`,
   this is the main checkout, which takes no edits. Say so in a line, read nothing more, and run
   `/adf:dispatch` now with `chore/dev-env` as the branch, without asking first: it moves this
   session to the task's worktree, where this command runs as the developer typed it.

3. **Read the facts, running nothing yet:** the Compose files (`compose.yaml`, `compose.yml`,
   `docker-compose.y*ml`, and their overrides), the Dockerfiles wherever they are, the `Makefile`,
   `ops/`, `.env.example`, `DEV-SETUP.md`, `AGENTS.md` § Quick reference,
   `.claude/rules/deployment.md`, `.claude/hooks/config.sh`, and `ops/agent/worktree.conf` when the
   project has it. Then `docker version` and `docker compose version`: this skill needs Compose v2
   (`docker compose`, with `--wait`). When the argument names the mode, read what § Modes lists for
   it with these reads.

4. **Name the mode** in one line — from the argument, or from the situation: no stack yet, or one that
   doesn't meet the specification → set up; parallel worktrees whose stacks collide → worktrees; the
   app on the host, or switching between the two → native; something fails → diagnose; stale or
   broken local data → reset. Then follow it, as § Modes says.

## Modes

Each mode but reset has its steps in a file beside this one. Read that file — and the specification
where the table says so — with step 3's reads when the argument names the mode, or as soon as step 4
names it, and follow it.

| Mode | What it does | Read |
|---|---|---|
| set up | Writes a missing stack from the templates, or audits one in the order the specification's § Conformance gives — either one through `/adf:triage` — then starts it, verifies it, and writes down what it verified | `<this skill's base directory>/set-up.md`, and the specification |
| worktrees | With parallel-agents: audits isolation (W1–W3), proposes the `worktree.conf` change, and verifies two worktrees' stacks side by side | `<this skill's base directory>/worktrees.md`, and the specification |
| native | Fills in running the app on the host (`ops/native/Makefile`), and starts it only in a checkout configured for native mode | `<this skill's base directory>/native.md`, and the specification |
| diagnose | `/adf:debug`'s order, applied to the environment: a failing signal, the simple things, ranked hypotheses, a fix that touches only this project | `<this skill's base directory>/diagnose.md` |
| reset | The smallest step that works, `make reset` last | § Mode: reset, below |

## Mode: reset

Take the smallest step that works, and re-run the signal after each:

1. `docker compose restart <service>`
2. `docker compose up -d --force-recreate <service>`
3. `make build`, then `make up`
4. `make down`, then `make up` — containers go, volumes stay
5. `make reset` — `docker compose down -v`, then `make up` — **last, and only after** listing this
   project's volumes (`docker volume ls --filter label=com.docker.compose.project=<project>`), naming
   the data each one holds and how it comes back, and the developer's yes.

Then run the migrations and the seed the way `DEV-SETUP.md` says, and re-run the signal. Never prune
machine-wide, never touch a shared service (`docs/SHARED-SERVICES.md`), and never
reset in the main checkout of a hub.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "`docker system prune -af` will clear it up" | It removes every project's stopped containers, unused images, and networks — other worktrees' and other repositories' included. Reset this project, smallest step first. |
| "Let me print `docker compose config` to see what's wrong" | It prints every resolved secret into the conversation. `--quiet` validates; `--services` lists. |
| "I'll read `.env` to see which mode this checkout uses" | `.env` holds credentials. `make help` names the mode in force. |
| "I'll add `make dev` for the native run" | Each mode's file defines the same tasks, so agents and worktrees never need to know which mode a developer chose. A task only one mode has goes in that mode's file. |
| "I'll read `.env` to find the port" | `.env` holds credentials, and a port Docker picked isn't in it at all. `make urls` looks it up. |
| "I'll start the stack now so it's ready" | Whether the task needs an environment is triage's call. Reading code and docs needs none. |
| "Port 3000 is taken — I'll kill whatever holds it" | It may be another worktree's stack or the developer's own process. Find the owner, report it, and ask. |
| "`3000:3000` is simpler — everyone knows the port" | Only one stack can hold it, so a second worktree's fails to start. Docker picks a free port and `make urls` shows it; a developer who wants a fixed one pins it in their `.env`. |
| "A fixed `container_name` makes it predictable" | It makes a second worktree's stack fail to start. The checkout's folder names the project. |
| "`env_file: .env` passes everything at once" | Every container gets every variable, credentials included, and nothing says which service needs what. Each service's `environment:` names what it gets. |
| "`make *` is allowed, so any task is safe to run" | The allow trusts the project's Makefile, and no prompt stops a task. One that deletes data waits for the developer's yes in chat, and a `logs` that follows needs fixing (C9). Check the task (`make -n <task>`) before you run one you haven't read. |
| "`make run cmd='yarn test src/x.test.ts'` is the quickest way to run one test" | `make test t=src/x.test.ts` runs the same thing through the task, in every mode, and a reviewer can read it. `make run` is for what no task covers (C10). |
| "The stack is in Docker, but `npm ci` on the host is quicker" | The host's runtime and dependencies aren't the project's, the command prompts, and Docker mode needs nothing on the host (M11). `make deps` installs into this checkout's volume, with no prompt (D7). |
| "The tool isn't in the container, so I'll install it on the host" | Then the next checkout and the CI don't have it, and the host drifts (M11). Add it to the project's dependencies or the Dockerfile's `tools` stage, through triage, or say what's missing and ask. |
| "This CLI needs the Docker socket, so I'll mount it in `tools`" | Then `make run` reaches the host's Docker, every project's containers, without a prompt (D5). The CLI gets a service of its own, and its command-taking task an ask rule (D8). |
| "`make lint` needs the stack, so I'll `make up` first" | The checks start the tools container themselves (D6). A check that needs `make up` is a gap to report. |
| "I'll write it as `cd app && make run cmd=\"echo $VAR\"`" | A `cd` points `make` at another folder, which may be another checkout in another mode, and the host's shell expands `$VAR` before `make` reads what's left. Run it from the checkout's root, in single quotes, with a `$` for the container as `$$`. |
| "`make run cmd='cat .env'` shows what the app sees" | It prints credentials into the conversation, on the host or in the container (V4), and no prompt stops it. `.env.example` names the variables. |
| "It's quicker to run the tests with `DEV_MODE=native`" | The mode is the developer's choice (M10). Run every task in the configured mode; if one can't run there, say what it needs and ask. |
| "The bug only shows in the production build, so I'll run the build and start commands on the host" | That runs a third environment, outside the configured mode, with the host's runtime and variables. `make prod` builds and serves it in the mode this checkout uses (C11), and `make urls` says where. With no `prod` task, say what you need and ask. |
| "`make reset` will fix the migration error" | It's `docker compose down -v`: it deletes the data. It's the last step, not the first; find the cause, and reset only as far as it needs. |
| "It started on the second try, so it's fixed" | A retry that works hides a race — usually a missing healthcheck or `depends_on` condition. Find why the first one failed. |

## Red flags (stop and reassess)

- You're in the main checkout of a hub
- A command names no project but would touch every project
- You're following logs, or about to read `.env` or a resolved config
- You're about to publish a fixed host port, or one on every interface
- You're about to set `DEV_MODE` or `SERVICES`, or change `DEFAULT_MODE` — even when asked (M10)
- You're editing `compose.yaml`, the `Makefile`, or `ops/` before triage
- The fix you're about to run deletes something, and the developer hasn't said yes

## Verification

- [ ] The module check and the hub check ran before anything else
- [ ] The stack meets the specification, or its gaps — each by requirement ID — went to the developer as a careful-lane change
- [ ] Every fact written down traces to a command run in this session
- [ ] No secret was printed: no unfiltered `config`, no `inspect` of the environment, no `.env`
- [ ] Every destructive step was scoped to this project, named what it removed, and had the developer's yes
- [ ] `make urls` shows each published service, answering
- [ ] Every task that deletes data is named as one in `DEV-SETUP.md`; a task other than `run` that runs a command it's given on the host has an ask rule; no task waits for input or follows (C9, C10)
- [ ] In Docker mode `make run cmd='<command>'` runs in the tools container with no prompt, and neither the app's service nor `tools` mounts anything of the host but the checkout, with its nested worktrees hidden (C10, D5, D6)
- [ ] In Docker mode `make deps`, `make lint`, `make typecheck`, and `make test` pass with the stack down and only `docker`, `git`, and `make` on the `PATH` (M11)
- [ ] `make test t=<file>` and `make lint f=<file>` run just that file, and `AGENTS.md` § Quick reference writes the one-file commands as the tasks take them (C3); until the tasks take them, the gaps name each task and what it takes (C3)
- [ ] With parallel-agents: two worktrees' stacks run side by side, each under its own project and ports
- [ ] In a checkout configured for native mode: `make up` answers on the URL `make urls` gives, with only the backing services in Docker, and `make down` stops it. In any other, native mode's file was read against M4–M8 and reported as not run (M10)
- [ ] After a fix or a reset, the failing signal passes

## Principles

- Signal first. A command that fails on the problem turns guessing into checking.
- This project only. The machine's Docker is shared with everything else the developer runs.
- Ports are looked up, never written down: Docker picks them, and `make urls` says where they are.
- Write down only what you verified — an unverified command in `DEV-SETUP.md` is a trap for the next person.
- The smallest reset that works.
