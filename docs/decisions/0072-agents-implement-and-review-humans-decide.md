# 0072: Agents implement and review; humans decide

- **Status:** accepted
- **Date:** 2026-11-08
- **Amends:** [0039](0039-check-locally-then-on-the-preview.md) — the agent reviews the change on the
  preview too, and requests the project's reviewers; [0045](0045-agent-local-check-opens-the-draft.md)
  and [0070](0070-the-agent-marks-its-pull-request-ready.md) — `/review` runs in every lane, and the
  developer reviews on the preview, not the local environment. Also v2.6.0's rule that `/review`
  runs before the draft in the full lane only, and in the fast and careful lanes when asked

## Context

- **The agent's work and the developer's overlapped, and the handoff between them was silent.**
  After decision 0070, the agent tests a change locally and on the preview and marks its pull request
  ready, but nobody is asked to look at it: 0039 ruled out requesting reviewers, to stop agents
  nagging the developer in chat. A ready pull request waited until someone noticed it.
- **The agent tested, but reviewed only in the full lane.** `/review` ran before the draft in the full
  lane and for docs or CI work; in the fast and careful lanes, only when the developer asked. On the
  preview, the agent walked the acceptance criteria and nothing else — not how the page looked, read,
  or behaved beyond them.
- **The developer was sent to two environments.** The report gave the local URL and the preview's,
  though the local environment is where the agent builds and tests, and since decision 0071 it's
  stopped once the pull request is ready.
- **The framework spoke GitHub.** `/open-pr` named `gh` commands for every step but the first, and
  `guard-git.sh` checked `gh pr create` for `--draft` but not `glab mr create`, so the draft rule 0070
  relies on held on GitHub only.

## Decision

- **The principle: agents implement and review; humans decide.** Each environment has its role:

  | Environment | The agent | The developer |
  |---|---|---|
  | **Local** | Implements and tests; reviews the change (`/review`) | — |
  | **Preview** | Tests and reviews, when there is one and it can reach it | Reviews, approves, and merges |

- **`/review` runs in every lane, before the push,** in proportion to the lane — what it already
  reads for fast and careful work. Its findings are fixed before the push. It replaces "when the
  developer asks" for the fast and careful lanes.
- **On the preview, the agent tests and reviews — if possible and applicable.** Possible: the project
  has previews and the agent can reach them; a preview behind a sign-in it doesn't have is skipped,
  and the report says so. Applicable: the change has something a person sees. The review adds to the
  walk of the criteria: the changed page at a phone's width and a desktop's, its copy, the browser
  console's errors, basic accessibility (labels, focus, contrast that's visibly off), and any
  difference from the local run. Still read-only. A finding is fixed on the branch before ready, or
  listed under *Not verified*.
- **The developer reviews on the preview.** The report sends them there, with what to try; the local
  environment is the agent's. With no preview, they review the pull request itself — the diff and the
  evidence — and the report says how to run it locally if they want to.
- **Ready is the handoff, and it asks a person.** Right after marking the pull request ready, the
  agent requests the project's reviewers, from the **Reviewers** line in `CONTRIBUTING.md`:
  usernames, which both hosts take; a GitHub team; `CODEOWNERS`, when GitHub requests them on its
  own; or `none`. Never the author: GitHub refuses it, and a self-review decides nothing. On a GitLab tier
  that takes one reviewer — Premium and Ultimate take several — it requests the first and says so. A draft requests no one.
- **After a fix that answers a review,** once the pull request's checks pass again, the agent
  re-requests that reviewer's review.
- **No nudges in chat stays** (0039): the report names the developer's next step once, and the agent
  doesn't remind them or offer to merge.
- **GitHub and GitLab both.** `/open-pr`'s steps name each action with its `gh` command; a reference
  file beside the skill gives the `glab` one, read when the remote is on GitLab. `guard-git.sh`
  refuses a `glab mr create` without `--draft`, as it does a `gh pr create`. The rules name actions —
  mark it ready, request the reviewers — not one host's commands.

## Consequences

- **Positive:**
  - Every change reaches a person reviewed by the agent, locally and on the preview, and the person
    hears about it from the host when it's ready — not by checking.
  - The developer has one place to review: the preview, the same build that ships.
  - A GitLab project keeps the draft rule and gets every step's command.
- **Negative / cost:**
  - **`/review` in the fast and careful lanes** adds a skill run to every small change, in the same
    conversation. It reads in proportion to the lane, so it stays a fraction of the full lane's.
  - **The preview review is a judgment, not a test.** It catches what's visibly wrong, and misses
    what only a person who knows the product sees; the developer's review is still the gate.
  - **A reviewer request notifies people** on the agent's say-so. It comes once, at ready, after the
    agent's tests and review, and only to the people the project named.
  - **The GitLab path isn't exercised by the session evals,** which simulate `gh`; static checks keep
    the reference file covering every action.
  - **The rest of the framework still speaks `gh`** — the `pr-state.sh` hook and a few skills. That's
    a change of its own.

## Alternatives considered

- **Keep no reviewer requests (0039 as it was).** Declined: ready then reaches no one, and the
  handoff the principle needs doesn't happen.
- **Request the developer who ran the session.** Not possible: they're the pull request's author.
  The report already names their next step.
- **Request a review as soon as the preview deploys, while it's a draft.** Declined: a draft means
  the agent is still testing; a person asked then reviews work that may change.
- **Run `@adf:ux-reviewer` on the preview for every UI change.** Declined for now: a separate agent
  per change costs more than the visible checks above. A team can ask for it.
- **`/review` in the full lane only (v2.6.0's split).** Declined: "agents review" holds in every lane;
  the lane sets how much it reads, not whether it runs.
