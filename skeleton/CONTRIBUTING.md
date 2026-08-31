# Contributing Guide

Welcome! We're glad you want to contribute. This document explains how to get started and what we expect from contributions.

## Getting started

1. Read the [Development Setup Guide](docs/getting-started/DEV-SETUP.md) to get your environment running
2. Read `CLAUDE.md` to understand the project, stack, and critical rules
3. Read [docs/ONBOARDING.md](docs/ONBOARDING.md) for the AI-assisted development workflow

## Development workflow

This project follows **multi-perspective spec-driven, test-driven, docs-first development**:

1. **Check for existing specs** — read `specs/` before starting
2. **Write or update the spec** — use the multi-perspective spec template at `specs/_template.md`. Required sections (Business, Functional, Out of scope, Security, Testing, Documentation, plus Accessibility for UI and Privacy for personal data) are enforced before approval. See `docs/SPEC-MODEL.md` for the model.
3. **Get spec approval** — specs must be reviewed before tests, docs, or code begin. Commit with `spec:` prefix.
4. **Write tests** — every acceptance criterion AND every testable requirement (Security, A11y, Perf) gets a test. Tests are written BEFORE implementation (TDD). Run them — they should fail. Commit with `test:` prefix.
5. **Write user-facing docs** — if the spec lists pre-implementable docs (admin guides, API contracts, end-user copy defaults), write them now. Commit with `docs:` prefix. Skip cleanly if none.
6. **Implement** — build according to the approved spec until all tests pass. Reconcile docs with reality as you go (small adjustments fold into `feat:` commit; meaningful revisions get a separate `docs:` commit).
7. **Review** — run code, security, and (for UI) UX review before committing
8. **Open a PR** — one logical change per pull request

## Code standards

- Follow the conventions in `.claude/rules/` (auto-loaded by Claude Code, readable by anyone)
- Match the style of existing code in the file you're editing
- [Add project-specific standards here: formatting, naming, etc.]

## Commit messages

Use concise imperative mood. Explain *why*, not *what*:

```
feat: add newsletter signup endpoint
fix: guard against non-array API response in topics endpoint
refactor: extract SignupForm into shared component
test: add e2e tests for signup persistence flow
docs: update architecture overview with new data flow
```

Prefixes: `spec`, `test`, `docs`, `feat`, `fix`, `refactor`, `chore`, `style`. The first four follow the workflow phase order; see `.claude/rules/git-workflow.md` for details.

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
