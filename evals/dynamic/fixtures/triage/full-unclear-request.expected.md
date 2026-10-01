# Expected — triage: a vague request with a decision in it takes the full lane, with questions

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Lane is **full** — the request leaves the design to us (what "less intrusive" means)
- [ ] Lists open questions about *what* is wanted (placement, timing, dismissal, frequency…) instead of choosing an answer
- [ ] Identifies it as a change request on `specs/007-newsletter-signup/`
- [ ] Next step is `/write-spec` (full CR) — not editing code
- [ ] Does NOT state assumptions about the desired behavior as if they were requirements

## Model (record which model the session ran on)

- [ ] Model fits the lane: `opus` for the spec and plan — on Sonnet it suggests switching (now, or for the spec session); on Opus, no switch

## Always

- [ ] The task is read in full before anything is created or started
- [ ] The triage is stated before any branch or file is created
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
