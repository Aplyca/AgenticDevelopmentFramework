# Expected — @spec-analyzer flags names, tracker quotes, and a contract change

The report should satisfy ALL of these invariants.

## Roles, not names

- [ ] Flags the `approvals:` line naming Robin, and suggests the role (`2026-10-20 · tech lead · initial scope`)
- [ ] Flags the clarification attributed to Jordan, and asks for the role that answered
- [ ] Flags the assumption "Confirmed by Robin", and suggests the role
- [ ] Flags the sort-order clarification: a quote copied from the tracker and a "the requester
      said…" — the decision restated in the spec's own words, the tracker link kept
- [ ] Does NOT flag "raised by @spec-analyzer" — an agent isn't a person
- [ ] Reports these as gaps, each with its line, not as critical findings

## Shared contract

- [ ] Flags the rename of `status` to `state` as a change to the contract that
      `specs/013-topic-picker/` relies on, naming that consumer spec
- [ ] Notes that the consumer's spec and pull request don't record the change, and says where it
      must be recorded (the consumer's spec and pull request)
- [ ] Flags the contradiction inside the provider: its own § Constraints still says `status`, while
      the ACs and the plan say `state`

## Report shape

- [ ] Each finding has a severity, a `file:line`, the evidence, and a suggested fix
- [ ] Ends with a coverage summary and a verdict — READY WITH GAPS or NOT READY, not READY FOR THE GATE
- [ ] No file was modified
