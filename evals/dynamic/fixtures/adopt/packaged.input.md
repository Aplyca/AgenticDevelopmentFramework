# Input — adopt: a new project on the packaged install

<!-- run: plugin-dir -->

This fixture verifies `/adopt` with the packaged install (decision 0016): given a team that works in
Claude Code only, it commits only the project's own layer — no framework skills, agents, workflows,
or hook scripts — pins the `aplyca-adf` plugin to the newest release tag, stamps
`install: packaged`, and tells people the names they type.

## Repository context to give the AI

The same new project as `new-project`: a git repository with no commits and a README that says
nothing is built yet. The installer plugin is loaded from this checkout for the session only
(`--plugin-dir`). The framework's releases are tagged on GitHub, so the packaged install is available.
There is no remote.

## Prompt to give the AI

```
/aplyca-adf:adopt
```

## Follow-up

```
Yes, make the first commit. The plan: Next.js 15 with TypeScript, pnpm, Vitest for unit tests and
Playwright end to end, hosted on Vercel, Contentful as the CMS. Branching: feature branches into
main. Requirements come as GitHub issues; no tracker server. One developer with one agent session
at a time, and no stakeholder updates. No sensitive areas yet. We work in Claude Code only, so use
the packaged install. No custom skills and no modules. The decider is the tech lead. Go ahead with
the adoption; don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite adopt --cases packaged --models sonnet`.
2. `inspect.sh` checks the packaged layout and prints ✓ or ✘ under the end state.
3. Compare against `packaged.expected.md`.
