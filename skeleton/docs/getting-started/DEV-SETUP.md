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
cp .env.example .env.local
```

Edit `.env.local` and fill in the required values:

| Variable | Description | Where to get it |
|---|---|---|
| [e.g., DATABASE_URL] | [PostgreSQL connection string] | [Local Docker or team shared DB] |
| [e.g., API_KEY] | [External service API key] | [Ask team lead or check 1Password] |

### 4. Set up local services

```bash
[e.g., docker compose up -d]
```

This starts:
- [e.g., PostgreSQL on port 5432]
- [e.g., Redis on port 6379]

### 5. Initialize the database

```bash
[e.g., npm run db:migrate]
[e.g., npm run db:seed]  # Optional: load sample data
```

### 6. Start the development server

```bash
[e.g., npm run dev]
```

The app will be available at `http://localhost:[port]`.

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
`CLAUDE.md` adds the Claude Code layer (skills, agents, workflows, hooks).

```bash
claude  # Start Claude Code in the project directory
```

**Claude Code needs no install step.** Open a session in the project — in the terminal, the desktop
app, or an IDE — and accept the prompt to trust the folder. The committed `.claude/settings.json`
then turns on the hooks, the permissions, and the framework's plugin, `aplyca-adf`, at the release
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

<!-- CUSTOMIZE: one documented way to install, run, test, and lint — make targets, package scripts,
     just recipes — used identically by developers and agents. Agents can only run what is written
     down; every manual step an agent can't discover is a step it will guess. -->

| Task | Command |
|---|---|
| Install | `[command]` |
| Run | `[command]` |
| Test | `[command]` |
| Lint / typecheck | `[command]` |

## Troubleshooting

### [Common issue 1: e.g., Port already in use]

```bash
[e.g., lsof -i :3000  # Find what's using the port]
[e.g., kill -9 <PID>  # Stop the process]
```

### [Common issue 2: e.g., Database connection refused]

[e.g., Make sure Docker is running: `docker ps`]
[e.g., Restart services: `docker compose restart`]

### [Common issue 3: e.g., Dependencies fail to install]

```bash
[e.g., rm -rf node_modules package-lock.json]
[e.g., npm install]
```

### Still stuck?

- Check the project's FAQ, if it has one
- Ask in [team channel]
- Tag [team lead or maintainer]
