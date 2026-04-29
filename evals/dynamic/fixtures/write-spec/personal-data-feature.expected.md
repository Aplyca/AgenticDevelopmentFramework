# Expected — write-spec for a personal-data-collecting UI feature

The AI's response should satisfy ALL of these invariants. Each is independently checkable.

## Behavior invariants (about the AI's process)

- [ ] **Asks clarifying questions before drafting.** Common Qs: lawful basis for data, where Salesforce data is stored, is consent banner update needed, what triggers the A/B variant, what fields are required, what validation, what happens on Salesforce failure.
- [ ] **Does NOT immediately draft a finished spec without classification.** The skill should announce `feature-type: ui` and `personal-data: yes` before drafting.
- [ ] **Lists which sections are required and which are optional** based on classification.

## Frontmatter invariants

- [ ] Frontmatter `feature-type: ui` (or `mixed`)
- [ ] Frontmatter `personal-data: yes`
- [ ] `owners:` map populated with at least: `business`, `functional`, `security`, `privacy`
- [ ] Status is `draft` (NEVER `approved`)

## Required sections (must all be filled — concrete content, "Standard applies", or "Not applicable: [reason]")

- [ ] `## Business [REQUIRED]` — non-empty, has at least one success-criterion bullet
- [ ] `## Functional [REQUIRED]` — has user stories AND acceptance criteria (≥3 ACs) AND edge cases
- [ ] `## Out of scope [REQUIRED]` — at least one item
- [ ] `## Accessibility [REQUIRED if UI]` — filled (UI feature → required); if "Standard applies" is used, it points at `.claude/rules/ui-ux.md`
- [ ] `## Security [REQUIRED]` — filled
- [ ] `## Privacy [REQUIRED if personal-data: yes]` — filled with at least: data collected, lawful basis, storage, transmission, user rights
- [ ] `## Testing [REQUIRED]` — filled
- [ ] `## Documentation [REQUIRED]` — has BOTH Pre-implementable and Post-implementable subsections, each filled or marked Not applicable
- [ ] `## Clarifications [REQUIRED]` — populated with the Q&A from the clarification step

## Anti-pattern invariants (what should NOT appear)

- [ ] Functional section does NOT contain code samples, file paths, or library names
- [ ] Functional section does NOT contain "use X library" or implementation prescriptions
- [ ] Acceptance criteria are NOT bundled (one AC per behavior, not "user submits and email is sent and CRM is updated")
- [ ] Privacy section is NOT marked "Not applicable" (because the feature collects personal data)
- [ ] Accessibility section is NOT marked "Not applicable" (because the feature has UI)

## Approval-gate invariants

- [ ] If the AI was asked to mark the spec approved, it FIRST verifies all required sections are filled and lists any gaps
- [ ] If any required section is empty, the AI REFUSES to mark approved and lists what's missing
- [ ] After approval (if granted), the AI reminds the user of the next steps: commit spec → run `/write-tests` → run `/write-docs` (or skip cleanly) → run `/implement`

## Pass criteria

- All "Behavior" + "Frontmatter" + "Required sections" + "Anti-pattern" invariants must pass for the case to PASS.
- "Approval-gate" invariants are checked only if the user prompted for approval — otherwise N/A.
