# 0086: One prose pass for the text people read

- **Status:** accepted
- **Date:** 2026-11-16

## Context

- **Four skills write text for readers outside the team:** `/adf:stakeholder-update` (the
  requester's messages), `/adf:end-user-docs` (the end-user page), `/adf:write-docs` (the
  user-facing docs a plan lists), and `/adf:framework-feedback` (a public issue the framework's
  maintainers read). The review and delivered updates post without anyone reading them first.
- **Two more write for the team:** `/adf:open-pr` (the pull request's description, mostly its
  template) and `/adf:record-decision` (decision records, already "short, specific, honest"). The
  developer reads both in the pull request, and `/adf:open-pr` runs on every task.
- **None of them checked the text for machine-written patterns:** throat-clearing openings,
  "not X but Y" contrasts, hedges on behavior that was verified, a bold lead-in on every bullet,
  one-row tables. Readers who spot them skim, and a requester's update or an end-user page loses
  the attention it was written for.
- **Issue #79 proposed a pass like this for external docs,** from personal skills used across
  several projects. The maintainer asked for one short list that every skill writing prose for
  people uses, not a list inside one skill.

## Decision

- **One list, in a reference doc:** `PROSE-PATTERNS.md`, in `adf`'s `docs/` with the other
  reference docs (decision 0019). Each pattern has an example and what to write instead, in three
  groups: openings and closings, sentences, structure.
- **The four skills that write for readers outside the team run the pass on each draft** before
  showing or posting it, at the step that writes the text, and check it in their Verification. The skill names the doc there, so it is
  read only when text is written.
- **The destination wins:** a template's fixed headings and labels, the voice of the page or docs
  being updated, and the project's conventions stay, whatever the list says.
- **The pass cuts words, never facts.** A pass that adds text went wrong, and so did one that drops
  a fact the draft gave.

## Consequences

- **The four skills read one more file** when they write: about 750 tokens, once per draft.
- **A blind comparison on the newsletter example backed it for end-user pages**
  ([report](../../evals/dynamic/reports/2026-11-21-prose-pass.md)): three pages with the pass were
  a third shorter, had none of the patterns, matched the existing page's voice, and scored higher
  for their reader. Stakeholder updates barely changed, since the skill's style rules already cover
  most of the list. One page dropped a fact its reader needed, which is why the pass now says to
  keep every fact.
- **The list is advice, not a gate.** The static checks confirm each skill names the pass; nothing
  can check the prose itself.
- **A committed project gets `docs/PROSE-PATTERNS.md`,** overwritten at each upgrade like the other
  reference docs. A team that wants its own patterns writes them in its own conventions, which win.
- **Not covered:** `/adf:open-pr` and `/adf:record-decision`, whose readers are the team;
  `/adf:handoff` and `/adf:track-time`'s descriptions, which are fixed formats of a line or two;
  and the spec's usage guide, which `/adf:stakeholder-update guide` posts as approved.

## Alternatives considered

- **A pass inside `/adf:write-docs` alone,** as the issue first proposed: the other three skills
  would keep writing the patterns, and the list would need copying to reach them.
- **Every skill that writes prose, the pull request's description and decision records included.**
  Declined: the team reads those in the pull request, where the developer edits what they don't
  like, and an unenforced step in `/adf:open-pr` would run on every task.
- **The list in the always-loaded rules:** every session would pay for it, and most never write for
  people.
- **A reference file beside one skill, read by the others through its folder:** no skill names
  another's files today, and the list would move if that skill did.
- **A script that flags the patterns:** word lists can't tell a hedge on known behavior from an
  honest one, or a template's label from a bold lead-in, and the text is often in another language.
