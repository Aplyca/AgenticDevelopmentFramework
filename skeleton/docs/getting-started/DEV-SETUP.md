# Development Environment Setup

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: developer environment setup -->

## Prerequisites

| Requirement | Version | Check command |
|---|---|---|
| [e.g., Node.js] | [e.g., 20+] | `node --version` |
| [e.g., Docker] | [e.g., 24+] | `docker --version` |
| [e.g., Git] | [e.g., 2.40+] | `git --version` |
| [e.g., make] | [e.g., 3.81+] | `make --version` |

[e.g., In Docker mode, the default here, Docker, Git, and make are all your machine needs: the
runtime, the dependencies, and every check run in containers. Native mode needs the runtime too.]

**Operating system:** [e.g., macOS 14+, Ubuntu 22.04+, Windows 11 with WSL2]

**Hardware:** [e.g., 8 GB RAM minimum, 16 GB recommended]

## Setup steps

### 1. Clone the repository

```bash
git clone [repo-url]
cd [project-name]
```

### 2. Install dependencies

```bash
[e.g., make deps  # into this checkout's Docker volume: nothing is installed on your machine]
```

[e.g., In Docker mode the dependencies live in a Docker volume, one per checkout, and the package
manager's cache in another that every checkout shares. The empty `node_modules/` folder in the
checkout is where the volume mounts: leave it. After a lockfile change, `make deps` again.]

### 3. Set up environment variables

```bash
[e.g., make env  # creates .env from .env.example]
```

Edit `.env` and fill in the required values. It stays out of git; `.env.example` names every
variable. [e.g., It's the one env file: Docker Compose reads it, and so does the app when it runs on
the host.]

| Variable | Description | Where to get it |
|---|---|---|
| [e.g., DATABASE_URL] | [PostgreSQL connection string] | [Local Docker or team shared DB] |
| [e.g., API_KEY] | [External service API key] | [Ask team lead or check 1Password] |

### 4. Set up local services

```bash
[e.g., make up    # starts the stack and waits until it's healthy]
[e.g., make urls  # where each service is]
```

This starts:
- [e.g., the app, `web`]
- [e.g., PostgreSQL, `db`]

[e.g., Docker picks each service's host port when it starts, so this checkout's stack runs beside
any other — another worktree's included — and `make urls` says where each one is. To keep a port
fixed, set its `<NAME>_PORT` in `.env`, such as `APP_PORT=3000`.]

### 5. Initialize the database

```bash
[e.g., npm run db:migrate]
[e.g., npm run db:seed]  # Optional: load sample data
```

### 6. Start the development server

```bash
[e.g., make up      # the app, in this checkout's mode, at the URL make urls shows]
[e.g., make logs    # its last lines]
```

[e.g., `DEV_MODE` in `.env` sets where the app runs: `docker` (the default here), or `native` for the
app on your machine against the services in Docker — which needs [runtime and version] installed, and
`make build` once to install its dependencies. For a service you run on your machine yourself, pin
its port in `.env` (`REDIS_PORT=6379`). `make help` names the mode in force.]

The app will be available at [e.g., the URL `make up` and `make urls` print].

### 7. Verify everything works

```bash
[e.g., make test  # in the tools container, with the stack up or not]
```

