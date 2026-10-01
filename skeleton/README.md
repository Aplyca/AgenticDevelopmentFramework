# [Project Name]

> [One-line description of what this project does and why it exists.]

## Status

<!-- Remove the rows that don't apply -->
| | |
|---|---|
| **Stage** | PoC / MVP / Production |
| **Stack** | [e.g., Next.js 15, React 19, TypeScript, PostgreSQL] |
| **Team** | [Team name or owners] |

## Getting started

### Prerequisites

- [e.g., Node.js 20+, Docker, etc.]

### Setup

```bash
git clone [repo-url]
cd [project-name]
[install command, e.g., npm install]
```

### Run locally

```bash
[dev command, e.g., make dev]
```

The app will be available at `http://localhost:[port]`.

### Run tests

```bash
[test command, e.g., npx playwright test]
```

## Project structure

```
[Replace with your project's actual directory layout]
```

## Development workflow

This project uses **multi-perspective spec-driven, test-driven, docs-first development**, with AI
agents working under the same rules as people:

1. **Triage** — read the task in full; decide what it needs before setting anything up, including
   its **lane**: fast (a precise change — edit, prove it with a test, commit), careful (the same in a
   risk area, plus its checklist and a confirmation), or full (something to decide — the steps below).
2. **Spec folder** (full lane) — `specs/NNN-<slug>/`: requirements from every role (`spec.md`), the
   plan and its change surface (`plan.md`), and commit-sized tasks (`tasks.md`).
3. **Approval gate** — scope, change surface, and assumptions are signed off before implementation.
4. **Docs first, then one task at a time** — each task's test fails first, then passes; one commit per task.
5. **Review and a draft pull request** (every lane) — QC'd by a person, then marked ready.

How it works in detail: [AGENTS.md](AGENTS.md), [specs/README.md](specs/README.md),
[docs/SPEC-MODEL.md](docs/SPEC-MODEL.md), and [CONTRIBUTING.md](CONTRIBUTING.md).

### AI agents and skills

`AGENTS.md` is read by every AI coding tool. Claude Code adds skills (type `/`), specialized agents
(type `@`), dynamic workflows (`/deep-…`), and guardrail hooks — see `CLAUDE.md`.

## Environment variables

<!-- List required env vars with descriptions, not values -->

| Variable | Purpose |
|---|---|
| `[VAR_NAME]` | [Description] |

Copy `.env.example` to `.env.local` and fill in the values.

## Deployment

[Describe how to deploy, or link to deployment docs.]

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the branching model, pull request flow, and standards.
