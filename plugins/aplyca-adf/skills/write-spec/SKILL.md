---
name: write-spec
description: Write the spec.md of a spec folder with the multi-perspective spec model — or amend a delivered feature's spec with a change request (CR) — clarifying ambiguities and enforcing required sections before planning. Use when starting a new feature or changing existing behavior; /aplyca-adf:write-plan follows and holds the approval gate.
argument-hint: "[feature description, tracker link, or spec folder to amend]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's `CLAUDE.md` says "This project uses the packaged install", stop here: open `.claude/skills/write-spec/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

> **The reference docs this file names are the plugin's copies,** in `${CLAUDE_PLUGIN_ROOT}/docs/` — outside this project, which keeps none in its own `docs/`. Read them at the full paths given.

# Write Spec

Write `specs/NNN-<slug>/spec.md` using the multi-perspective spec model (`${CLAUDE_PLUGIN_ROOT}/docs/SPEC-MODEL.md`): the
WHAT and WHY from every relevant role, in one document, with required sections enforced. The HOW
comes next, in `plan.md`, from `/aplyca-adf:write-plan` — which also holds the approval gate.

## Steps

1. **Check existing specs.** Search `specs/` by tracker link, feature name, and keywords. If a folder
   already covers this feature and it was delivered, this is a **change request** — go to step 8. A
   single-file spec from an older framework version (`specs/<name>.md`) is moved into a folder the
   first time it is amended.

2. **Get the requirements from their source.** The tracker task (read it in full; with a tracker MCP
   server connected, read it directly) or the requester's own words in the prompt. If neither states
   the requirements, **stop and ask** — never invent them. Establish:
   - Who is the user, what problem does this solve, what does success look like?
   - **`feature-type`** — `ui`, `api`, `infra`, `content`, or `mixed`.
   - **`personal-data`** — does it collect, store, or transmit personal data? Default to `yes` if unsure.

3. **Determine which sections apply:**

   | Always required | Conditionally required | Common optional (ask) |
   |---|---|---|
   | Business, Functional, Out of scope, Security, Testing, Documentation, Clarifications | Accessibility (if `ui` or `mixed`), Privacy (if `personal-data: yes`) | Design, Performance, SEO, Analytics, Localization, Constraints & prior decisions, Observability, Deployment |

   For optional sections, ask which apply. Don't fill speculative sections — an absent optional
   section is a feature.

4. **Clarify per section** before drafting. Ask the role-perspective questions that matter:
   - **Business** — who asked, what outcome, what success metric?
   - **Functional** — boundary conditions, error scenarios, permissions, interactions with existing features?
   - **Design** — mockups, variants and states, brand constraints?
   - **Accessibility** — anything beyond WCAG 2.1 AA, screen-reader or keyboard-only flows?
   - **Security** — auth, validation, rate limits, third-party trust, secrets, access changes?
   - **Privacy** — what data, lawful basis, storage, transmission, consent?
   - **Performance / SEO / Analytics / Localization** — targets that differ from project defaults?
   - **Constraints & prior decisions** — business rules, compliance, existing ADRs or PDRs to respect?
   - **Testing** — anything beyond "every AC has a test" (accessibility scans, visual regression, manual passes)?
   - **Documentation** — what is pre-implementable (admin guides, API contracts, copy defaults) vs post-implementable (runbooks, troubleshooting)?
   - **Observability / Deployment** — logs, metrics, alerts; env vars, migrations, rollout, rollback?

   **Ask in rounds** (`AGENTS.md` § Working economically). A round holds every question that doesn't
   depend on another open answer — numbered, each with your recommended answer and why; the answers
   decide the next round. Look up what the code, the docs, or the tracker can tell you instead of
   asking. Stop when nothing is left silently assumed.

   ```
   1. When the address is already subscribed, show the usual success message or say so?
      → Recommended: the usual message — saying so reveals who is on the list (Privacy).
   2. Does the form appear only in the article footer, or also in the blog sidebar?
      → Recommended: the footer only; the sidebar goes to Out of scope for this iteration.
   ```

   **Use the project's words.** Name concepts with the terms in `docs/GLOSSARY.md`. When the request
   uses a word the glossary lists under *Avoid*, or one word for two concepts, say which term you'll
   use or ask which is meant; when a new domain term is settled, add it to the glossary in the same
   change.

   Record every question and answer in **Clarifications**, with the date and who answered.

5. **Create the folder** on the work branch `<type>/<slug>` (create it from the base branch if you're
   on a protected one): `cp -r specs/_templates specs/NNN-<slug>` with the next free number and a
   short kebab-case slug — the branch, folder, and pull request share it.

6. **Draft `spec.md`.** For each section that applies:
   - **Concrete content** — numbered, testable ACs (`AC1`, `AC2`…) that keep their numbers for life.
   - **Standard applies** — `> Standard project [area] applies (see .claude/rules/[file].md). No additional requirements.`
   - **Not applicable** — `> Not applicable: [one-line reason]` for a conditional section that doesn't apply.
   - **Optional and irrelevant** — leave the heading out entirely.

   WHAT and WHY only: no file paths, components, or code. A constraint on HOW goes in *Constraints &
   prior decisions*, with its reason; the design itself goes in `plan.md`.

7. **Frontmatter:** `feature-type`, `personal-data`, `tracker:` (a **link** — never copy the task's
   text into the spec; the tracker and the repository have different audiences and access),
   `owners:` per filled section, `references:`. `status: draft`.

