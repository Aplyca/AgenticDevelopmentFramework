# MCP integration

How to expose this project's specs, ADRs, runbooks, and other knowledge artifacts as **Model Context Protocol (MCP) resources** so AI tools (Claude Code, Cursor, Antigravity, others) can query them via a uniform protocol instead of file reads.

This is **optional**. The framework works without MCP. But for projects with a large `specs/` directory, many ADRs, or multiple runbooks, exposing them as queryable MCP resources turns "find all specs touched in the last week" or "give me the Security section of every spec in the marketing area" from a manual file-walk into a single AI-readable query.

## What MCP is (one paragraph)

The Model Context Protocol is an open standard from Anthropic that lets AI tools discover and call tools, read resources, and follow prompts from external servers via a uniform JSON-RPC API. AI tools like Claude Code can connect to multiple MCP servers and use their resources alongside the local file system. As of 2026 it has authentication semantics, schema validation, and is supported across major AI coding tools. See [modelcontextprotocol.io](https://modelcontextprotocol.io) for the current spec.

## Why expose framework artifacts via MCP

The framework's primary artifacts (specs, ADRs, runbooks, admin guides) are markdown. Without MCP, an AI tool reads them via the file system — fine for small projects, awkward at scale because:

- Cross-spec queries ("which specs reference the Mailchimp integration?") require manual greps
- Section-level access ("show me the Security section of all UI specs") requires custom parsing
- The AI loads more context than necessary (full spec files vs. just the relevant section)
- No way to cleanly expose specs to multiple AI tools with the same interface

MCP solves this by giving you a server that can:
- List specs/ADRs/runbooks as discoverable resources
- Return full content OR specific sections by URI
- Filter by metadata (feature-type, area, status, last-modified)
- Surface relationships (which specs reference which ADRs)

## When to set up an MCP server for this framework

**Yes:**
- You have ≥30 specs and section-level queries are getting tedious
- Multiple teams / multiple AI tools query the same spec corpus
- You want consistent access across Claude Code, Cursor, and Antigravity without each tool implementing its own parsing
- You need authenticated access (e.g., specs that include sensitive client info)

**No / not yet:**
- <10 specs and grepping works fine
- Single team, single AI tool — file reads are simpler
- You're not willing to maintain a small TypeScript/Python service

## What to expose

For most projects adopting this framework:

| Resource family | URI pattern (example) | Use |
|---|---|---|
| Specs | `mcp://specs/<folder>` | Full `spec.md` content (or a legacy single-file spec) |
| Spec sections | `mcp://specs/<folder>/section/<heading>` | E.g. `mcp://specs/007-newsletter-signup/section/Security` |
| Spec metadata | `mcp://specs/<folder>/meta` | Frontmatter only — feature-type, status, owners, approvals |
| Plan and tasks | `mcp://specs/<folder>/plan`, `…/tasks` | The change surface, test strategy, and gate results |
| Spec list | `mcp://specs?filter=<query>` | Filtered list — e.g. `?feature-type=ui&status=approved` |
| ADRs | `mcp://adrs/<number>` | Full ADR content |
| Admin docs | `mcp://docs/admin/<name>` | Pre-implementable user-facing docs |
| Runbooks | `mcp://docs/runbooks/<name>` | Operational docs |

Don't expose code as MCP resources — that's what file system access is for.

## Reference implementation (TypeScript)

This is a minimal starter — adopters extend it for their needs. Uses `@modelcontextprotocol/sdk`.

```typescript
// tools/spec-mcp-server/server.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { readdir, readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, basename } from 'node:path';
import matter from 'gray-matter';

const SPECS_DIR = join(process.cwd(), 'specs');

// Spec folders (specs/NNN-<slug>/spec.md, plan.md, tasks.md) and legacy single-file specs (specs/<name>.md).
async function listSpecs() {
  const entries = await readdir(SPECS_DIR, { withFileTypes: true });
  return entries
    .filter(entry => !entry.name.startsWith('_') && entry.name !== 'README.md')
    .flatMap(entry => {
      if (entry.isDirectory() && existsSync(join(SPECS_DIR, entry.name, 'spec.md'))) {
        return [{ name: entry.name, folder: join(SPECS_DIR, entry.name) }];
      }
      if (entry.isFile() && entry.name.endsWith('.md')) {
        return [{ name: basename(entry.name, '.md'), folder: null }];
      }
      return [];
    });
}

function specFile(name, part = 'spec') {
  const folder = join(SPECS_DIR, name);
  return existsSync(folder) ? join(folder, `${part}.md`) : join(SPECS_DIR, `${name}.md`);
}

// The text from a "## <heading>" line up to the next "## " heading.
function extractSection(content, heading) {
  const lines = content.split('\n');
  const start = lines.findIndex(line => line.toLowerCase().startsWith(`## ${heading.toLowerCase()}`));
  if (start === -1) return null;
  const end = lines.findIndex((line, index) => index > start && line.startsWith('## '));
  return lines.slice(start, end === -1 ? undefined : end).join('\n');
}

