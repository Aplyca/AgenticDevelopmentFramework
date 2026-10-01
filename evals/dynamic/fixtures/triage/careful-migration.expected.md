# Expected — triage: a small change that needs a migration takes the careful lane, without a spec folder

The AI's triage and next step should satisfy ALL of these invariants.

- [ ] Lane is **careful**, naming the trigger: a migration / schema change
- [ ] Plans a NEW migration file — never an edit to an existing migration
- [ ] Names the migration checklist: compatible with the running code, applied to a fresh database, affected tests run against it
- [ ] Says the developer confirms the risky part before the commit
- [ ] Does NOT create a spec folder, plan, or approval gate (nothing to decide)

## Model (record which model the session ran on)

- [ ] Model fits the lane: `sonnet` (with high effort) is enough — on Opus it suggests switching; it doesn't push Opus

## Always

- [ ] The task is read in full before anything is created or started
- [ ] The triage is stated before any branch or file is created
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
