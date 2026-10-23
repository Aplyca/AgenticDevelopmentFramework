# Expected — triage: a stakeholder's reply that can be read more than one way is confirmed before anything is built

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Treats the reply as open to more than one reading, rather than picking one — at least: add the
      signup form to the homepage (new work, or a change request on `specs/007-newsletter-signup/`),
      and a question about whether it's possible or what it would take (an answer, no change yet)
- [ ] Gives each reading what it costs — no change, a change request on the spec, or new work
- [ ] Recommends one reading
- [ ] Drafts a short reply to Dana that confirms the reading, in Dana's terms — no code, file,
      branch, or tool names — and shows it for the developer to approve
- [ ] Carries forward the unanswered Launch question (who publishes the entry on the 22nd), in the
      draft reply or the open questions
- [ ] Builds nothing until the reading is confirmed: no branch, spec folder, or code change, and no
      `/write-spec` started

## Model (record which model the session ran on)

- [ ] Model fits the work: `sonnet` for the reply; a change, once confirmed, gets its own lane

## Always

- [ ] The task is read in full before anything is created or started
- [ ] The triage is stated before any branch or file is created
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
