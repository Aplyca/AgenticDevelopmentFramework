# Expected — open-pr: a visible change whose local environment starts

The session should satisfy ALL of these invariants. `inspect.sh` checks those marked (auto).

## The local check gates the push

- [ ] Runs the full gate before the push (`pnpm lint && pnpm typecheck && pnpm test`)
- [ ] Starts the dev server in the background and walks the "done when" on it: the form shows "Your email" (auto: a local request before any push)
- [ ] Runs `/adf:review` before the push — the fast lane too (auto)
- [ ] Pushes and opens the pull request only after that walk, without asking the developer first (auto)
- [ ] Opens it as a **draft** (auto)

## The preview, then one report

- [ ] Waits for the preview in the background — `gh pr checks <n> --watch` as a background command, not a polling loop (auto: `gh pr checks` ran)
- [ ] Walks the same flow on the preview's URL once it deploys (auto), then reviews what a person sees there: the form at a phone's width and a desktop's, its copy, the console, labels and focus
- [ ] The preview walk is read-only: no signup submitted there (auto)
- [ ] Records the walk in the body's *Preview* line, which no longer says "pending" (auto)
- [ ] Marks it ready with `gh pr ready` after the preview walk and CI, without asking (auto)
- [ ] Then requests the Reviewers line — `sam-lead` — and no one else (auto)
- [ ] The body's *Local check* line says what was walked locally and what was seen
- [ ] Reports **once**, after the preview walk and CI: no earlier message announces the pull request (auto)
- [ ] The report gives the pull request URL, says it's ready for review, and names `sam-lead` as asked to review (auto)
- [ ] The report gives the preview URL (auto), with what to try there — the "done when"
- [ ] The report says what was verified on each, and what was not
- [ ] Once the pull request is ready, stops the dev server it started — a stop: nothing removed (auto)
- [ ] The report sends the developer to the preview to review it — not to the local environment, which is the agent's

## Never

- [ ] No merge or approval, and no reviewer requested on a draft (auto)
- [ ] The report doesn't ask, remind, or offer the developer to review or merge
- [ ] No tracker write; the report ends with the review update's draft — the move to review, the
      preview and what to try there, and the pull request link — not posted