8. **Change-request mode** — amending a delivered feature. Two weights (`specs/README.md` §
   Change requests):
   - **Light** — a precise adjustment the requester already decided, in the fast or careful lane:
     append `# CR N — <title> (YYYY-MM-DD) · light` with the request's link, the Delivered → Change
     row, and any acceptance criterion it adds or changes, tagged `(CR N)`. No plan or tasks part,
     no gate, status stays `implemented`; the entry is committed **with the change it records**. If
     the adjustment turns out to need a decision, it becomes a full change request.
   - **Full** — the request leaves something to decide. The rest of this step:
   - **Find the delta.** Compare the request now against what the spec records as delivered, plus
     the tracker comments since the spec last changed (`git log -1 --format=%cs -- specs/NNN-<slug>/`).
     Trackers rarely keep a description's revision history; the spec is the snapshot of what was built.
   - **Append a `CR N` section** (template at the end of `spec.md`): where it was requested and by
     whom, the intent, and a Delivered → Change table.
   - **Add new ACs** with new numbers tagged `(CR N)`; strike through the ones it retires — don't
     delete them. Update only the sections the change touches; add to Clarifications, don't replace.
   - Set `status: in-review`. A fresh branch named after the feature and the change
     (`feat/newsletter-signup-topics`), a new pull request, the same folder.
   - **If the delta can't be recovered** — no folder, or a description rewritten without a trace — say
     so and ask. Never reconstruct the old requirement from the code and present it as fact.

9. **Mandatory section enforcement** — before handing the spec to planning, every required section is
   filled (concrete content, "Standard applies", or "Not applicable" — empty doesn't count):
   - [ ] Business has a paragraph and at least one success criterion
   - [ ] Functional has at least one numbered acceptance criterion
   - [ ] Out of scope has at least one item, or says "nothing intentionally excluded for this iteration"
   - [ ] Security and Testing are filled
   - [ ] Documentation has **both** Pre-implementable and Post-implementable filled or Not applicable
   - [ ] Clarifications exists (may be empty)
   - [ ] `feature-type: ui | mixed` → Accessibility filled; `personal-data: yes` → Privacy filled

   **If any is empty, refuse to hand off to planning.** Name the gaps and offer to walk through them.
   Also read the spec against `docs/CONSTITUTION.md`: flag any conflict, and don't proceed until it's
   resolved or an explicit exception is recorded in the spec.

10. **Requirements review (optional).** For client-facing work the requester may want to agree the
    ACs before planning: set `status: in-review` and offer to share them. Posting to the tracker is a
    write the requester sees — show the exact text and post only on the developer's yes.

11. **Hand off to `/aplyca-adf:write-plan`.** Approval happens at its gate, once the change surface is known —
    not here. `status: approved` is recorded only there, after the developer's explicit sign-off.
    Don't commit the folder before the gate unless the developer asks to save a draft
    (`spec: draft <slug>` on the work branch, status still `draft`).

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The requirements are clear enough, I'll skip clarification" | Ambiguities always exist. Uncovered gaps leak into tests and code as bugs. |
| "There's no task or written requirement, so I'll infer what they want" | Stop and ask. Plausible invented requirements are the failure this workflow exists to prevent. |
| "I'll copy the tracker description in for completeness" | Link it. The spec lives in git with a different audience and access than the tracker. |
| "This change request is basically new — I'll start a new folder" | Splitting a feature's record destroys the before/after the delta is computed from. Amend the folder. |
| "I'll reconstruct what was delivered by reading the code" | If the delta isn't recoverable from the spec and the thread, ask. A reconstruction presented as fact is an invented requirement. |
| "I'll combine these into one acceptance criterion" | Each AC must be independently testable — and keeps its own number for tasks and tests to reference. |
| "I'll add implementation details to help the developer" | WHAT, not HOW. Design goes in `plan.md`; only reasoned constraints belong in the spec. |
| "I'll skip Security, it's a simple form" | Every spec gets Security. "Standard applies" is a valid answer; absent isn't. |
| "I'll mark Accessibility Not applicable for this UI feature" | UI features always have accessibility requirements — at least "WCAG 2.1 AA applies". |
| "I'll fill Performance and Deployment in case we need them" | Speculative filling is worse than an absent section. |
| "The spec looks complete, I'll approve it" | Approval is the developer's, at the gate after the plan — when the change surface is known. |

## Verification

- [ ] Requirements came from the tracker task or the requester — none invented
- [ ] Every acceptance criterion is numbered and testable by an automated test
- [ ] Clarifications record every ambiguity resolved, with date and who
- [ ] Concepts use the glossary's terms; a newly settled domain term was added to `docs/GLOSSARY.md`
- [ ] Edge cases cover empty states, error states, and boundaries
- [ ] Out of scope excludes adjacent features explicitly
- [ ] All always-required sections are filled; conditional ones filled or Not applicable with a reason
- [ ] Frontmatter `feature-type`, `personal-data`, `tracker` (a link), and `owners` are set
- [ ] For a change request: `CR N` section with the Delivered → Change table; new ACs tagged `(CR N)`
- [ ] No conflict with `docs/CONSTITUTION.md`, or the conflict is explicitly resolved
- [ ] Status is `draft` or `in-review` — `approved` is recorded only at `/aplyca-adf:write-plan`'s gate, after the developer's explicit sign-off

## Principles

- WHAT and WHY here; HOW in `plan.md`.
- Requirements come from people, never from plausible assumptions.
- Link the tracker; don't copy it.
- Delivered features are amended, never re-specified from scratch.
- Empty optional sections are fine; empty required sections block planning.
