# Comparison — the prose pass (decision 0086) — 2026-11-21

Decision 0086 has four skills run a prose pass on each draft written for readers outside the team.
This comparison checked what the pass changes in two of them, `/adf:stakeholder-update` and
`/adf:end-user-docs`, and whether the reader loses anything to it.

## How it ran

- **The project:** a packaged project built around the newsletter example. It had the delivered
  `newsletter-signup` spec folder from `docs/examples/`, with an end-user doc row in its
  Documentation table; a stamp naming the `end-user-docs` module; tracker and end-user docs
  conventions; one existing editor guide page, "Edit the homepage banner", in the destination's
  voice; and session notes for the task in review: the preview, the pull request, and Dana's
  request.
- **Two kits:** the two skills as on `main` at `aa2ed6e` (without the pass) and on this branch at
  `c357594` (with it), with Step 0 removed and the plugin's paths filled in. The kits had neutral
  names, so the drafting agents couldn't tell which was which.
- **The drafts:** 12 subagents on Opus 5.5, three per cell: Dana's review update and the end-user
  page, each with and without the pass. Each got the same prompt, naming only the task and its kit,
  and nothing about the comparison.
- **The grading:** one more agent read the 12 drafts under shuffled labels. For each, it marked a
  checklist of required content (9 items for the update, 10 for the page), quoted each pattern from
  `PROSE-PATTERNS.md` it found, flagged claims the spec and session notes don't support, scored the
  draft 1–5 for its reader, and ranked each set of six. A script counted words and structure.

## End-user page

| | Without | With |
|---|---|---|
| Words, average | 573 | 377 |
| Bullets with a bold lead-in, per page | 6–7 | 0 |
| Headings, per page | 1–6 | 0–1 |
| Patterns found, three drafts | 10 | 0 |
| Reader score, average | 3.3 | 4.0 |
| Places in the blind ranking | 2, 5, 6 | 1, 3, 4 |
| Required content missed | the rate-limit number given (P10) in 2 | P10 in 3; "no web team needed" in 1; the draft line after the title in 1 |
| Unsupported claims | 0 | 1 |

The pages with the pass followed the existing guide page: inline bold labels on paragraphs, plain
bullets, almost no headings. All three without it put a bold lead-in on every bullet of a list and
said something twice, and two replaced the page's labels with headings.

One page with the pass dropped that an editor needs no deploy and no web team, which was the
requester's main point. Another counted the rate limit per reader, when it is per
network. The only page to pass every checklist item was written without the pass, at 540 words.

## Stakeholder update

| | Without | With |
|---|---|---|
| Words, average | 283 | 259 |
| Patterns found, three drafts | 4, all "saying it twice" | 0 |
| Reader score, average | 4.3 | 4.7 |
| Places in the blind ranking | 1, 5, 6 | 2, 3, 4 |
| Required content missed | 0 | 0 |
| Unsupported claims | 0 | 1 |

All six updates passed every checklist item. The skill's style rules and its review template
already keep out most of the list, so the pass removed four restated clauses and little else. The
unsupported claim made the requester's sign-off a condition for release, which the session notes
don't say and the pass doesn't suggest.

## What changed

- **`PROSE-PATTERNS.md`'s pass gained step 3, "Cut words, not facts":** every fact the draft gave
  is still there after the pass, and a cut that took one puts it back.
- **The four skills keep the pass.** The update's gain is small, but the review and delivered
  updates post without anyone reading them first, and the read costs about 750 tokens per draft.

## Limits

- Three drafts per cell, one model, one project, and one task per skill. The same session wrote
  the project and ran the comparison.
- The grader had the pattern list, so the pattern counts follow the treatment by design. The
  checklist, the unsupported claims, and the reader scores are the measures to weigh.
- P10 counts a rate-limit number as technical detail. Five of the six pages gave one, so it doesn't
  separate the conditions.
- `/adf:write-docs` and `/adf:framework-feedback` weren't run, and step 3 wasn't run at all.
- The project and kits aren't in `fixtures/`: a rerun rebuilds them from this report.
