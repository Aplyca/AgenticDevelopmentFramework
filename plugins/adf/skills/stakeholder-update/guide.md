# The usage guide — post it, and keep it current

`/adf:stakeholder-update guide`: the requester's guide to what the task delivers — how they'll use
it, in their terms. Its text is the spec's *Documentation › Usage guide*, written with the spec and
approved at the gate; this puts it where the requester reads it.

1. **Check there is one.** The spec's *Documentation › Usage guide*. `Not applicable`: stop and say
   so. With the `end-user-docs` module in the stamp on `AGENTS.md`'s first line, the doc tool's page
   is the guide: `/adf:end-user-docs` writes it, and this stops.
2. **Find its home** — `docs/TRACKER-INTEGRATION.md` § Stakeholder updates › **Usage guide**: a
   comment on the task (the default, and with no line), or a section of its description.
3. **Before the build — once the gate approved the spec:** post the text as it is in the spec, under
   a first line that says what it is: `**Usage guide (draft) — how this will work once it's
   delivered.**` It posts on its own: the developer approved its text with the spec. With **Updates
   post: on the developer's yes**, show it and ask first.
4. **At delivered — the change is live:** update the guide where it lives, from the spec's text as
   it merged — the same comment, edited, with the first line now `**Usage guide**` — and link it
   from the delivered update. The spec's text was reconciled with what the build changed before the
   merge, with the other docs (`/adf:implement`, Phase 5); if it wasn't, say so and post what
   shipped. Add screenshots as `<this skill's base directory>/screenshots.md` says.
5. **Write as the post is written** (`SKILL.md` step 6): through the project's tracker tool, as the
   developer; read it back. A description is rewritten whole, so where it holds something an edit
   would lose — a mention, a link preview (§ Stakeholder updates) — the guide goes in a comment
   instead. Never touch the rest of the description.

**No spec folder** — the fast and careful lanes: there's no draft. A guide the change needs is a
short "how to use it" paragraph in the delivered update.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "I'll write the guide once it's built, when I know how it works" | The draft is the requester's chance to say "that's not how we'd use it" before the build. It's written with the spec. |
| "The build changed it — I'll just edit the comment" | The spec is the source, reconciled before the merge. Rewrite the task's copy from it. |
| "I'll improve the description's wording while I'm adding the guide" | The description is the requester's. Add the guide's section, or use a comment; change nothing else. |
