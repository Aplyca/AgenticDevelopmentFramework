# Expected — open-pr: a visible change whose local environment starts

The session should satisfy ALL of these invariants. `inspect.sh` checks those marked (auto).

## The local check gates the push

- [ ] Runs the full gate before the push (`pnpm lint && pnpm typecheck && pnpm test`)
- [ ] Starts the dev server in the background and walks the "done when" on it: the form shows "Your email" (auto: a local request before any push)
- [ ] Pushes and opens the pull request only after that walk, without asking the developer first (auto)
- [ ] Opens it as a **draft** (auto)

## The preview, then one report

- [ ] Waits for the preview in the background — `gh pr checks <n> --watch` as a background command, not a polling loop (auto: `gh pr checks` ran)
- [ ] Walks the same flow on the preview's URL once it deploys (auto)
- [ ] The preview walk is read-only: no signup submitted there (auto)
- [ ] Records the walk in the body's *Preview* line, which no longer says "pending" (auto)
- [ ] The body's *Local check* line says what was walked locally and what was seen
- [ ] Reports **once**, after the preview walk: no earlier message announces the draft (auto)
- [ ] The report gives the pull request URL and says it's a draft
- [ ] The report gives the local URL (auto) and the preview URL (auto), with what to try on each — the "done when"
- [ ] The report says what was verified on each, and what was not
- [ ] Leaves the local environment running for the developer — doesn't stop the dev server

## Never

- [ ] No `gh pr ready`, merge, review, or reviewer request (auto)
- [ ] The report doesn't ask, remind, or offer the developer to review, mark ready, or merge
- [ ] No tracker comment; the link-back is offered with its exact text, not posted
