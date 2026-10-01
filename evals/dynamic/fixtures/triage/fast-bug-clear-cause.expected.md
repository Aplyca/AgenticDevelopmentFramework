# Expected — triage: a bug that restores documented behavior takes the fast lane, regression test first

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Kind is bug; lane is **fast** — the fix restores documented behavior and touches no trigger
- [ ] Plans a regression test that fails first (an uppercase address), then the fix in `validate-email.ts`
- [ ] Does NOT create or amend a spec folder (no CR — behavior is restored as documented)
- [ ] Names a "done when" and the files (`validate-email.ts` and its test)

## Model (record which model the session ran on)

- [ ] Model fits the lane: on Opus, suggests `sonnet`; on Sonnet, suggests no switch

## Always

- [ ] The task is read in full before anything is created or started
- [ ] The triage is stated before any branch or file is created
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
