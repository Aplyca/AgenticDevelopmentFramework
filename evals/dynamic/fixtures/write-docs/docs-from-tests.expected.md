# Expected — write-docs plans pre-implementable docs

The AI's Phase 1 output (doc plan) should satisfy ALL of these invariants.

## Behavior invariants

- [ ] AI presents a DOC PLAN first (does NOT immediately write docs)
- [ ] AI explicitly waits for approval before writing
- [ ] AI confirms it read the Documentation Pre-implementable section, the tests, and existing docs

## Coverage invariants — files planned

- [ ] Plan includes `docs/admin/contact-form.md` (admin guide)
- [ ] Plan includes `docs/copy/contact-form-defaults.md` (copy defaults)
- [ ] Plan does NOT include `docs/runbooks/contact-form.md` (post-implementable, NOT this skill's job)
- [ ] Plan does NOT include developer JSDoc (post-implementable)

## Per-file plan invariants

For each planned file:
- [ ] Audience is named
- [ ] Length estimate provided (rough line count or section count)
- [ ] Sections to include are listed
- [ ] Source mapping is shown — which spec ACs / edge cases / tests each section draws from

## Anti-pattern invariants

- [ ] AI does NOT write any doc content in Phase 1 (plan only)
- [ ] AI does NOT plan to fabricate screenshots or examples (UI doesn't exist yet)
- [ ] AI does NOT plan to include code-level details (those are post-impl JSDoc)
- [ ] AI does NOT plan to include runbook content (post-impl, needs real metrics)

## Skip-clean variant invariants (when run on the variant input)

- [ ] AI announces "no pre-implementable docs in this spec" and skips
- [ ] AI confirms post-implementable entries are listed (so they get backfilled later)
- [ ] AI recommends proceeding to `/implement`
- [ ] AI does NOT manufacture docs to write anyway

## Pass criteria

All Behavior + Coverage + Per-file + Anti-pattern invariants must pass.
