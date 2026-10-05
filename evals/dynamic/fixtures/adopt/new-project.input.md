# Input — adopt: a new project with no code yet

<!-- run: plugin-dir -->

This fixture verifies `/adopt`'s mode for a new project: in the first turn it recognizes there is
nothing to inspect, offers the first commit, and asks for the planned stack in one round; given the
answers, it adopts on a branch with the planned entries marked, the stack recorded as a proposed
decision, and no command presented as verified.

## Repository context to give the AI

A new project: a git repository with no commits and a README that says nothing is built yet. The
installer plugin is loaded from this checkout for the session only (`--plugin-dir`), so `/adopt`
takes the skeleton from the same checkout and nothing is installed on the machine. There is no
remote.

## Prompt to give the AI

```
/aplyca-adf:adopt
```

## Follow-up

```
Yes, make the first commit. The plan: Next.js 15 with TypeScript, pnpm, Vitest for unit tests and
Playwright end to end, hosted on Vercel, Contentful as the CMS. Branching: feature branches into
main. Requirements come as GitHub issues; no tracker server. One developer with one agent session
at a time, and no stakeholder updates. No sensitive areas yet — the newsletter signup will store
email addresses. Claude Code only, but use the committed install. No custom skills. Modules: github. The decider is the tech lead.
Go ahead with the adoption; don't push.
```

## What to do with this fixture

1. Run it with `run-session-evals.sh --suite adopt --cases new-project --models sonnet`.
2. Read the transcript (both turns) and the end state the runner appends.
3. Compare against `new-project.expected.md`.
