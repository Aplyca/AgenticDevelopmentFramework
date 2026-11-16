# 0086: One prose pass for the text people read

- **Status:** accepted
- **Date:** 2026-11-16

## Context

- **Five skills write text that people read outside the session:** `/adf:stakeholder-update` (the
  requester's messages), `/adf:end-user-docs` (the end-user page), `/adf:write-docs` (the docs a
  plan lists), `/adf:open-pr` (the pull request's description), and `/adf:record-decision` (decision
  records).
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
- **Each of the five skills runs the pass on its draft before showing or posting it,** at the step
  that writes the text, and checks it in its Verification. The skill names the doc there, so it is
  read only when text is written.
- **The destination wins:** a template's fixed headings and labels, the voice of the page or docs
  being updated, and the project's conventions stay, whatever the list says.
- **The pass only cuts.** A pass that adds text went wrong.

## Consequences

- **The five skills read one more file** when they write: about 700 tokens, once per draft.
- **The list is advice, not a gate.** The static checks confirm each skill names the pass; nothing
  can check the prose itself.
- **A committed project gets `docs/PROSE-PATTERNS.md`,** overwritten at each upgrade like the other
  reference docs. A team that wants its own patterns writes them in its own conventions, which win.
- **Not covered:** `/adf:handoff` and `/adf:track-time`'s descriptions, which are fixed formats of a
  line or two, and the spec's usage guide, which `/adf:stakeholder-update guide` posts as approved.

## Alternatives considered

- **A pass inside `/adf:write-docs` alone,** as the issue first proposed: the other four skills
  would keep writing the patterns, and the list would need copying to reach them.
- **The list in the always-loaded rules:** every session would pay for it, and most never write for
  people.
- **A reference file beside one skill, read by the others through its folder:** no skill names
  another's files today, and the list would move if that skill did.
- **A script that flags the patterns:** word lists can't tell a hedge on known behavior from an
  honest one, or a template's label from a bold lead-in, and the text is often in another language.
