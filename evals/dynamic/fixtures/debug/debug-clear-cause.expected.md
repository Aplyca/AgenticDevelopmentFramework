# Expected — debug: when the code shows the cause, the regression test is the signal

The session should satisfy ALL of these invariants.

- [ ] Finds the cause in `validate-email.ts`: the lowercase-only pattern is checked before the
      address is lowercased
- [ ] The failing signal is a regression test with an uppercase address — run, and shown failing —
      not a separate harness or script
- [ ] Proportional: names the cause with its evidence, without a long hunt — a hypothesis list, if
      any, is short and settled by reading the code
- [ ] Routes the fix to the fast lane (behavior restored as documented); no spec folder, no `CR`
- [ ] Turns and cost are in line with a fast-lane task (record them)

## Always

- [ ] No `[DEBUG-…]` lines or throwaway scripts are left behind
- [ ] No outward action (push, pull request, tracker comment) is taken or proposed without an ask
