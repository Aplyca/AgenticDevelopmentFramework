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

This project uses **spec-driven, test-driven, AI-assisted development**.

1. **Spec first** — check `specs/` for existing specs. Write or update one before coding.
2. **Test next** — write tests that verify the spec's acceptance criteria.
3. **Implement** — build to pass the tests.
4. **Review** — run `@code-reviewer` and `@security-reviewer` before committing.

See [docs/ONBOARDING.md](docs/ONBOARDING.md) for the full workflow and team onboarding guide.

### AI agents

| Agent | Purpose |
|---|---|
| `@spec-writer` | Drafts feature specifications |
| `@code-reviewer` | Reviews code quality and conventions |
| `@security-reviewer` | Audits for security vulnerabilities |
| `@test-runner` | Writes and runs tests |
| `@architect` | Reviews architecture and design |
| `@debugger` | Investigates errors and failures |
| `@ux-reviewer` | Reviews UI against specs |

## Environment variables

<!-- List required env vars with descriptions, not values -->

| Variable | Purpose |
|---|---|
| `[VAR_NAME]` | [Description] |

Copy `.env.example` to `.env.local` and fill in the values.

## Deployment

[Describe how to deploy, or link to deployment docs.]

## Contributing

1. Create a feature branch from `main`
2. Write or update the spec in `specs/`
3. Implement with tests
4. Open a PR — CI runs tests and type checks automatically
