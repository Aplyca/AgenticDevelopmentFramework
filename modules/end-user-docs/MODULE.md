# Module: end-user-docs

For teams whose stakeholders read the system's guides in a doc tool — ClickUp Docs, Confluence,
Notion — rather than in the repository. Stakeholders are the people who use the system: visitors, the
client's **editorial** team, and its **administrators**; the guides say how to use it — create and
publish content, manage users and settings — not how it's built. Adds `/end-user-docs`, which writes
a feature's guide page there: drafted before implementation where end users can't see it, updated as the build changes it,
and published to the end-user doc once the feature ships, each page written only on the developer's
yes to its exact text
([decision 0048](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0048-end-user-docs-in-the-doc-tool.md)).

The repository keeps the technical docs — runbooks, API contracts, architecture — for the team and its agents (`/write-docs`). A project
without the module keeps its end-user docs there too, if it has any: `/end-user-docs` stops, and
`/wrap-up` never offers it.

## What it adds

| File | Purpose |
|---|---|
| `docs/END-USER-DOCS.md` | The project's settings — the doc tool, the end-user doc, the drafts location, the tools that read and write pages, the end users, the language and voice, screenshots, when to publish — and the structure of a feature's page |
| `.claude/skills/end-user-docs/` | **Committed install only:** the skill. A packaged project gets `/adf:end-user-docs` from the `adf` plugin, which `module.json` names |

## Install

`/adopt` and `/upgrade` install it when you choose the module. By hand:

- **Committed install:** `cp -Rn modules/end-user-docs/files/. /path/to/your-repo/`, then
  `scripts/build-committed.py /path/to/your-repo --modules end-user-docs`, which writes
  `/end-user-docs` from the `adf` plugin.
- **Packaged install:** `cp -Rn modules/end-user-docs/files/. /path/to/your-repo/`. The skill comes
  with `adf`, already on.

Then add `end-user-docs` to the `modules:` list in the stamp on `AGENTS.md`'s first line:
`/end-user-docs` stops in a project whose stamp doesn't name it. Removing it from the stamp turns the
feature off.

The agent reaches the doc tool through its MCP server: the `clickup` module for ClickUp Docs, or
`/adf-connect:connect` for another tool's official server (Confluence comes with Atlassian's).

## Customize

In `docs/END-USER-DOCS.md`:

1. **End-user doc and drafts** — the doc end users read, and a place for drafts they can't see. In
   ClickUp, make the drafts a private Doc in the same space, which end users aren't shared on: a
   draft page inside the end-user doc would be shared with them along with the rest of it.
2. **Read and write** — the tool's page tools. With the `clickup` module, listing and reading pages
   fall under its read-only allowlist, and creating or updating a page prompts.
3. **End users, language, and voice** — who reads the pages, and in which language: it may differ
   from the repository's.
4. **Published when** — after the merge to the production branch, when the release deploys, or on
   request. `/wrap-up` offers to publish only when it's after the merge.
5. **Page structure** — the sections of a feature's page; match the pages the end-user doc already
   has.

In each spec, § Documentation › End-user docs names the page a feature needs, or says Not applicable.

## Good to know

- **The doc tool is the only home.** No page text goes into the repository: the spec names the page,
  and the Phase 1 task links its draft. The doc tool's own history, if it keeps one, is the record of
  what was published.
- **Live pages are read before they're replaced.** Someone may edit a page in the tool; at publish,
  every difference the draft didn't make is shown, for the developer to keep or drop.
- **A retired draft stays in the drafts location,** renamed `[Published]` and pointing at the page.
  Deleting it is the developer's, in the tool: ClickUp's MCP server can't delete a page.
- **Each developer acts as themselves.** Pages carry the developer's name as their author, like any
  other write through the tracker's server.

## Verify

- `head -1 AGENTS.md` names `end-user-docs` in its `modules:` list, and `docs/END-USER-DOCS.md` has
  no placeholders left.
- In a feature's session after the approval gate, `/end-user-docs` (packaged: `/adf:end-user-docs`)
  shows the draft page and writes nothing until you approve it — and then only to the drafts
  location.