const server = new Server(
  { name: 'spec-mcp-server', version: '0.2.0' },
  { capabilities: { resources: {} } },
);

server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const specs = await listSpecs();
  return {
    resources: specs.flatMap(({ name, folder }) => [
      { uri: `mcp://specs/${name}`, name, mimeType: 'text/markdown' },
      { uri: `mcp://specs/${name}/meta`, name: `${name} (frontmatter)`, mimeType: 'application/json' },
      ...(folder
        ? [
            { uri: `mcp://specs/${name}/plan`, name: `${name} (plan)`, mimeType: 'text/markdown' },
            { uri: `mcp://specs/${name}/tasks`, name: `${name} (tasks)`, mimeType: 'text/markdown' },
          ]
        : []),
    ]),
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;
  // In mcp://specs/<folder>/<part>, "specs" parses as the URL's host; the path starts at the folder.
  const [, name, part, ...rest] = new URL(uri).pathname.split('/');
  const respond = (mimeType, text) => ({ contents: [{ uri, mimeType, text }] });

  if (part === 'plan' || part === 'tasks') {
    return respond('text/markdown', await readFile(specFile(name, part), 'utf-8'));
  }

  const { data: frontmatter, content } = matter(await readFile(specFile(name), 'utf-8'));
  if (part === 'meta') return respond('application/json', JSON.stringify(frontmatter, null, 2));
  if (part === 'section') {
    const heading = decodeURIComponent(rest.join('/'));
    return respond('text/markdown', extractSection(content, heading) ?? `Section "${heading}" not found in ${name}`);
  }
  return respond('text/markdown', content);
});

await server.connect(new StdioServerTransport());
```

This is ~90 lines and supports listing spec folders (and legacy single-file specs), reading a spec, its plan and tasks, its frontmatter as JSON, and individual sections. Extend with: ADRs, runbooks, admin docs, search/filter, authenticated access, write capability if your team wants AI-driven spec edits via MCP (most teams don't — keep MCP read-only).

## Wiring it into AI tools

### Claude Code

Add to `.mcp.json` at the repository root — project scope, so the team shares it and it's on in this
project only:

```json
{
  "mcpServers": {
    "specs": {
      "command": "node",
      "args": ["./tools/spec-mcp-server/dist/server.js"]
    }
  }
}
```

In Claude Code, the resources appear in the resource picker and can be referenced via `mcp://specs/<name>` URIs. Tool definitions are deferred — only the resource names consume context until you read one.

### Cursor

Cursor supports MCP servers via the Settings → MCP Servers UI. Add the same command/args. Cursor's discovery mechanism is similar — resources surface in the AI's context-picker.

### Antigravity / Gemini

Check `GEMINI.md` for current MCP support. As of writing, Antigravity supports MCP servers via its `.agent/` configuration. Same command/args pattern.

## Authentication & secrets

- **Local-only servers** (stdio transport, runs as you): no auth needed; the MCP server has whatever filesystem access you have.
- **Network-exposed servers** (HTTP transport): use the MCP spec's authentication mechanisms (OAuth, API keys). Don't expose specs over the network without auth — they often contain client / business-sensitive details.
- **Read-only by default.** Don't grant the MCP server write access to your specs directory unless you have a specific reason. Spec edits should go through the normal `/adf:write-spec` workflow with human review.

## Cost implications

MCP resource definitions are **deferred by default** in Claude Code — only the resource names consume context until you actually read one. This means exposing a 200-spec corpus via MCP costs roughly the same as exposing a 5-spec corpus, until the AI actually reads one. Big efficiency win vs. dumping all specs into the always-loaded instructions.

See `COST-MODEL.md` for the broader cost discipline.

## What this framework's MCP integration is NOT

- Not a hard dependency. The framework works without MCP.
- Not a replacement for file system access. Code, tests, and most docs are still read directly.
- Not a runtime API for the AI to modify specs. Keep MCP read-only; spec changes go through `/adf:write-spec` with human approval.
- Not a code module that ships with the skeleton. The reference snippet above is illustrative — adopters implement and extend.

## See also

- [modelcontextprotocol.io](https://modelcontextprotocol.io) — the spec
- [Anthropic MCP guidance](https://platform.claude.com/docs/en/agents-and-tools/mcp) — Claude Code-specific docs
- [`SPEC-MODEL.md`](SPEC-MODEL.md) — the spec structure that determines what's worth exposing
- [`COST-MODEL.md`](COST-MODEL.md) — why MCP's deferred-by-default loading helps cost
- [`MEMORY-STRATEGY.md`](MEMORY-STRATEGY.md) — how MCP resources fit alongside other persistence layers
