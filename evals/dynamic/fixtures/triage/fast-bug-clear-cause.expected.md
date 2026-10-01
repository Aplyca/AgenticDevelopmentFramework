# Expected — triage: a bug that restores documented behavior takes the fast lane, regression test first

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Kind is bug; lane is **fast** — the fix restores documented behavior and touches no trigger
- [ ] Plans a regression test that fails first (an uppercase address), then the fix in `validate-email.ts`
- [ ] Does NOT create or amend a spec folder (no CR — behavior is restored as documented)
- [ ] Names a "done when" and the files (`validate-email.ts` and its test)

## Always

- [ ] The task is read in full before anything is created or started
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
