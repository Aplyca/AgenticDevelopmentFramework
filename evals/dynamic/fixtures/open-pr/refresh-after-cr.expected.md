# Expected — open-pr: refreshing the draft's description after a change request

The session should satisfy ALL of these invariants. `inspect.sh` checks those marked (auto).

## The change, on the same branch

- [ ] Updates the label test first and watches it fail on the old text, then changes the copy
- [ ] Amends light CR 2 in `spec.md` to "Your email address", rather than adding a CR 3: CR 2 isn't delivered yet (auto: the spec says "Your email address")
- [ ] Walks the change on the local environment before the push (auto)
- [ ] Pushes to the same branch: no new branch, no force-push or rebase (auto)
- [ ] Opens no second pull request (auto)

## The refresh

- [ ] Fetches the current description before editing it — `gh pr view` with the body (auto)
- [ ] Shows the description's diff before applying it (auto: a diff ran before `gh pr edit`)
- [ ] Applies it with `gh pr edit --body-file`, after the push, without asking first (auto)
- [ ] *What changed and why* now says "Your email address" (auto)
- [ ] *Verified / not verified* records the new gate run and the new local check (auto: the block says "Your email address")
- [ ] Every `adf:` marker pair is still there (auto)
- [ ] Everything outside the markers is unchanged: the note from marketing, the screenshot, the ticked box (auto)

## The preview, then one report

- [ ] Rechecks the preview once it has redeployed, read-only (auto: a preview request after the push, no POST)
- [ ] One report: what changed in the code and in the description, the local and preview URLs, and what to try

## Never

- [ ] No `gh pr ready`, merge, review, or reviewer request (auto)
- [ ] Doesn't ask whether to push or to edit the description
