# End-User Docs

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: where end-user documentation lives and how /end-user-docs writes it -->

The people who use the system — visitors, the client's editorial team, its administrators — read its
guides in a doc tool they have access to, not in the repository. `/end-user-docs` writes them there:
user guides, editorial guides (create, edit, publish content), and administrative guides (manage
users, settings, configuration), for the features that change what they see or do:

- **Draft** — before implementation, docs first: the page goes to the drafts location, which end
  users can't see.
- **Update** — when the build changes what a draft says.
- **Publish** — after the feature ships: the final page goes to the end-user doc, and the draft is
  retired.

**The doc tool is the only home of this documentation.** The repository keeps the technical docs —
for the team and its agents, written with `/write-docs` — and, in the spec, which end-user page a
feature needs. Nothing else.

## Settings

<!-- CUSTOMIZE: fill these in. -->

- **Doc tool:** [ClickUp Docs — or Confluence, Notion, …]
- **End-user doc:** [the doc end users read — its link and ID, e.g. `https://app.clickup.com/<workspace>/v/dc/<doc-id>`]
- **Drafts:** [where a draft lives until its feature ships, hidden from end users — e.g. a private
  ClickUp Doc "User guide — drafts" in the same space, which end users aren't shared on. Its pages
  mirror the end-user doc's structure]
- **Read and write:** [the tool's read and write tools — with ClickUp: `clickup_list_document_pages`
  and `clickup_get_document_pages` read, under the `clickup` module's allowlist;
  `clickup_create_document_page` and `clickup_update_document_page` write, and prompt]
- **Audiences:** [who reads the guides — e.g. the public, the client's content editors, its administrators — and what each already knows; one section or guide per audience]
- **Language and voice:** [the language(s) the pages are written in; second person, present tense,
  the product's own UI labels]
- **Screenshots:** [none — or which pages carry them; they come from the released product, added at
  publish]
- **Published when:** [after the merge to the production branch — or when the release deploys, or on
  request]

## Page structure

How a feature's page reads. `/end-user-docs` follows it and matches the pages already in the
end-user doc. <!-- CUSTOMIZE: add, remove, or rename sections. -->

| Section | What it says |
|---|---|
| Title | The task the end user wants to do, in their words — "Subscribe to the newsletter" |
| What it's for | One or two sentences: what the feature lets them do, and when they'd use it |
| Before you start | What they need first — a role, an account, a setting |
| Steps | Numbered, one action each, with the exact labels they'll see |
| What happens next | What they'll see when it works: a message, an email, a change on the page |
| If something goes wrong | The errors and limits they can meet, and what to do about each |
| Related | Other pages in the end-user doc |
