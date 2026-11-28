# The description, when the repository has no template

`/adf:open-pr` step 4 fills this in when the repository has no `.github/pull_request_template.md`
(on GitLab, no `.gitlab/merge_request_templates/Default.md`), by step 4's rules: the `adf:` markers
kept, checklists filled honestly, *Follow-ups* and *Merge danger* complete.

```markdown
## Traceability
**Spec:** `specs/NNN-<slug>/` (CR N, when amending — "light" for a fast- or careful-lane
adjustment) — or "none: fast lane" for work with nothing to record
**Tracker task:** <link> — a requester's issue: `Refs #N`, never `Closes`, since the merge isn't live  ·  `Closes #N` only for an engineering issue this resolves
**Lane:** fast | careful | full — <reason>; set by <the triggers | a sensitive area | the developer>
<careful: the checklist applied; the risky part — the area, what the checklist found, what you
walked · lowered by the developer: <their reason>>

## What changed and why
<!-- adf:what-changed -->
<the change and its reasoning — a reviewer should not have to reconstruct intent from the diff>
<!-- /adf:what-changed -->

## How to review and test
<!-- adf:how-to-verify -->
**Where:** <the preview's URL — "pending" until it deploys; or "no preview: `make up`, which prints where">
1. <a step the reviewer follows there, in order> — <what they should see>
**Look at:** <what deserves the reviewer's attention — the risky part, a decision, the files that carry the change>
**Tests:** <which tests cover this — added or extended>
<!-- /adf:how-to-verify -->

## Verified / not verified
<!-- adf:verified -->
- Verified: <commands run, counts — from tasks.md § Gate results; `/adf:review`: clean, or what it found and you fixed>
- Local check: <the flow you walked on the local environment, and what you saw — or "nothing to run">
- Preview: <the flow you walked and what you reviewed on the preview — layout, copy, console, accessibility — and what you saw; or "pending: deploying", "no preview", "can't reach it", "nothing a person sees">
- Not verified: <what you could not check, and why>
<!-- /adf:verified -->

## Merge danger
**Reversible:** yes — reverting the merge undoes it | no — <what a revert leaves changed>
**Blast radius:** <who or what is affected if this is wrong — one page, every form, an API's callers>

## Follow-ups
- [ ] <a task found along the way, in one line> — <why it matters> (found in <file:line>)
<or "- none">

## Screenshots
<before / after for UI changes; delete otherwise>
```
