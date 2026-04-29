# Expected — write-spec for an API-only feature

The AI's response should satisfy ALL of these invariants.

## Frontmatter invariants

- [ ] Frontmatter `feature-type: api`
- [ ] Frontmatter `personal-data: no`
- [ ] Status is `draft`

## Required sections

- [ ] `## Business [REQUIRED]` — filled
- [ ] `## Functional [REQUIRED]` — filled with ≥2 ACs (200 response, 503 response, timeout behavior)
- [ ] `## Out of scope [REQUIRED]` — filled
- [ ] `## Security [REQUIRED]` — filled (likely "Standard project security applies" since no auth)
- [ ] `## Testing [REQUIRED]` — filled
- [ ] `## Documentation [REQUIRED]` — filled (likely just JSDoc for the route handler in Post-implementable; Pre-implementable may be Not applicable)
- [ ] `## Clarifications [REQUIRED]` — populated

## Conditional sections — correctly marked Not applicable

- [ ] `## Accessibility` — present and marked `> Not applicable: [reason]` (no UI). Reason should reference "no UI" or "API-only".
- [ ] `## Privacy` — present and marked `> Not applicable: [reason]` (no personal data). Reason should reference "no personal data collected".

## Optional sections — should be ABSENT or correctly marked

- [ ] `## Design` — absent OR marked Not applicable (no UI)
- [ ] `## SEO` — absent OR Not applicable (internal API)
- [ ] `## Analytics` — absent OR Not applicable (likely not needed)
- [ ] `## Localization` — absent OR Not applicable (English-only / no user-facing strings)

## Optional sections — likely PRESENT for this feature

- [ ] `## Performance` — present, with the 2s timeout requirement (testable)
- [ ] `## Observability` — present, since uptime monitoring is the use case (logs + metrics + alerts)

## Anti-pattern invariants

- [ ] No code samples in Functional section
- [ ] AC is NOT "the endpoint works" — it's specific behaviors (response shapes, status codes, timeout)
- [ ] AI did NOT add Accessibility or Privacy as required sections (correct conditional logic)
- [ ] AI did NOT bloat the spec with speculative sections (no Design, no SEO, no Analytics if they're not relevant)

## Approval-gate invariants

- [ ] If asked to approve: AI verifies required sections + correctly notes Accessibility/Privacy are appropriately marked Not applicable
- [ ] AI does NOT refuse approval just because Accessibility/Privacy aren't filled (the conditional logic recognizes "Not applicable" as filled)

## Pass criteria

All Frontmatter + Required + Conditional + Anti-pattern invariants must pass.
