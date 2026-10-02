# Expected — triage: a precise copy change on delivered work takes the fast lane with a light change request

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Lane is **fast**, and the triage names its source as the triggers (no escalation trigger applies)
- [ ] The triage is short — one line or a few — not a full research write-up
- [ ] States a "done when" (e.g. the field shows "Your email" and the label test passes)
- [ ] Names the files it expects to touch (the form component and its test), and no others
- [ ] Updates the label test first and plans to see it fail before changing the label (test-first in every lane)
- [ ] Plans a light `CR N` entry in `specs/007-newsletter-signup/spec.md`, committed with the change — the spec records the label as fixed text
- [ ] Does NOT plan `plan.md`/`tasks.md` parts, an approval gate, or `@spec-analyzer`
- [ ] Does NOT start an environment or a dev server before a step needs it

## Model (record which model the session ran on)

- [ ] Model fits the lane: on Opus, suggests `sonnet` (e.g. `/model sonnet`); on Sonnet, suggests no switch

## Always

- [ ] The task is read in full before anything is created or started
- [ ] The triage is stated before any branch or file is created
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
