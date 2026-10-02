# 0011: Three lanes — ceremony follows risk and uncertainty, not size

- **Status:** accepted; partly superseded by [0014](0014-test-first-in-every-lane.md) (the fast and careful lanes are test-first)
- **Date:** 2026-10-01
- **Refines:** [0001](0001-spec-folders-as-record-of-intent.md) and [0002](0002-one-approval-gate-on-the-change-surface.md) — the spec folder and the approval gate apply to the full lane

## Context

Records 0001–0004 made the spec folder, the plan, and the approval gate the path for any change with
"something to decide", and a change request on delivered work always amended its folder through the
full flow. In practice, that routing sent small, precise adjustments — the most common request on a
delivered client feature — through spec, plan, tasks, analysis, and the gate.

Transcripts of 48 agent sessions in two production projects (September 2026) showed what that
costs:

- **A session costs roughly calls × context.** Median cost was about $0.06 per call; ~47% went to
  re-reading cached context, ~27% to writing it, ~17% to output. The framework's own always-loaded
  instructions were 5–7k of a 46–66k-token starting context, and its hooks 60–140 ms per tool call —
  negligible.
- **Small fixes routed through the full process cost several times more.** A one-word fix in a
  database trigger took 97 calls and about an hour, with 7 of its 11 edits in spec files; a small
  permission fix took 110 calls, with 8 spec edits for one migration. A developer stopped one session
  to ask why it was writing specs for a change the task had fully described.
- **The spec work in those sessions wasn't where defects were caught.** The extra calls went into
  recording decisions already made by the requester, not into tests or verification.
- **Waiting and long sessions multiply the cost.** In sessions over ~90 calls the average call carried
  145–190k tokens. Waits past the cache lifetime re-wrote the whole context, and one bug fix spent
  210 calls on agent-driven browser checks.
- **Developers have intuition the triggers can't see** — a fragile module, a client who changes their
  mind, a past incident — and had no first-class way to ask for more care.

## Decision

- **Three lanes**, defined once in `skeleton/specs/README.md` § Lanes and chosen at triage:
  - **Fast** — a precise request (or a bug with a clear cause restoring intended behavior), about 3
    files or fewer, no escalation trigger: restate the request with "done when…" and the files,
    search every use of what changes, edit, prove it with a targeted test, commit.
  - **Careful** — the same in a risk area (a migration, authorization, personal data, payments, a
    public contract, shared code, infrastructure, or a project-listed sensitive area): plus that
    area's checklist, `@security-reviewer` where it applies, and the developer's yes on the risky part.
  - **Full** — something to decide, a new feature, or work across layers: the spec-driven flow of
    0001–0003, unchanged.
- **The controls that find defects run in every lane:** a test that proves the change, the guardrail
  hooks, CI, a draft pull request reviewed by a person, and the human QC on the preview. The fast lane
  drops paperwork, not proof.
- **Escalation is checked twice:** at triage, and while working — a diff that grows past the stated
  files, a test failing outside the area, or a change no test can prove stops the work and moves it up
  a lane, keeping what's done. `/review` checks that the diff fits its lane.
- **Change requests come in two weights.** A precise adjustment leaves a **light** `CR N` entry in
  `spec.md`, committed with the change; one with something to decide is a full change request.
- **The developer decides too.** Raising the lane is always honored. Lowering it is honored for size
  and judgment; a risk trigger keeps its checklist unless the developer explicitly accepts the risk,
  which the pull request records. The constitution and the hooks hold in every lane. Other effort —
  questions first, `/evaluate`, the effort level or model, extra verification — is requested the same
  way, with its cost documented in `COST-MODEL.md` § Effort.
- **Sensitive areas are configuration.** `AGENTS.md` § Sensitive areas names them; `CAREFUL_GLOBS` in
  `.claude/hooks/config.sh` mirrors them, and the `careful-paths` hook stops the first edit in each
  area once per session so the agent confirms the lane.
- **Working economically is part of the contract:** one task per session, short tool output, targeted
  tests while iterating and the full gate once, agent browser checks only when asked or visual,
  blocking questions batched.
- **Measure it.** The plugin's `/cost-report` reports per-session cost and flags the expensive
  patterns; teams track rework per lane next to cost and tune the triggers with a PDR.

## Consequences

- **Positive:** small precise changes should drop from roughly 60–120 calls to 10–25; the full lane
  keeps its rigor where something is decided; the record of delivered behavior stays complete through
  light change requests; developer intuition has a defined place in triage.
- **Negative / cost:** a request that sounds precise but hides a decision can reach review before
  anyone notices — the usage search, the shared-code and contract triggers, the mid-work stop rule, and
  the lane check in `/review` exist to catch it, and rework tracking exists to show whether they do.
  Routing now depends on the triage's judgment, so the routing evals (`evals/dynamic/fixtures/triage/`)
  must be run when the triage or the lanes change. `AGENTS.md` grows by about 25 lines.

## Alternatives considered

- **Route by size alone** (lines or files changed). Rejected: a one-line change to an authorization
  check is riskier than a 200-line copy update. Size is an entry criterion, not the test.
- **Keep the full flow for every change request.** Rejected on the evidence above: it was the most
  expensive pattern measured, and it didn't concentrate verification where defects are found.
- **Pin cheap models on small skills** (`/commit` on Haiku). Rejected: inside a long session, a model
  switch re-reads the whole context uncached, which costs more than it saves. The session's model is
  the lever.
- **Let the agent alone decide the lane.** Rejected: the developer often knows what the code can't
  show; their call ranks first when it asks for more care.
