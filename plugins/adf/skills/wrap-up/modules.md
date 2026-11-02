# Wrap-up with the end-user-docs or time-tracking module

`/adf:wrap-up` reads this when the stamp on `AGENTS.md`'s first line names the `end-user-docs` or
the `time-tracking` module. Without them, say nothing about end-user docs or time.

## End-user docs (step 3)

An end-user page waiting to be published isn't work left over. Only when the stamp names
the `end-user-docs` module, the pull request merged, the spec lists an end-user page whose draft
isn't retired yet, and `docs/END-USER-DOCS.md` publishes after the merge, offer
`/adf:end-user-docs publish` once, before the close-up. The developer may skip it: a release
publishes it later.

## Time (step 4)

Only when the stamp names the `time-tracking` module, ask whether to log the task's time now with
`/adf:track-time` — a question of its own, before the close-up's — and wait for the answer: the
task's worktree and its transcripts are still there to measure. Time not yet logged isn't work left
over, so the developer may skip it.
- **On a yes,** run `/adf:track-time` to its end — the draft, the developer's picks, the entries
  written — then go on.
- **On a skip,** go on.

Don't ask when `/adf:track-time` already ran in this session after the task's last work.
