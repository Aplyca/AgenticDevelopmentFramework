# 0039: An agent checks a change locally first, then on the pull request's preview

- **Status:** accepted
- **Date:** 2026-10-15
- **Amends:** [0022](0022-local-check-before-the-pull-request.md) — what the agent checks itself, around the developer's local check

## Context

Decision 0022 made the developer's local check the gate before the draft pull request, and the
developer's QC on the preview the gate before ready. Neither said what the agent checks itself, or
in what order. `AGENTS.md` said only "browser checks only when asked or for a visual change — the
human QC on the preview is the real check".

Testing in an adopting project, the developer kept asking agents to "push it and check on the
preview". Agents went to the preview on their own too, sometimes before checking the change locally.
They opened its pages, called its API, and once ran the end-to-end suite against it. A failure found
there cost a deploy round-trip. The preview is shared, and it can reach real services.

## Decision

- **Locally first.** Before the developer's local check, and before any push, the agent runs the
  change on its checkout's own environment and walks the changed flow itself.
- **Then on the preview,** when the project has previews and the change alters something a person
  sees or uses:
  - The agent waits for the draft's preview to deploy, in the background, never with a polling
    loop.
  - It walks the same flow there, in a browser, read-only: nothing that reaches a person or shared
    data unless the developer asks. Never the end-to-end suite, which creates data and runs only
    against the local stack.
  - It records what it saw in the pull request's *Preview* line.
  - A difference from local goes to the developer with what differs. A retried deploy doesn't fix
    it.
- **Where previews deploy** is a line in `AGENTS.md` § Quick reference. "None" turns the second
  step off.
- **Evidence, not the QC.** The developer's check on the preview still decides ready, and the agent
  never marks a pull request ready (0005).

## Consequences

- **Positive:**
  - The developer gets a change the agent has already walked twice, so their QC finds what only a
    person sees.
  - A problem that only the platform shows — configuration, environment variables, data — is caught
    before review.
- **Negative / cost:**
  - **Waiting for the deploy** adds minutes to the end of a task. It runs in the background, and the
    session can report the pull request meanwhile.
  - **A read-only walk can't exercise a flow that writes.** The local check covers that, and the
    body says what the preview walk left out.

## Alternatives considered

- **Run the smoke suite against the preview.** Declined. Smoke tests create data, and the preview is
  shared and may reach real services. The e2e specification keeps the suite on the local stack.
- **Only the developer checks the preview.** Declined. It's the developer's gate, but an agent's walk
  first catches platform-only problems while the agent still has the context to fix them.
