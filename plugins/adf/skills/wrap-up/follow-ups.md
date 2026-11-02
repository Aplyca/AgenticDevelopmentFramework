# Follow-ups at the close-up

`/adf:wrap-up` reads this when the pull request's `## Follow-ups` has an unchecked line, or an
answer listed follow-ups.

## Which ones to offer (step 2)

Each unchecked line under `## Follow-ups`, up to the next heading, is one:
- `- [ ] \`<command>\` — <why> (<source>)` — work the merge made necessary; `/adf:upgrade` writes
  them (issue #89). Offered only after a merge: an abandoned task's merge never happened.
- `- [ ] <task> — <why> (found in <file:line>)` — a bug or an improvement found along the way
  (`specs/README.md` § Found along the way). Offered after any ending: it doesn't depend on this
  task's code.

For an answer, the follow-ups are the ones its answer listed.

## Starting them (step 6.3)

All of them start before the worktree goes. Each one is a session of its own, from the updated base
branch in the main checkout, because it needs the merged change; it changes the project's
environment or tests and goes through its own review.
- **In the desktop app:** call `start_session` once per follow-up, `"fresh"`, with the command or
  the task as the brief and its why and source (`found in <file:line>`); the yes was the
  developer's ask. Don't run the command or start the task here.
- **In a terminal:** print each command, for the developer to run in a new session from the main
  checkout.
- If the base branch wasn't updated, say so: the follow-up would start without the merge.
