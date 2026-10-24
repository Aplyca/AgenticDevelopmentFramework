---
name: end-user-docs
description: With the end-user-docs module: draft, update, or publish a feature's end-user page in the doc tool its users read (ClickUp Docs, Confluence, Notion), never in the repository, writing only on the developer's yes. Use after the approval gate, after the merge, or when asked.
argument-hint: "[spec folder or tracker task] [draft | update | publish]"
---

> **Step 0 — which copy.** This is the packaged copy ([decision 0016](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0016-packaged-install.md)). Unless this project's instructions say "This project uses the packaged install", stop here: open `.claude/skills/end-user-docs/SKILL.md` and follow that file instead — it's the version this project upgraded to. If it doesn't exist, the project doesn't use this skill: say so and stop.

# End-User Docs

A feature can need two kinds of documentation, and each has its own home:

- **Technical docs** — admin and operator guides, API contracts, architecture, reference — for the
  team and its agents, in the repository, written with `/adf:write-docs`.
- **End-user docs** — how the people who use the product do what a feature lets them do — in the doc
  tool they have access to, written with this skill. **The doc tool is their only home:** the
  repository keeps only the spec's line that names the page.

Not every feature needs an end-user page — only one that changes what end users see or do, as the
spec's § Documentation › End-user docs says. The page follows the feature in three modes:

- **Draft** — docs first, after the approval gate and before implementation: written from the spec
  and the planned tests, in the drafts location end users can't see.
- **Update** — when the build changes what the draft says (a renamed label, an extra error), and at
  Phase 5's reconcile.
- **Publish** — once the feature ships: reconciled with what was built, the final page goes to the
  end-user doc, and the draft is retired.

## Steps

1. **Check the module.** Read the stamp on the first line of `AGENTS.md` (`head -1 AGENTS.md`).
   Unless its `modules:` list names `end-user-docs`, say "this project doesn't keep end-user docs in
   a doc tool — the end-user-docs module isn't installed" and stop: its end-user docs, if any, are
   repository docs for `/adf:write-docs`. Then read `docs/END-USER-DOCS.md`: the doc tool, the
   end-user doc, the drafts location, the tools, the end users, the language and voice, screenshots,
   when to publish, and § Page structure. Placeholders left in it are questions for the developer
   before going on.

2. **Find the feature, the mode, and the draft.**
   - **The feature:** the argument, or the spec folder on this branch. Read spec § Documentation ›
     End-user docs: the page each audience needs, new or existing. Marked Not applicable, or absent:
     say the spec lists no end-user page, and stop — adding one is a spec change first
     (`/adf:write-spec`, as a change request once the feature is delivered). With no spec folder (the
     fast or careful lane), the tracker task and the diff are the source, and the developer says
     whether end users need a page.
   - **The mode:** the argument; otherwise draft before implementation, publish once the pull request
     has merged (`gh pr view --json state`) and the settings' moment to publish has come, update in
     between.
   - **The draft:** the Phase 1 task in `tasks.md` links it; otherwise list the drafts location's
     pages — a feature's draft is the one whose subtitle names its spec folder or tracker task.

