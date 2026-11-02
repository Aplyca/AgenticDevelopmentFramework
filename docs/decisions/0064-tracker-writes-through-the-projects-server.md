# 0064: Tracker writes go through the project's server, and a correction an edit would damage is the developer's

- **Status:** accepted
- **Date:** 2026-11-02
- **Amends:** [0053](0053-stakeholder-updates-at-three-moments.md) — the read-back checks the author,
  and a correction no longer always edits the comment;
  [0043](0043-track-time-in-the-tracker.md) and [0048](0048-end-user-docs-in-the-doc-tool.md) — their writes
  name the server and the account

## Context

An adopting project wrote to ClickUp through its MCP server for a while and read back every write.
What it found applies to more than ClickUp:

- **Two servers, two sign-ins.** A host app can carry its own tracker connector — the Claude desktop
  app's ClickUp connector, for example — beside the project's server in `.mcp.json`. The connector is
  signed in separately, possibly to another account or workspace, so a write through it can appear
  under someone else's name. Its tools carry their own prefix, so the project's read-only allow list
  doesn't cover them, and its write prompt doesn't say which account posts.
- **Edits through the tools lose what markdown can't carry.** `clickup_update_comment` dropped a
  comment's mention. A pasted image reads back as a file-name line and a comment's link preview as a
  plain link, so rewriting either through markdown would very likely lose them too. `/stakeholder-update`
  said "a correction edits that comment".
- **The tools can't make everything the editor can.** A link to a task, posted through the tools,
  shows as a plain link; the preview — which keeps showing the task's current name — comes only from
  pasting the link in ClickUp's editor. ClickUp also moves a mention to the end of a comment, and a
  tracker automation can change a status right after it's set.

## Decision

- **Writes go only through the project's server, as the developer.** A connector built into the host
  app may read, never write. Before the session's first write, the agent asks the project's server
  who is signed in and tells the developer which account will post; when the server isn't connected,
  it writes nothing until the developer signs it in. This holds for `/stakeholder-update`'s posts and
  status moves, `/track-time`'s entries, and `/end-user-docs`'s pages.
- **Every write is read back,** the author and the status included. A status an automation changed is
  reported, not undone.
- **A correction the tools would damage is the developer's, in the tracker.** The agent edits posted
  text through the tools only when it holds no mention, pasted image, or link preview; otherwise it
  shows the corrected text.
- **Links the tools can't preview are the developer's to paste,** the same way as images: the agent
  posts the plain link, asks for the paste, and reads the comment again.
- `docs/TRACKER-INTEGRATION.md` § Stakeholder updates gains two lines a project fills in — **Links to
  tracker items** and **Editing posted text** — and its **Mentions** line says where the tracker
  places a mention. The `clickup` module fills them in, with what was observed in November 2026.

## Consequences

- A write can't land under another account without the developer having been told whose it is.
- The developer makes some fixes in the tracker by hand, as they already paste images; the agent says
  exactly what to change.
- One more call per session (who is signed in) and one per write (the read-back, which the comments
  had already).
- Not yet tested: whether a rewrite through the tools loses link previews and pasted images, and
  whether a mention on a comment's last line stays there. The `clickup` module marks them; a later
  test confirms or corrects them.