All tests should pass. If not, see [Troubleshooting](#troubleshooting) below.

## First task

Once your environment is working, try this to build confidence:

1. [e.g., Pick an issue labeled "good first issue"]
2. [e.g., Create a branch: `git switch -c docs/first-task`]
3. [e.g., Make the change, write a test, open a PR]

## IDE setup

**Recommended:** [e.g., VS Code with these extensions:]
- [e.g., ESLint, Prettier, TypeScript]
- [e.g., Claude Code extension]

**Optional settings:**
- [e.g., Format on save: enabled]
- [e.g., Default formatter: Prettier]

[e.g., In Docker mode the dependencies aren't on your machine, so the editor resolves no package: no
autocomplete or library types from them, and no on-save lint or format with the project's own
tools. Run `make lint f=<file>` and `make format f=<file>` instead.]

## AI-assisted development

This project is set up for AI coding agents: `AGENTS.md` is the shared instruction file, and
`.claude/rules/claude-code.md` adds the Claude Code layer (skills, agents, workflows, hooks). Claude
Code reads both on its own (v2.1.281 or later). Don't add a `CLAUDE.md` or `CLAUDE.local.md`: Claude
Code would read it instead of `AGENTS.md`.

```bash
claude  # Start Claude Code in the project directory
```

**Claude Code usually needs no install step.** Open a session in the project — in the terminal, the
desktop app, or an IDE — and accept the prompt to trust the folder. The committed
`.claude/settings.json` then turns on the hooks, the permissions, and the framework's plugin, `adf`,
at the release the project pins; Claude Code downloads the plugin, and `/plugin` lists it. Cloud
sessions don't load it.

If typing `/adf:` offers nothing, the plugin didn't download — on a machine whose copy of the
`aplyca` marketplace is older than this project's release, for instance, since Claude Code keeps
one copy for every project. From the project's folder, refresh it and install each plugin
`.claude/settings.json` turns on, then start a new session:

```bash
claude plugin marketplace update aplyca
claude plugin install adf@aplyca --scope project
claude plugin install adf-dev@aplyca --scope project      # only if the settings already turn it on
claude plugin install adf-connect@aplyca --scope project  # only if the settings already turn it on
```

They only download what the settings already turn on, so the file doesn't change. For a plugin they
don't turn on, the command isn't a way to turn it on: it writes the `enabledPlugins` entry itself and
can rewrite the whole file. Turning one on is a one-line change to the committed settings, made on a
work branch and merged by pull request. Always pass `--scope project`: without it, Claude Code
installs at user scope, which turns the plugin on in every project on your machine.

Key commands:
- `/triage [task link]` — read a task in full and decide what it needs, before setting anything up
- `/write-spec [feature]` → `/write-plan [spec folder]` — spec, plan, and the approval gate
- `/implement [spec folder]` — one task at a time: test red, code, test green, commit
- `/review` — review a change before delivering it
- `/open-pr` — push and open a draft pull request (on its own, once the agent has checked the change locally)
- `@code-reviewer review [file]` — an isolated, read-only review
- `@debugger [error message]` — investigate a bug

How work flows end to end: `AGENTS.md` § How work flows, and `specs/README.md`.

## Command surface for humans and agents

<!-- CUSTOMIZE: one documented way to install, run, test, and lint — a Makefile at the root (`make
     help` lists its tasks), or the stack's own scripts — used identically by developers and agents.
     Agents can only run what is written down; every manual step an agent can't discover is a step it
     will guess. -->

| Task | Command |
|---|---|
| List the tasks | `[e.g., make help]` |
| Install | `[e.g., make deps]` |
| Run / stop / down | `[e.g., make up · make stop (keeps containers and data) · make down (removes containers; data stays)]` |
| Where it runs | `[e.g., make urls]` |
| Run on the host | `[e.g., DEV_MODE=native in .env, then make up]` |
| The production build, locally | `[e.g., make prod — make urls shows it, make logs s=web-prod]` |
| Logs | `[e.g., make logs]` |
| Test | `[e.g., make test]` |
| Lint / format / typecheck | `[e.g., make lint · make format · make typecheck]` |
| Anything else, in the tools container | `[e.g., make run cmd='<command>']` |

## Troubleshooting

### [Common issue 1: e.g., Port already in use]

[e.g., With Docker, only a port pinned in `.env` can be taken; Docker picks free ones for the rest.]

```bash
[e.g., docker ps --filter publish=3000  # another stack holding it, a worktree's perhaps]
[e.g., lsof -iTCP:3000 -sTCP:LISTEN     # or a process of yours]
```

[e.g., Stop it only if it's yours, or empty the port in `.env` and let Docker pick one.]

### [Common issue 2: e.g., Database connection refused]

[e.g., Make sure Docker is running: `docker ps`]
[e.g., Restart services: `make down`, then `make up`]

### [Common issue 3: e.g., Dependencies fail to install]

[e.g., In Docker mode the dependencies are this checkout's Docker volume, `<project>_deps`, where
`<project>` is this checkout's name in `docker compose ls` — a worktree's is the one its `.env` sets.
To start it over: stop the stack, remove the volume, and install again.]

```bash
[e.g., make down]
[e.g., docker volume rm <project>_deps]
[e.g., make deps]
```

### Still stuck?

- Check the project's FAQ, if it has one
- Ask in [team channel]
- Tag [team lead or maintainer]
