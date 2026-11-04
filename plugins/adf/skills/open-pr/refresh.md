# Refresh — keep your draft's description current

`/adf:open-pr refresh`, once a later push to your own open draft changes what its description says:
a fix or a change request the developer asked for, a sync with the base branch, new gate results.
Editing your own draft's description is upkeep: it takes no prompt.

1. **Check the pull request:** `gh pr view <n> --json state,isDraft,body`. Merged or closed: stop and
   say so — never edit it or push to its branch. No longer a draft: the developer has taken it over,
   so show the diff (step 5) and apply it only on their yes.
2. **Check the record** the push left in the spec folder: a fix's task ticked; a change request's
   tasks and gate results; `status: implemented` again once a full change request's gate results are
   in. Commit and push what's missing before the description: the merge takes the record as the
   branch has it. A full change request still under way keeps its status, and the description says
   the pull request waits for it.
3. **Fetch the current body** into a file and work from that copy, never from what you wrote last:
   people edit descriptions.
4. **Rebuild only the sections you own,** the text between each `<!-- adf:<section> -->` and its
   `<!-- /adf:<section> -->`: *What changed and why*, *How to verify*, and *Verified / not verified*.
   - **From the record, not from memory:** `tasks.md` § Gate results and the spec's change requests —
     what this pull request now delivers, with what the latest `CR N` changed. In the fast and
     careful lanes, the light `CR N` and the gate you just ran.
   - **Everything outside the markers stays byte for byte:** the traceability lines, checked boxes,
     a reviewer's notes, screenshots. *Follow-ups* only gains a line for something new you found;
     never tick or remove one.
   - **A body without the markers** — opened before the template had them, or rewritten by hand — is
     all the people's: show the sections you'd replace, and apply only on the developer's yes.
5. **Show the description's diff** before you apply it, old against new:
   `git diff --no-index <old> <new>`. Sum it up in your report, so the developer sees what changed.
6. **Apply it** without waiting: `gh pr edit <n> --body-file <new>`. The title changes only when the
   scope did. When the change is one a person sees, recheck the preview (`/adf:open-pr` step 7).

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I pushed the fix; the description can stay as it was" | Then it describes code that's gone, and the reviewer reads it first. After a push that changes what it says, refresh it. |
| "I'll rewrite the whole description from what I know now" | People edit descriptions: a reviewer's note, a ticked box, a screenshot. Rebuild only the sections between the markers, from the current body. |
