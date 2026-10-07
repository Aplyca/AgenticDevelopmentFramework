# 0022: The developer approves a change on the local environment before its pull request opens

- **Status:** accepted
- **Date:** 2026-10-06
- **Amends:** [0005](0005-outward-actions-and-draft-prs.md) — when a pull request opens

## Context

Decision 0005 put the human check after the pull request. It opens as a draft, a person exercises
the change on its preview, and only then is it marked ready. Before the pull request, the evidence was
the agent's: the tests, the full gate, and `/review`.

A team using the framework asked for a check before the pull request too. The developer runs the
change on the local environment, tests it by hand, and approves it, and only then does the pull
request open. What they found without it:

- **A pull request is outward.** It notifies reviewers, starts CI and a preview deployment, and on
  tracker-linked work it's what the requester hears about. A change that fails the first manual try
  costs all of that, and a second round.
- **The agent's evidence can't see what a person sees.** Tests prove what they assert. A layout that
  breaks at one width, a label that reads wrong, a flow that technically passes but confuses: these
  show up the first time someone uses the change.
- **The worktree can run it.** With the parallel-agents module, each task's worktree has its own env
  file and, where the project uses them, its own port. So checking one task locally doesn't collide
  with another (decision 0021).

## Decision

- **The local check.** When a change alters something a person can see or use, the agent starts it on
  the local environment (`AGENTS.md` § Quick reference; with the parallel-agents module,
  `scripts/agent/worktree-new.sh <branch>`, on the worktree's own port). It gives the developer the
  local URL and what to try: the acceptance criteria, or the fast lane's "done when".
- **The developer tests it by hand and approves it.** A fix they ask for goes in first, and the check
  repeats.
- **Only then does the pull request open.** `/open-pr` stops without the approval and offers the check.
  The pull request says what the developer tried, under "Local check".
- **Docs-only, CI-only, and answer-only work has nothing to run** and skips it. So does a refactor,
  which changes nothing a person can see.
- **Decision 0005 holds after the pull request:** it opens as a draft, and the QC on the preview comes
  before ready.

The rule is in `AGENTS.md` § Delivery rules and § 3, and in `.claude/rules/git-workflow.md`,
`/open-pr`, `/implement`, `/spec-workflow`, and `specs/README.md`.

## Consequences

- **Positive:**
  - A pull request opens on a change a person has already used, so the preview QC and the review start
    from something that works.
  - The pull request records what the developer tried.
  - Problems a person notices come back while the context is still in the session, before CI and
    reviewers spend anything.
- **Negative / cost:**
  - **The developer's time on every visible change, before the pull request.** The fast lane's typo
    fix gets a check too. It's short, but it's a step.
  - **The local environment has to start.** Setup and start time comes before each pull request, and a
    project that can't run locally can't follow the rule as written. It says so in its `AGENTS.md`
    and checks on the preview instead.
  - **Parallel tasks under check at once need separate environments.** That means the module's
    per-worktree ports and project names. Without them, two checks collide on one port.

## Alternatives considered

- **The preview check only, after the pull request (0005 as it was).** It catches the same problems,
  but after the pull request has notified people and started CI.
- **The agent checks the browser itself.** A useful extra step for a visual change, but it isn't a
  person's approval. The agent doesn't see what a requester would notice, and its own pass shouldn't
  count as one.
- **End-to-end tests in CI.** They're a signal, and they prove only what they assert. Worth having,
  but not a substitute for someone using the change.
