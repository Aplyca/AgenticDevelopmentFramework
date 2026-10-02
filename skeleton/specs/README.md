# Specifications

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: specs/ — spec-driven development records -->

This directory is the **record of intent**: why each change exists, what was decided and why,
and what was actually delivered — the things a diff can't tell you. It lives in git, so it is
discoverable with `ls`, greppable, reviewed in the same pull request as the code, and survives a
move to another Git host or tracker.

The tracker task (ClickUp, Jira, Linear, GitHub Issues…) stays the source of truth for **what the
requester needs**; the spec folder records **how we understood it and what we built**. Specs
_link_ their tracker task — they never copy it.

## Lanes — how much process a change gets

Every change to the repository takes one of three lanes. The lane follows **risk and uncertainty,
not size**. What catches defects runs in every lane: a test that proves the change, the guardrail
hooks, CI, a draft pull request reviewed by a person, and the human check on the preview. What the
lane changes is how much gets written down and approved *before* the code exists.

| Lane | When | What happens |
| --- | --- | --- |
| **Fast** | The requester has already decided exactly what they want — or a bug with a clear cause, where the fix restores the intended behavior. About 3 files or fewer, in one layer, and no escalation trigger | No spec folder, plan, or approval gate. Restate the request in one line with **"done when…"** and the files you expect to touch → search every use of what you change → write or update the test that asserts the new behavior and watch it fail (for a bug, the regression test) → edit until it passes → `/commit`. When it changes what a spec records as delivered, add a [light change request](#change-requests) in the same commit; a fix that restores documented behavior needs none |
| **Careful** | As fast, but the change touches a risk area (triggers below) | The fast lane plus that area's [checklist](#careful-lane-checklists), and the developer confirms the risky part before the commit. Still no spec folder: a light change request when it changes recorded behavior, a regression test for a bug |
| **Full** | Something to decide: a requirement that's unclear, conflicts with an agreed acceptance criterion, or leaves the design to us. Also a new feature, a new dependency, or work across layers or more than ~3 files | A spec folder and the [flow](#flow) below: spec → plan → tasks → approval gate → docs first → one red → green commit per task → review |

Answers (investigations, impact analyses, estimates) and changes to how the team works (PDRs in
`docs/process/`) take no lane.

### Escalation triggers

| Trigger | Lane, at least |
| --- | --- |
| A requirement that's unclear, conflicts with an agreed acceptance criterion, or leaves a design choice to us | Full |
| A new feature or module, a new dependency, or a change across layers or more than ~3 files | Full |
| A migration or schema change; authentication, authorization, or row-level security; personal data; payments; a public API or contract; code that other features use; infrastructure, CI, or deploy configuration | Careful |
| A path in the project's sensitive areas — `AGENTS.md` § Sensitive areas, mirrored in `CAREFUL_GLOBS` (`.claude/hooks/config.sh`) | Careful |

Triggers are checked at triage **and again while working**. When the diff grows past the files
stated at triage, a test outside the area fails, or no test can prove the change: stop, tell the
developer, and move up a lane — keeping what's done.

### Careful-lane checklists

- **Migration** — a new file, never an edit; compatible with the code that is running until the
  deploy; applied to a fresh database, with the affected tests run against it.
- **Authorization** — access is never loosened without the developer's explicit yes; a test for the
  denied case as well as the allowed one.
- **Personal data** — what's collected, stored, or exposed changes only as the request says; nothing
  new reaches logs, analytics, or the browser.
- **Shared code** — list the code's other consumers and run their tests.
- **Public API or contract** — existing callers keep working (an additive change), or the developer
  agrees to the break.
- **Infrastructure, CI, or deploy** — the change can be reverted, and the developer knows when it
  takes effect.

For authorization, personal data, and payments, also run `@security-reviewer` on the changed files.

### The developer decides

The developer can set the lane in the task or at any point in it — "full lane on this", "be careful
here", "just a quick fix" — and the triage says where the lane came from: the triggers, the
sensitive areas, or the developer.

- **Raising the lane is always honored**, with no reason needed. Mid-task, the agent fills in only
  what the new lane adds — a short plan, more tests, a review — instead of starting over.
- **Lowering it is honored for size and judgment, not for risk.** A developer can take a small change
  out of the full lane. Where a risk trigger applies, that area's checklist stays unless the developer
  explicitly accepts the risk; the pull request then says so ("lane lowered by the developer:
  <reason>").
- **The constitution and the guardrail hooks hold in every lane.** No instruction lowers them.

More effort isn't only a higher lane: questions before any code, `/evaluate` to compare designs, a
higher effort level or a stronger model, and extra verification (`@security-reviewer`,
`/deep-review`). Each has a different cost — `docs/COST-MODEL.md` § Effort.

## Flow

The full lane:

```
triage → specify → (clarify) → plan → tasks → (analyze) → APPROVE → docs first → implement (TDD per task) → verify → draft PR
```

| Step | Artifact | What happens |
| --- | --- | --- |
| **Triage** | first message | Read the task in full; decide the deliverable (answer or change), the lane, and whether an environment is needed (`/triage`) |
| **Specify** | `spec.md` | WHAT and WHY from every relevant role — the multi-perspective model in `docs/SPEC-MODEL.md` (`/write-spec`) |
| **Clarify** | `spec.md` § Clarifications | Ambiguities become questions; answers are written back into the spec |
| **Plan** | `plan.md` | HOW: constitution check, architecture, **change surface**, data and contracts, test strategy, documentation plan, risks, assumptions (`/write-plan`) |
| **Tasks** | `tasks.md` | Dependency-ordered tasks sized to one commit each, each naming its test and ACs |
| **Analyze** | (report) | Read-only consistency check: every AC → task → test, no constitution conflict, change surface complete (`@spec-analyzer`, or `/deep-spec-analysis` for high-stakes work) |
| **Approve** | `spec.md` `status: approved` | **Stop.** The developer sees the scope, the change surface, and every assumption, and signs off. No implementation code before this. |
| **Docs first** | pre-implementable docs | Written from the spec and plan, committed before implementation (`/write-docs`; skips cleanly when there are none) |
| **Implement** | one commit per task | Write the test, watch it fail, write the code, watch it pass, commit, tick the task (`/implement`) |
| **Verify** | `tasks.md` § Gate results | Full gate run; `/implement` records the red-then-green evidence and what could not be run; `/review` checks it |
| **Deliver** | draft PR | Only when asked: push and open a **draft** PR naming the spec folder and tracker task (`/open-pr`). A human QCs it and marks it ready. |

The approval gate sits after the plan on purpose: approving a spec alone is cheap but checks
the wrong thing — the riskiest part of an agent's convincing analysis is usually **which files
and layers the change actually touches**, and that is only known once the plan exists. Before
the first commit, a wrong change surface is a sentence to correct; after it, a rewrite.

## Granularity

| Artifact | Granularity |
| --- | --- |
| Tracker task | The business requirement (one task may need several spec folders) |
| Spec folder | One feature — created by its first PR, amended by later change requests |
| Branch | `<type>/<slug>`, where `<slug>` matches the spec folder's slug; a change request's branch adds the change: `<type>/<slug>-<change>` |
| Commit | One task from `tasks.md` (full lane); one change with its test (fast and careful lanes) |
| Pull request | One per branch; names its spec folder and links its tracker task |

**Shared foundation work** that several features depend on — a migration, a shared type, a
service — is its own spec folder and its own PR, landed first.

## Folder convention

```
specs/
├── README.md            # this file
├── _templates/          # copy to start a new spec folder
│   ├── spec.md
│   ├── plan.md
│   └── tasks.md
└── 007-newsletter-signup/
    ├── spec.md          # WHAT and WHY (multi-perspective)
    ├── plan.md          # HOW, change surface, test strategy
    ├── tasks.md         # commit-sized tasks + gate results
    └── contracts/       # optional: API schemas, event payloads
```

Start one with `cp -r specs/_templates specs/NNN-<slug>` — `NNN` is the next free number. The
number is **ordering, not identity**: the slug joins folder, branch, and PR, so a number collision
between two parallel branches is harmless (renumber on merge if you care).

## Status

Recorded in `spec.md` frontmatter:

| Status | Meaning |
| --- | --- |
| `draft` | Being written; may be incomplete |
| `in-review` | Required sections filled; requirements under review with the requester (optional step for client-facing work) |
| `approved` | Scope, change surface, and assumptions signed off at the gate — implementation may start. Each sign-off is a line in `approvals:` |
| `implemented` | Every task done and the gate results recorded — set by `/implement` in the branch, so it merges with the pull request and the folder reads as built. A full change request moves it back to `in-review` until its own sign-off; a light one leaves it `implemented` |

Nothing mechanical enforces the gate — it is a rule an agent could skip and CI can't see. That
is why `/implement` refuses to write code for a spec whose status is not `approved`, and why
reviewers check the `approvals:` line.

## Change requests

Feedback on delivered work is not a new feature. Re-reading the task from scratch is how scope
gets silently dropped or redone. Find the delta first:

1. **Find the existing folder.** `git log -- specs/NNN-<slug>/` says when each part landed.
2. **Compare the request now against what the spec says was delivered.** Trackers rarely keep a
   revision history of a task's description — the spec is the snapshot of the requirement as
   built, and the comments since the spec's last update are usually where the change was argued.
3. **Record it in the same folder**, in one of two weights:
   - **Light** — a precise adjustment the requester has already decided, in the fast or careful
     lane. Append a short `CR N — <title> (date) · light` section to `spec.md` — the request's link,
     the Delivered → Change row, and any acceptance criterion it adds or changes, tagged `(CR N)` —
     and commit it **with the change it records**. No plan or tasks part and no approval gate: the
     pull request's review approves the diff, and its URL goes into `pull-requests:` as `· CR N`.
     The status stays `implemented`. Appended at the end of `spec.md`:

     ```markdown
     # CR 2 — Email field label (2026-10-08) · light

     - **Requested:** https://tracker.example.com/t/MKT-530 · by Dana (marketing lead)

     | Aspect | Delivered (PR …) | Change |
     | --- | --- | --- |
     | Email field label | Fixed text "Email address" | Fixed text "Your email" |
     ```

     — and the line it changes in place gets `(CR 2)`.
   - **Full** — the request leaves something to decide. Append a `CR N` section (intent + a
     Delivered → Change table), add new ACs tagged `(CR N)`, and append a `# CR N — <title>` part to
     `plan.md` and `tasks.md` covering only the delta — tasks numbered from `T<N>00` (T100 for CR 1),
     so IDs never collide. Earlier parts stay as the record of what was built. Same gate.

   A light change request that turns out to need a decision becomes a full one. Either way: a new
   branch, a new pull request, the same folder.
4. **If the delta can't be recovered** — no folder, or a description rewritten without a trace —
   say so and ask. Never reconstruct the old requirement from the code and present it as fact.

**Hotfix backfill.** A hotfix ships first; if it changed behavior, the feature's folder catches up
in a follow-up pull request: a `CR N — hotfix: <title> (date)` section (what changed and why, the
Delivered → Change table), the acceptance criteria it changed, and the hotfix pull request in
`pull-requests:`. There's no approval gate for recording what already shipped — the backfill pull
request is reviewed like any change.

## Specs from older framework versions

Single-file specs (`specs/<name>.md`, one file with every section) remain valid records. Leave
them as they are; the next time one changes, move it to `specs/NNN-<slug>/spec.md` in the same
PR and add the `plan.md` and `tasks.md` for the change.
