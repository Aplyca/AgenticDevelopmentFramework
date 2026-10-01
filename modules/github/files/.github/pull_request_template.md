<!-- Title: a commit-style subject under 70 characters — e.g. "feat: add newsletter signup" -->

## Traceability

<!-- Required. The spec folder is the record of intent; the tracker task is the requirement it
     fulfills. Work with nothing to decide has no spec folder — say so and cite the task alone.
     Add `Closes #N` as well if this resolves an engineering issue. -->

**Spec:** `specs/NNN-slug/` <!-- add "(CR N)" when amending a delivered feature -->
**Tracker task:**

## What changed and why

<!-- A reviewer should not have to reconstruct intent from the diff. AI-assisted or not, the person
     who opened this pull request owns it. -->

## How to verify

1.
2.

**Tests:** <!-- tests added or extended, or why none were needed -->

## Verified / not verified

<!-- From the spec folder's tasks.md § Gate results: what ran (commands, counts) and what could not
     be checked here, and why — e.g. "UI on the preview deployment". -->

- Verified:
- Not verified:

## Screenshots

<!-- UI changes: before / after. Delete this section otherwise. -->

## Checklist

Quality gates (`AGENTS.md` § Quick reference): <!-- CUSTOMIZE: your real commands -->

- [ ] Lint clean
- [ ] Typecheck clean
- [ ] Tests pass, and the spec's acceptance criteria are encoded in them
- [ ] Git hooks were not bypassed (`--no-verify` was not used)

Constitution gates (`docs/CONSTITUTION.md`): <!-- CUSTOMIZE: one box per principle -->

- [ ] **Scope** — every changed file is inside the spec folder's approved change surface
- [ ] **Secrets** — no tokens, keys, or `.env` files in the diff; new environment variables are declared in the template
- [ ] **Authorization** — no access check loosened; any broadening is justified above
- [ ] **History** — no existing migration edited or deleted
- [ ] **Types** — nothing silenced to clear an error
- [ ] **Accessibility** — accessibility lint respected, not disabled
- [ ] **Dependencies** — none added, or each one is justified above

<!-- If a box above is unchecked, say why here rather than deleting it. -->
