# Specifications

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: specs/ — spec-driven development records -->

This directory is the **record of intent**: why each change exists, what was decided and why,
and what was actually delivered — the things a diff can't tell you. It lives in git, so it is
discoverable with `ls`, greppable, reviewed in the same pull request as the code, and survives a
move to another Git host or tracker.

The tracker task (ClickUp, Jira, Linear, GitHub Issues…) stays the source of truth for **what the
requester needs**; the spec folder records **how we understood it and what we built**. Specs
_link_ their tracker task — they never copy it.

## When a change needs a spec folder

The test is **"is there anything to decide?"** — not "is it big?".

| Work | Spec folder? |
| --- | --- |
| New feature or behavior change | Yes |
| Change request on delivered work | Amend the existing folder (see [Change requests](#change-requests)) |
| Bug fix that changes documented behavior | Yes (or amend the feature's folder) |
| Bug fix restoring intended behavior, with a clear root cause | No — regression test + fix |
| Typo, copy edit, version bump, formatting, dev-only tooling with nothing to decide | No |
| Investigation, impact analysis, estimate — the deliverable is an **answer** | No — deliver the answer; a change it recommends gets a spec once someone approves that change |
| A change to how the team works | No — record it as a PDR in `docs/process/` |

Ambiguous, cross-cutting, or high-risk work is where a spec pays off most — but a small change
with a real decision in it still gets one.

## Flow

```
triage → specify → (clarify) → plan → tasks → (analyze) → APPROVE → docs first → implement (TDD per task) → verify → draft PR
```

| Step | Artifact | What happens |
| --- | --- | --- |
| **Triage** | first message | Read the task in full; decide the deliverable (answer or change), whether an environment is needed, whether a spec is needed (`/triage`) |
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
| Commit | One task from `tasks.md` |
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
| `implemented` | Every task done and the gate results recorded — set by `/implement` in the branch, so it merges with the pull request and the folder reads as built. A change request moves it back to `in-review` until its own sign-off |

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
3. **Amend the same folder:** append a `CR N` section to `spec.md` (intent + a Delivered → Change
   table), add new ACs tagged `(CR N)`, and append a `# CR N — <title>` part to `plan.md` and
   `tasks.md` covering only the delta — tasks numbered from `T<N>00` (T100 for CR 1), so IDs never
   collide. Earlier parts stay as the record of what was built. New branch, new PR, same folder,
   same gate.
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
