# Contributing Guide

Welcome! We're glad you want to contribute. This document explains how to get started and what we expect from contributions.

## Getting started

1. Read the [Development Setup Guide](docs/getting-started/DEV-SETUP.md) to get your environment running
2. Read `CLAUDE.md` to understand the project, stack, and critical rules
3. Read [docs/ONBOARDING.md](docs/ONBOARDING.md) for the AI-assisted development workflow

## Development workflow

This project follows **spec-driven, test-driven development**:

1. **Check for existing specs** — read `specs/` before starting
2. **Write or update the spec** — if no spec covers your change, write one first
3. **Get approval** — specs must be reviewed before implementation begins
4. **Implement** — build according to the approved spec
5. **Write tests** — every acceptance criterion gets a test
6. **Review** — run code and security review before committing
7. **Open a PR** — one logical change per pull request

## Code standards

- Follow the conventions in `.claude/rules/` (auto-loaded by Claude Code, readable by anyone)
- Match the style of existing code in the file you're editing
- [Add project-specific standards here: formatting, naming, etc.]

## Commit messages

Use concise imperative mood. Explain *why*, not *what*:

```
feat: add email-based identity for Portal Aliados
fix: guard against non-array API response in GestionPortal
refactor: extract ProcessFlowDiagram into shared component
test: add e2e tests for email persistence flow
docs: update architecture overview with new data flow
```

Prefixes: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`.

## Pull request process

1. **Branch from `main`**: `git checkout -b feature/short-description`
2. **Keep PRs focused**: one feature, fix, or refactor per PR
3. **Write a clear description**: what changed, why, and how to test it
4. **Link the spec**: reference the spec file if one exists
5. **Ensure tests pass**: run the test suite before opening the PR
6. **Request review**: tag the appropriate reviewer(s)
7. **Address feedback**: respond to all comments, push fixes as new commits

## Testing requirements

- New features must have tests covering each spec acceptance criterion
- Bug fixes must include a test that reproduces the bug
- Tests must not depend on external services being up (mock everything)
- [Add project-specific test requirements: coverage targets, test framework, etc.]

## Security

- Never commit credentials, API keys, or secrets
- Validate all user input at API boundaries
- Never expose internal error details to the client
- Review [docs/security/](docs/security/) for the project's security practices
- Report security vulnerabilities privately to [security contact email or process]

## Documentation

- Update documentation when your change affects architecture, APIs, or setup procedures
- Add new terms to [docs/GLOSSARY.md](docs/GLOSSARY.md) when introducing domain concepts
- Write an [ADR](docs/architecture/decisions/) when making a significant technical decision

## Questions?

- [e.g., Ask in #project-name on Slack]
- [e.g., Open a GitHub Discussion]
- [e.g., Tag @team-lead in your PR]
