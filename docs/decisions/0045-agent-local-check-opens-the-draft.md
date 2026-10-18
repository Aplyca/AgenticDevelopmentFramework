# 0045: The agent's own local check opens the draft, and the developer tests after it, locally and on the preview

- **Status:** accepted
- **Date:** 2026-10-18
- **Amends:** [0022](0022-local-check-before-the-pull-request.md) — what opens the draft pull request;
  [0039](0039-check-locally-then-on-the-preview.md) — the agent's local check becomes the gate

## Context

Decision 0022 made the developer's approval in the local check the trigger for the draft pull
request. The agent started the change locally, gave the developer the URL, and waited. Decision 0039
added the agent's own walk of the changed flow, locally before that check and on the preview after
the draft opened.

That left the developer testing the same change twice, at two moments: locally before the pull
request, then on the preview before ready, with a deploy's wait in between. The session sat idle
until the first approval came. What 0022 guarded against had mostly gone: the pull request opens as a
draft, which asks no reviewer for attention, and since 0039 the agent runs the change before any push.

What must not go is the guarantee 0022 gave: **a change nothing has run never reaches a pull request.**

## Decision

- **The agent's local check is the gate for the push.** When a change alters something a person can
  see or use, the agent starts it on its checkout's own environment and walks the changed flow
  itself — every acceptance criterion, or the fast lane's "done when". Once it works, it pushes and
  opens the draft without asking. A step that fails is fixed and walked again first.
- **No local run, no push.** If the environment won't start, or a criterion needs something only a
  shared service has, the agent stops and tells the developer what blocks it. It never pushes to see
  the change on the preview instead.
- **Then the preview**, as in 0039: read-only, in a browser, recorded in the *Preview* line.
- **The agent leaves the local environment running** and reports where the developer can test the
  change: the local URL, the preview's, what to try on each, and what it verified and could not.
- **One report, after the preview walk.** The deploy waits in the background, so the developer hears
  once, with both URLs, instead of a draft now and a preview later. With no preview, or a deploy
  that failed, the report says so and gives the local instructions.
- **The developer tests after the draft opens,** on either environment. A fix they ask for goes on the
  same branch, walked locally again before the push. Their check still decides ready, and the agent
  never marks a pull request ready (0005).
- **Unchanged:** work with nothing to run opens its draft once the full gate and `/review` pass; the git
  guard refuses a pull request that isn't a draft; no nudges to review, ready, or merge (0039).

## Consequences

- **Positive:**
  - The developer tests once, with both environments ready, instead of approving locally and then
    QCing the preview.
  - The session doesn't wait on a person between the review and the pull request.
  - The pull request says what the agent walked locally and on the preview, so the developer's test
    starts from evidence.
- **Negative / cost:**
  - **A draft can open on a change no person has tried.** CI and a preview deploy run on it, and where
    the tracker links pull requests on its own, the requester can see it. The draft state, the agent's
    local walk, and the report are what stand in for the approval.
  - **A fix after the developer's test costs a push and a preview redeploy,** where before it cost only
    a local restart.
  - **The rule rests on the agent following `/open-pr`.** No hook can tell whether the flow was walked;
    the reviewer sees it in the *Local check* line.

## Alternatives considered

- **Keep the developer's approval as the gate (0022 as it was).** It catches what only a person sees
  before anything leaves the machine, at the cost of a second test and an idle session per change.
- **A project setting choosing between the two gates.** Declined for now: one rule is simpler to
  follow and to check. A team that wants the developer's approval first can ask the agent to wait in
  `AGENTS.md` § Delivery rules.
