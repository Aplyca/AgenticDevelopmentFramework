# Development Environment Setup

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: developer environment setup -->

## Prerequisites

| Requirement | Version | Check command |
|---|---|---|
| [e.g., Node.js] | [e.g., 20+] | `node --version` |
| [e.g., Docker] | [e.g., 24+] | `docker --version` |
| [e.g., Git] | [e.g., 2.40+] | `git --version` |

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
[e.g., npm install]
```

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
[e.g., make up      # the app in Docker, at the URL make urls shows]
[e.g., make native  # or the app on your machine, against the services in Docker]
```

The app will be available at [e.g., the URL `make urls` or `make native` prints].

### 7. Verify everything works

```bash
[e.g., npm test]
```

All tests should pass. If not, see [Troubleshooting](#troubleshooting) below.

## First task

Once your environment is working, try this to build confidence:

1. [e.g., Pick an issue labeled "good first issue"]
2. [e.g., Create a branch: `git checkout -b your-name/first-task`]
3. [e.g., Make the change, write a test, open a PR]

## IDE setup

**Recommended:** [e.g., VS Code with these extensions:]
- [e.g., ESLint, Prettier, TypeScript]
- [e.g., Claude Code extension]

**Optional settings:**
- [e.g., Format on save: enabled]
- [e.g., Default formatter: Prettier]

## AI-assisted development

This project is set up for AI coding agents: `AGENTS.md` is the shared instruction file, and
`.claude/rules/claude-code.md` adds the Claude Code layer (skills, agents, workflows, hooks). Claude
Code reads both on its own (v2.1.281 or later). Don't add a `CLAUDE.md` or `CLAUDE.local.md`: Claude
Code would read it instead of `AGENTS.md`.

```bash
claude  # Start Claude Code in the project directory
```

**Claude Code needs no install step.** Open a session in the project — in the terminal, the desktop
app, or an IDE — and accept the prompt to trust the folder. The committed `.claude/settings.json`
then turns on the hooks, the permissions, and the framework's plugin, `adf`, at the release
the project pins; Claude Code downloads the plugin, and `/plugin` lists it. Don't install it yourself,
and never at user scope, which turns it on in every project on your machine. Cloud sessions don't
load it.

Key commands:
- `/triage [task link]` — read a task in full and decide what it needs, before setting anything up
- `/write-spec [feature]` → `/write-plan [spec folder]` — spec, plan, and the approval gate
- `/implement [spec folder]` — one task at a time: test red, code, test green, commit
- `/review` — review a change before delivering it
- `/open-pr` — push and open a draft pull request (on its own, once you approve the local check)
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
| Install | `[command]` |
| Run / stop | `[e.g., make up · make down]` |
| Where it runs | `[e.g., make urls]` |
| Run on the host | `[e.g., make native]` |
| Logs | `[e.g., make logs]` |
| Test | `[e.g., make test]` |
| Lint / typecheck | `[e.g., make lint]` |

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

```bash
[e.g., rm -rf node_modules package-lock.json]
[e.g., npm install]
```

### Still stuck?

- Check the project's FAQ, if it has one
- Ask in [team channel]
- Tag [team lead or maintainer]
