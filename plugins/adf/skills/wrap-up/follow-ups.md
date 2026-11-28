# Follow-ups at the close-up

`/adf:wrap-up` reads this when the pull request's `## Follow-ups` has an unchecked line, an answer
listed follow-ups, or the merge left the record short (step 3).

## Which ones to offer (step 2)

Each unchecked line under `## Follow-ups`, up to the next heading, is one:
- `- [ ] \`<command>\` — <why> (<source>)` — work the merge made necessary; `/adf:upgrade` writes
  them. Offered only after a merge: an abandoned task's merge never happened. **A session.**
- `- [ ] <task> — <why> (found in <file:line>)` — a bug or an improvement found along the way
  (`specs/README.md` § Found along the way). Offered after any ending: it doesn't depend on this
  task's code. **An issue** in this repository when the stamp on `AGENTS.md`'s first line names
  `github` or `gitlab` ([decision 0082](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0082-follow-ups-found-along-the-way-are-filed-as-issues.md));
  otherwise, a session.

- **The record the merge left short** (step 3), offered only after a merge. Ask whether each open
  task was done: done, or only the status unset, is a fix to the record — a `docs:` branch that
  ticks those tasks and sets `status: implemented`, a session; a task not done is its own
  follow-up, for the work.

For an answer, the follow-ups are the ones its answer listed.

**For the issues, read with the rest:** the repository (`git remote get-url origin`), who files
them (`gh api user --jq .login`; on GitLab, `glab api user`'s `username`), and an open issue that
already covers each one (`gh issue list --state open --search "<key words> in:title" --limit 5`;
`glab issue list --search "<key words>"`). A CLI missing or not signed in: they can't be filed, so
the close-up's line says the text will be given to paste. The close-up's list (step 5) shows each
line as it will be filed, a match as "already #<n>", and the developer can move any one to a session,
or drop it:
```
- File as issues in <owner>/<repo>, as <account>: <each finding's line>
```

## Filing and starting them (step 6.3)

**The issues first:** they need nothing from the worktree. For each one the developer kept:
- **The title** is the line's task. **The body:**
  ```
  <why it matters>

  Found in `<file:line>` along the way in #<n>.
  ```
  On GitLab the merge request is `!<n>`; for an answer, name its question in a line instead. Add how
  it's known (seen failing, or read and suspected) and the lane it would take when the session's
  report said. The reference makes the host link the two: don't edit the merged description.
- **File it:** `gh issue create --title "<title>" --body-file <file>`; on GitLab,
  `glab issue create --title "<title>" --description "$(cat <file>)"`. Add `--label bug` for a bug,
  only when `gh label list` (`glab label list`) has it: labels are the team's, never created.
- **Report each issue's URL.** One that fails: give its title and body to paste, and go on.

**Then the sessions.** All of them start before the worktree goes. Each one is a session of its own,
from the updated base branch in the main checkout, because it needs the merged change; it changes
the project's environment or tests and goes through its own review.
- **In the desktop app:** call `start_session` once per follow-up, `"fresh"`, with the command or
  the task as the brief and its why and source (`found in <file:line>`); the yes was the
  developer's ask. Don't run the command or start the task here.
- **In a terminal:** print each command, for the developer to run in a new session from the main
  checkout.
- If the base branch wasn't updated, say so: the follow-up would start without the merge.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "Every follow-up gets a session of its own" | With the `github` or `gitlab` module, a finding is filed as an issue, where the team decides when it's done; a session is for one the developer wants now. The commands an upgrade wrote still start as sessions. |
| "The status is one line; I'll commit it on the merged branch" | The merged branch takes no more pushes, and the base branch is protected. The fix is a pull request of its own, and the miss was the task's pull request's: say so. |
