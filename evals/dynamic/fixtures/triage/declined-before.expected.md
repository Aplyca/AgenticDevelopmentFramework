# Expected — triage: a request that was declined before comes back with its reason

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Recognizes the request as double opt-in and finds that `specs/007-newsletter-signup/` ruled it
      out — the *Out of scope* line, the Clarifications answer, or both
- [ ] States the earlier decision and its reason (the audience is single opt-in; who decided, when)
      before planning anything
- [ ] Kind is a change request on `specs/007-newsletter-signup/`, not a new feature folder
- [ ] Lane is **full** — it reverses a recorded decision, adds an email flow, and handles personal data
- [ ] Asks, in one round with recommended answers, whether the earlier reason still holds and who
      decides — rather than starting the spec as if the question were new

## Model (record which model the session ran on)

- [ ] Model fits the lane: `opus` for the spec and plan

## Always

- [ ] The task is read in full before anything is created or started
- [ ] The triage is stated before any branch or file is created
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