3. **Read the sources.**
   - **What end users will do:** the spec — Functional (the ACs and edge cases), Design (the labels,
     messages, and states they'll see), Localization — and `plan.md` § Test strategy: the tests are
     the precise statement of the behavior the page describes. For a change request, the `CR N`
     section only.
   - **What was built** (update and publish): the commits since the spec's approval, the tests as
     they pass, the copy in the code or the CMS. Where it differs from the draft, what was built wins:
     the page describes the product end users will use.
   - **The end-user doc:** its page tree, and the pages the feature touches — to match their tone,
     structure, and depth, and to place the page: a new page under a parent, or a section of an
     existing one.

4. **Write the page** by § Page structure, in the language and voice the settings name:
   - the end user's task, in their words, with the product's labels exactly as they'll see them — no
     code, endpoints, or internal names, no spec IDs;
   - every step, message, and limit backed by an AC, an edge case, or a planned test — or, once
     built, by the product;
   - no screenshot or sample you haven't seen: a draft marks where one goes, `[Screenshot: <what it
     shows>]`, when the settings want them; at publish each becomes a screenshot of the released
     product, or goes;
   - a draft opens with one line — "Draft — not yet released. Spec: `<spec folder>`" — and the
     published page carries no draft line.

5. **Show the full draft,** as the last text of your turn: the page in full, where it goes, and — for
   an existing page — what changes on it and every edit made in the tool since the draft (step 6).
   Then ask before posting: the yes is to this exact text, every time, even when the developer asked
   for the docs.

6. **Write it** — on the yes, the page as approved and nothing else:
   - **Draft:** create the page in the drafts location, named after the target page, with the
     subtitle `Draft for <target page> · <spec folder>` — or replace an existing draft's content.
     Read it back. Tick its Phase 1 task with the draft's link, and commit the tick with the other
     Phase 1 docs (`docs: draft end-user docs for <slug>` when there are none).
   - **Update:** replace the draft's content. Read it back.
   - **Publish:**
     1. **Read the live page first,** when it exists. Every difference the draft didn't make is an
        edit made in the tool since: it was in the draft you showed, for the developer to keep or
        drop. Nothing on a live page is lost silently.
     2. **Create the page** under its parent in the end-user doc, or replace the existing page's
        content. Read it back.
     3. **Retire the draft:** rename it `[Published] <name>` and replace its content with the
        published page's link and the date, so the text has one home. Deleting it is the
        developer's, in the tool.
     4. **Report** the published link. The delivered update links it (`/adf:stakeholder-update`).
        When that update already went out, offer a one-line reply on the tracker task with the link.
        Either is a write the requester can see: confirm it first (`docs/TRACKER-INTEGRATION.md`
        § Rules for agents).
   - **Publish without a feature** (at a release): list the drafts location's unretired drafts, and
     publish the ones whose features shipped, one approval per page.

## Rationalizations (do not accept these)

| Agent says... | Why it's wrong |
|---|---|
| "The project has `/adf:end-user-docs` available, so I'll write the page" | The plugin carries it for every project. Only a stamp that names `end-user-docs` turns it on. |
| "Every feature deserves a user page" | The spec decides. A feature that doesn't change what end users see or do needs none. |
| "I'll keep a copy in `docs/user/`, so it's reviewed in the pull request" | The doc tool is the only home: two copies drift. The developer reviews the page in full before it's written. |
| "I'll publish it now, so it's ready on release day" | A page for an unreleased feature tells end users about something they can't use. It stays a draft until the feature ships. |
| "I'll replace the live page with the approved draft" | Someone may have edited it in the tool since. Read it first, and show every difference the draft didn't make. |
| "A screenshot would help — I'll describe one as if it existed" | It's wrong the moment the product differs. Mark where it goes; the real one comes from the released product. |
| "End users will want to know which endpoint it calls" | That's technical documentation, for `/adf:write-docs`. The end-user page speaks the end user's task and labels. |
| "The developer said write the user docs, so I'll post the page" | The request starts the draft. Show it in full, and post only on the yes to that text. |

## Red flags (stop and reassess)

- The stamp doesn't name `end-user-docs`, and you're about to write or offer anything.
- A page for a feature that hasn't shipped is about to go to the end-user doc.
- A step, label, or message no AC, test, or built product backs.
- A code path, endpoint, table, or spec ID on an end-user page.
- A screenshot placeholder or a draft line on a published page.
- The page's text is about to go into the repository.

## Verification

- [ ] The stamp names `end-user-docs`, and `docs/END-USER-DOCS.md` was read
- [ ] The spec lists the page — or, with no spec folder, the developer confirmed end users need it
- [ ] Every step, message, and limit is backed by an AC, an edge case, a test, or the built product; nothing is fabricated
- [ ] The page follows § Page structure, in the end users' language and the product's labels, with nothing technical
- [ ] The full page was shown, written only on the yes to that text, and read back
- [ ] A draft went to the drafts location; only a shipped feature's page went to the end-user doc
- [ ] At publish: the live page's edits were shown first, no placeholder or draft line was left, and the draft was retired
- [ ] Nothing of the page's text was written to the repository
