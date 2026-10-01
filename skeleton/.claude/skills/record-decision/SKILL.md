---
name: record-decision
description: Record a decision as an ADR (about the application — structure, dependencies, interfaces, data, platform) or a PDR (about how the team works — workflow, gates, branching, tooling, requirements flow), keep the index current, supersede or correct earlier records without rewriting them, and update the docs that describe the decision in the same change. Use when a significant technical or process decision is made, or the constitution is amended.
argument-hint: "[the decision, in a sentence]"
---

# Record a Decision

Decisions get re-argued long after the reasoning is forgotten — process decisions as often as
architectural ones. A short, dated, append-only record of the forces, the choice, its cost, and the
rejected alternatives ends the re-argument, or makes the next one faster.

| Record | Lives in | For decisions about | Examples |
|---|---|---|---|
| **ADR** — Architecture Decision Record | `docs/architecture/decisions/` | The application | Choosing a database or framework, a module boundary, an API style, a deployment platform, the dev-environment tooling |
| **PDR** — Process Decision Record | `docs/process/` | How the team works | The approval gate, draft pull requests, the requirements pipeline, review rules, how agents hand off work, constitution amendments |

Borderline — a branching and release model, say — shapes both how code reaches production and how
people work. Pick one home per project, say so in both indexes, and stay consistent.

## Steps

1. **Classify** the decision (table above). A constitution amendment is always a PDR.

2. **Look for related records** in both indexes. Does this supersede one (fully or in part), correct
   one, or depend on one? Read them.

3. **Take the next free number** in the right directory and copy its template to `NNNN-<slug>.md`:
   `docs/architecture/decisions/0000-template.md` or `docs/process/0000-pdr-template.md`.

4. **Write it — short, specific, honest:**
   - **Context** — the forces and the evidence. Data beats opinion: "a rule followed in 1 of 15
     pull requests over eight months" ends an argument that "people forget" doesn't.
   - **Decision** — stated plainly, in rules someone can follow and check.
   - **Consequences** — positive *and* negative. State the cost honestly; a record with no
     downsides is one nobody will trust later.
   - **Alternatives considered** — each rejected option and why.
   - **Status** — `proposed` while under discussion; `accepted` once the deciders agree (usually
     when the pull request merges).

5. **Supersede, never rewrite.** Accepted records are append-only. When a decision changes, the new
   record says what it supersedes ("Supersedes PDR-0002 rules 1–3"), and the old record gets exactly
   one edit: its status becomes `superseded by PDR-NNNN` (or "partly superseded…").

6. **Correct with a dated note.** When an accepted record turns out to be factually wrong, append a
   note under the affected passage instead of editing it:
   `> **Corrected YYYY-MM-DD.** <what was wrong, what is true, where the docs now say it>`

7. **Update the index** — the README table in the record's directory.

8. **Bring the docs into line in the same change.** Every file that describes the decided behavior —
   `AGENTS.md`, `CONTRIBUTING.md`, `docs/CONSTITUTION.md`, the pull request template, skills, CI
   comments — now says what the record says. A record that contradicts the instruction files is how
   an agent resolving the conflict by precedence lands on the wrong answer.

9. **Constitution amendments** get their own pull request containing the constitution change and its
   PDR — never inside the pull request that benefits from the amendment.

10. **Commit** with `docs:` — e.g. `docs: record the draft pull request rule as PDR 0007`.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "It's a small process tweak — no record needed" | Process rules get re-argued exactly like architecture. A one-page record costs minutes; the next debate costs hours. |
| "I'll update the old record to reflect the new decision" | Records are append-only. Rewriting history erases why the old decision made sense — supersede it instead. |
| "There are no real downsides to list" | Every decision has a cost. Leaving it out makes the record read as advocacy, and nobody trusts it. |
| "I'll fix AGENTS.md and the other docs later" | A decision recorded in one place and contradicted in another is worse than none. Same change. |
| "This feature needs the constitution amended — I'll do it in this PR" | Amending a gate in the change that needs to pass it defeats the gate. Separate pull request. |
| "I'll record what I think we should do" | Record what the deciders decided. If it isn't decided yet, the status is `proposed`. |

## Red flags (stop and reassess)

- The decision contradicts the constitution and no amendment is proposed.
- You're editing the body of an accepted record rather than superseding or appending a correction.
- The record cites no evidence and lists no alternatives.
- Docs that describe the old behavior are left unchanged.

## Verification

- [ ] Classified correctly — ADR (application) or PDR (process); amendments are PDRs
- [ ] Uses the template, with the next free number, and is listed in the index
- [ ] Context cites evidence; consequences include the cost; alternatives explain each rejection
- [ ] Superseded records changed only their status line; corrections are dated notes
- [ ] Every doc describing the decided behavior was updated in the same change
- [ ] A constitution amendment, if any, is in its own pull request

## Principles

- Short, dated, immutable, append-only.
- Evidence over opinion; state the cost.
- The record and the instruction files must agree — update them together.
