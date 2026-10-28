# 0057: Vercel and Contentful get fixed read-only profiles in `/connect`; reads that return secrets are denied; GitHub stays on `gh`

- **Status:** accepted
- **Date:** 2026-10-28
- **Refines:** [0023](0023-plugins-by-concern.md) — where Supabase, Vercel, and Contentful go, and how
  `/connect` builds a server's allow list

## Context

Teams asked for two services, both read-only:
- **Vercel:** to troubleshoot deployments and their logs.
- **Contentful:** to read content entries and the content model.

They also asked whether GitHub's MCP server is needed beside the `gh` CLI.

0023 put both services in `adf-connect`'s `/connect` with no module. `/connect` wrote the URL, then
the agent sorted the server's tools into reads and writes at connect time. Vercel's documentation
(checked 2026-10-28) shows why that sorting isn't enough:

- **Vercel has no read-only option.** The OAuth grant carries the developer's whole Vercel role.
  The server lists 217 tools: deploys, domains, purchases, sandboxes, firewall rules.
- **Names mislead in both directions.**
  - `get_project_env` and `get_shared_env_var` read, but what they return is the decrypted secret.
  - `get_access_to_vercel_url` sounds like a read and creates a shareable link to a protected
    deployment.
  - `create_observability_query` sounds like a write and only queries.
- **A project-scoped URL exists.** `https://mcp.vercel.com/<team>/<project>` binds one team and
  project, and doesn't register the account-wide tools such as `deploy_to_vercel`.

Contentful is the opposite case. A space admin sets each environment's tools to read-only in the
Contentful MCP app, and the server then refuses every write, whatever the client allows.

## Decision

1. **`/connect`'s catalog carries a read-only profile for Vercel and Contentful.** Each profile
   lists the tools to allow, to deny, and to leave prompting, by exact name. The agent starts from
   the profile and checks it against the server's real tool list. A tool the profile doesn't name
   prompts.
   - **Vercel:** the project-scoped URL. The allow list covers projects, deployments, build logs,
     runtime logs and errors, and documentation search. Reading production logs needs the
     developer's yes, written down.
   - **Contentful:** read-only set in the Contentful MCP app first. The allow list covers spaces,
     environments, content types, entries, locales, assets, and tags.
2. **A read that returns a secret is denied, not allowed.** It goes in `permissions.deny`, as the
   skeleton denies `Read(.env)`. A ground rule of `/connect`, for every service.
3. **No modules for them.** A module would only add the allow list as committed files. Vercel's URL
   needs each project's slugs, and Contentful's real limit is set in Contentful itself.
4. **The upgrade points connected projects at the profile.** When `.mcp.json` already has a Vercel or
   Contentful server, `/adf:upgrade` lists `/adf-connect:connect <service>` under the PR's Follow-ups.
   It changes no file itself: the developer reviews `/connect`'s changes as a change of their own.
5. **GitHub stays on `gh`.** `gh api` reaches the whole API, and the skeleton's `ask` rules make
   each `gh` write prompt. GitHub's MCP server would add its tools to every session's context, and a
   second way to write that those rules don't see.

## Consequences

- **Positive:**
  - A Vercel or Contentful connection is read-only the same way in every project. It doesn't depend
    on how one agent sorted 217 tool names.
  - Secret values stay out of conversations and transcripts by rule, not by the agent's care.
- **Negative / cost:**
  - **The profiles go stale when a vendor renames or adds tools.** A missing name prompts, which is
    safe. The catalog's "checked on" date says when to look again.
  - **Contentful's tool names come from its open-source server.** The hosted server is expected to
    match, and `/connect` step 6 confirms it on the first connection.
  - **Projects that already connected either service** keep their old allow list until someone runs
    the follow-up the upgrade lists.

## Alternatives considered

- **`vercel` and `contentful` modules like `clickup`,** each with an install script and a settings
  fragment. `/upgrade` would refresh the allow lists. But the install would need each project's
  slugs and environments, and `/adopt`, `/upgrade`, and the evals would each grow a module for what is
  one catalog entry.
- **Deny every Vercel write by name.** There are too many, and new ones arrive unlisted. Leaving
  writes off the allow list makes them prompt, and that's the framework's rule.
- **GitHub's read-only MCP endpoint.** It's read-only, but every read it adds is already one
  `gh api` call away.
