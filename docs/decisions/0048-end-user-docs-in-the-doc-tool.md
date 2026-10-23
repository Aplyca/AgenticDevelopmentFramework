# 0048: End-user docs live in the doc tool end users read, drafted before the code and published once it ships (end-user-docs module)

- **Status:** accepted
- **Date:** 2026-10-22

## Context

A feature can need two kinds of documentation with different readers:

- **Technical docs** — admin and operator guides, API contracts, architecture, reference — for the
  team and its agents. They live in the repository, and `/write-docs` writes the pre-implementable
  ones before the code (docs first).
- **End-user docs** — how the people who use the product do what a feature lets them do. Many teams
  keep them in a doc tool their end users already have access to — ClickUp Docs, Confluence, Notion —
  because those users never see the repository.

The framework had no place for the second kind. `/write-docs` writes to the repository, and the
skeleton's `TRACKER-INTEGRATION.md` only suggested a usage guide in the tracker task's description.
So end-user pages were written by hand after delivery, if at all, and drifted from what was built.

Most of what's needed exists: the spec's § Documentation already decides which docs a feature needs,
the tracker's MCP server already reaches the doc tool (ClickUp's has page tools that read, create,
and update pages in Markdown), and its rules already require a yes before every write the requester
can see.

Some teams have no such doc tool, and shouldn't see the feature.

## Decision

- **An `end-user-docs` module turns the feature on.** Its `module.json` names `/end-user-docs`, which
  `adf` carries, as `/track-time` is carried for `time-tracking` (decision 0043). It installs
  `docs/END-USER-DOCS.md`: the doc tool, the end-user doc, the drafts location, the tools that read
  and write pages, the end users, their language and voice, screenshots, when to publish, and the
  structure of a page. The skill acts only where the stamp on `AGENTS.md`'s first line names the
  module.
- **The doc tool is the end-user docs' only home.** No page text goes into the repository. The spec's
  new § Documentation › End-user docs names the page a feature needs, or says Not applicable — only
  features that change what end users see or do get one — and the Phase 1 task links its draft.
  `/write-docs` keeps the repository's docs, and hands end-user pages to `/end-user-docs`.
- **Docs first, as a draft.** After the approval gate, `/end-user-docs` drafts the page from the spec
  and the planned tests, in a drafts location end users can't see — in ClickUp, a private Doc beside
  the end-user one. It updates the draft when the build changes what it says, and at Phase 5's
  reconcile.
- **Published once the feature ships.** At the moment the settings name — after the merge, or at the
  release — the skill reconciles the draft with what was built, reads the live page first and shows
  every difference the draft didn't make, writes the final page to the end-user doc, and retires the
  draft: renamed `[Published]`, its content replaced with the page's link. `/wrap-up` offers it once,
  before the close-up, only with the module and only when the settings publish after the merge.
- **Every page on the developer's yes to its exact text,** shown in full first, then read back.
  Screenshots and samples are never invented: a draft marks where one goes, and at publish each
  becomes a screenshot of the released product or goes.

## Consequences

- **Positive:**
  - End users get a page for each feature that changes what they do, written from the same ACs and
    tests as the code, and published when the feature ships — not after it, if at all.
  - The two kinds of docs stop competing for one skill: technical docs stay in the repository, for
    the team and its agents; end-user pages go where end users read.
  - A team without a doc tool never sees it: no spec subsection to fill, no offer at the wrap-up.
- **Negative / cost:**
  - **No review in the pull request.** The page isn't in the diff; the developer reviews it in full
    before each write instead. The doc tool's own history, if it keeps one, is the record.
  - **Two locations to keep apart.** A draft in the end-user doc would be visible to end users, so
    the project needs a drafts location they can't see.
  - **Retired drafts pile up.** ClickUp's MCP server can't delete a page; the developer deletes them
    in the tool.
  - **Edits made in the tool** between the draft and the publish are only caught by comparing the
    live page with the draft; the developer decides which to keep.
  - **Publishing at a release** isn't triggered by anything: the developer runs the skill then, and
    it lists the drafts waiting.

## Alternatives considered

- **Write the page in the repository and publish a copy to the doc tool.** Declined: the team wanted
  the doc tool as the only home. Two copies drift, and an edit made in the tool would be overwritten
  at the next publish.
- **Write the draft into the end-user doc directly, marked "Draft".** Declined. End users would read
  about features they can't use yet.
- **Publish only after delivery, with no draft.** Declined. Writing the page before the code is what
  makes it describe what the feature should do, as docs first does for the repository's docs.
- **Extend `/write-docs` with a doc-tool location.** Declined. The two kinds of docs differ in
  reader, home, review, and timing — a draft hidden from its readers, published only once the
  feature ships — and a project without a doc tool shouldn't carry the second.
- **A section in the skeleton's `TRACKER-INTEGRATION.md`, present or not.** Declined, as for time
  tracking (decision 0043): modules are how a project turns a feature on.
- **Put it in `adf-connect`.** Declined. Writing documentation is process, which `adf` carries; the
  doc tool's connection stays with `clickup` or `/adf-connect:connect` (decision 0023).
