# 0068: A Contentful server is named after its project, so each project has its own sign-in and space

- **Status:** accepted
- **Date:** 2026-11-05
- **Refines:** [0057](0057-read-only-profiles-for-connected-services.md) — Contentful's read-only
  profile, and the follow-up the upgrade lists for a Contentful server

## Context

A developer often works on several projects, each with its own Contentful space. 0057 had `/connect`
name the server `contentful` in every project, with the same hosted URL in each.

- **The URL carries no space.** The developer picks spaces and environments on Contentful's consent
  screen when signing in to `https://mcp.contentful.com/mcp`.
- **Claude Code keeps one sign-in per server.** Its documentation says sign-ins are stored per
  endpoint. With the same name and URL in every project, a developer's first sign-in, and the spaces
  picked in it, reaches every project that uses that name. An agent in one project could read
  another project's content.
- **A name of its own gives a project a sign-in of its own.** Tested on 2026-11-05 in an adopting
  project: a server named `contentful-<project>` signed in on its own, and the developer picked only
  that project's space.

Supabase and Vercel don't have this problem: their URLs name the project.

## Decision

1. **A Contentful server is named `contentful-<project>`,** with `<project>` the repository's name in
   lowercase letters, digits, and hyphens. When signing in, the developer picks only this project's
   space and environments. The allow list names the tools under that name:
   `mcp__contentful-<project>__<tool>`.
2. **A server already named plain `contentful`** gets the rename offered when `/connect` runs again.
   Each developer then signs in again under the new name.
3. **`/connect`'s verification checks the scope:** `list_spaces` returns only this project's space.
4. **The upgrade's follow-up covers the name.** 0057's migration lists
   `/adf-connect:connect contentful` for a Contentful server until it's named after its project and
   its reads are allowed under that name.

## Consequences

- **Positive:**
  - An agent reaches only the space of the project it works in, whatever the developer connected
    elsewhere.
  - The name is committed in `.mcp.json`, so the whole team gets the same scope.
- **Negative / cost:**
  - **A developer signs in once per project,** not once for every project.
  - **A project already connected as `contentful` keeps sharing** until someone runs the follow-up.
  - **The behavior is Claude Code's, not documented by name.** Its documentation speaks of
    endpoints, not names. `/connect`'s new check, `list_spaces`, would show the change if it stopped
    holding.

## Alternatives considered

- **One sign-in for every space, with each project's space written in `DEV-SETUP.md`.** No new
  name, but every project's agent can read every space the developer picked.
- **Contentful's open-source server, pinned with `SPACE_ID`.** It reaches one space by
  configuration, but it takes a personal Management API token with the developer's full rights, and
  the Contentful MCP app's read-only setting doesn't apply to it.
- **A query string on the URL to make each project's endpoint different.** Not documented by
  Contentful or by Claude Code, and not tested.
