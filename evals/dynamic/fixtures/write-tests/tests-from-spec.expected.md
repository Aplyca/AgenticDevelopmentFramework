# Expected — write-tests test plan covers all spec sections

The AI's Phase 1 output (test plan, before approval) should satisfy ALL of these invariants.

## Behavior invariants

- [ ] AI presents a TEST PLAN first (does NOT immediately write tests)
- [ ] AI explicitly waits for approval before writing tests
- [ ] AI organizes the plan by source spec section (FROM Functional, FROM Security, FROM Accessibility, etc.)

## Coverage invariants — Functional ACs

- [ ] Test for AC1 ("visitor sees the form") is present
- [ ] Test for AC2 ("submitting valid form shows success") is present
- [ ] Test for AC3 ("submitting empty fields shows inline errors") is present

## Coverage invariants — Edge cases

- [ ] Test for "malformed email" is present (likely a unit test on the validator)
- [ ] Test for "message >5000 chars" is present

## Coverage invariants — Security (NOT just Functional)

- [ ] Test for "reCAPTCHA score <0.5 rejected" is present (route-level test)
- [ ] Test for "rate limit 5/IP/hour returns 429" is present
- [ ] Test for "oversize payload rejected" is present (server-side crafted-payload test)

## Coverage invariants — Accessibility (NOT just Functional)

- [ ] Test verifying inline errors use `role="alert"` is present
- [ ] Test verifying form is keyboard-navigable in correct tab order is present
- [ ] Test verifying input labels are programmatically associated is present
- [ ] axe-core automated scan is mentioned (from Testing section's explicit ask)

## Coverage invariants — Performance (NOT just Functional)

- [ ] Performance test for the <500ms p95 SLA is mentioned (or explicitly deferred with reasoning)

## Coverage invariants — Privacy (NOT just Functional)

- [ ] Test verifying IP TTL behavior (60-min expiry from KV) is mentioned

## Coverage invariants — Testing section (explicit asks)

- [ ] Manual screen-reader pass is mentioned (typically as a PR checklist item, not an automated test)

## Anti-pattern invariants

- [ ] Plan does NOT only cover Functional ACs — it covers Security/A11y/Perf as required
- [ ] AI does NOT write any test code in Phase 1 (plan only)
- [ ] AI does NOT skip the approval step
- [ ] Plan does NOT bundle multiple ACs into one test (each AC has its own test)

## Coverage report invariants

- [ ] AI includes a coverage check / count: "ACs covered: 3/3, Edge cases: 2/2, Security: N/N, Accessibility: N/N, Performance: 1/1"

## Pass criteria

All Behavior + Coverage (every section) + Anti-pattern invariants must pass.
