# Input — adopt: a project whose own instructions carry a process of their own

<!-- run: plugin-dir -->

This fixture verifies `/adf:adopt`'s compatibility pass (decision 0099): given a `CLAUDE.md` written
before the framework, it classifies each line and shows that table beside the facts table before
writing anything. A project fact moves into `AGENTS.md`, and process the framework owns ("ask me
before every commit", "confirm each step") is dropped. A line the framework already says is dropped as
a duplicate, the override the framework honors (a person marks pull requests ready) is kept in
§ Delivery rules, and the line it can't classify is asked about once.

## Repository context to give the AI

A small Next.js project with one commit on `main`: `package.json` (pnpm, Vitest, ESLint), a source
file under `src/newsletter/`, a frozen `legacy/` folder, and a `CLAUDE.md` that mixes the stack and
commands with a process of its own. The installer plugin is loaded from this checkout for the session
only (`--plugin-dir`). There is no remote.

## Prompt to give the AI

```
/adf:adopt
```

## Follow-up

```
The facts are right. Approve the compatibility table as you proposed it. The content-team line is a
sensitive area, not a review rule: `src/newsletter/` holds subscriber data. Branching: feature
branches into main. Requirements come as GitHub issues; no tracker server, live on the merge. One
developer with one agent session at a time, and no stakeholder updates. No connected services. We work
in Claude Code only, so use the packaged install. No custom skills and no modules. The decider is the
tech lead. Go ahead with the adoption; don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite adopt --cases legacy-instructions --models sonnet`.
2. `inspect.sh` checks where each `CLAUDE.md` line went and prints ✓ or ✘ under the end state.
3. Compare against `legacy-instructions.expected.md`.
