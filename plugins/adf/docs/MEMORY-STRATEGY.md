# Memory strategy

How to decide where a piece of project knowledge belongs — `AGENTS.md`, tool-specific layers, engineering rules, persistent memory, spec folders, decision records, reference pages, or the tracker. Each layer has a different cadence, scope, and load behavior; using the wrong one wastes tokens, bloats context, or causes facts to go stale.

## The persistence layers

This framework has **nine** places where project knowledge can live. Each has a different role.

| Layer | Where | Loaded when | Change cadence | Owned by |
|---|---|---|---|---|
| **Non-negotiables** | `docs/CONSTITUTION.md` | Read before every spec, plan, and review; overrides everything below | Rare (amendments) | Tech lead + approvers |
| **Project identity & rules** | `AGENTS.md` (+ nested `AGENTS.md` per module) | Every session, every AI tool (Claude Code natively, when no `CLAUDE.md` or `CLAUDE.local.md` is present); nested files when working in their folder | Slow (months) | Tech lead |
| **Tool-specific config** | `.claude/rules/claude-code.md`, `GEMINI.md`, `.claude/settings.json`, hooks | Every session, by the matching tool | Slow (months) | Tech lead |
| **Engineering rules** | `.claude/rules/*.md` | When Claude reads a file matching the rule's `paths:` | Slow (months) | Tech lead |
| **Per-feature knowledge** | `specs/NNN-<slug>/` (spec, plan, tasks), plus the user-facing docs they produce | On demand when working on that feature | Per feature and per change request | The team |
| **Decisions** | `docs/architecture/decisions/` (ADRs) and `docs/process/` (PDRs) | On demand when revisiting a decision | Per decision (rare) | Architect / tech lead / team |
| **How subsystems work** | `docs/reference/` | On demand — one page per subsystem | When the subsystem changes (same PR) | The team |
| **Persistent memory** | Tool-specific memory (Claude Code: `~/.claude/projects/<slug>/memory/`) | Just-in-time, by the AI | Fast (per learning) | The AI + the user |
| **Requirements & conversation** | The tracker (linked, never copied) | When a task is read | Continuous | Requester + team |

Plus operational layers (out of scope for this doc):
- Runbooks (`docs/runbooks/`) — operational knowledge for incident response
- API contracts (`openapi/`, type definitions in code)

## The decision tree

```
Is this knowledge about... ?
├── ...a principle no change may violate?
│   └── docs/CONSTITUTION.md (amended via a PDR, never casually)
│
├── ...the project's identity, stack, or workflow conventions?
│   └── AGENTS.md (universal; nested AGENTS.md for one module) or .claude/rules/claude-code.md / GEMINI.md (tool-specific)
│
├── ...how to write/review code in a specific path?
│   └── .claude/rules/<area>.md (path-scoped)
│
├── ...a specific feature's requirements, behavior, design, or delivery evidence?
│   └── specs/NNN-<slug>/ (spec.md, plan.md, tasks.md — change requests amend the same folder)
│
├── ...a significant technical decision (framework choice, integration pattern)?
│   └── docs/architecture/decisions/NNNN-<title>.md (ADR)
│
├── ...a decision about how the team works (gates, workflow, hand-offs)?
│   └── docs/process/NNNN-<title>.md (PDR)
│
├── ...how a subsystem works at the code level?
│   └── docs/reference/<subsystem>.md
│
├── ...a learned fact, gotcha, or pattern that recurs across features?
│   └── Memory (persistent, just-in-time loaded)
│
└── ...something the AI should remember about how YOU prefer to work?
    └── Memory (user-type entry)
```

## When to use memory specifically

Memory is the right choice when **all of these** are true:

1. The fact is **specific enough** that it's not a project-wide convention (those go in AGENTS.md / rules).
2. The fact is **recurring** — likely to come up across many sessions, not just once.
3. The fact would otherwise be **re-derived from scratch** each session (wasted tokens) or **forgotten** between sessions.
4. The fact is **stable enough** to outlive a single feature (specs handle per-feature facts).

### Good memory entries

- "The Contentful environment for staging is named `staging-2024`, not `staging`. The default in the SDK is wrong." (gotcha that recurs across features)
- "When working with the Mailchimp v3 API, batch operations cap at 500 entries per request — chunk larger inputs." (domain-specific quirk)
- "User prefers `pnpm` over `npm`; defaults to TypeScript strict mode; uses Vitest, not Jest." (user-type, persists preferences)
- "The marketing team approves copy changes; the editorial team approves article content. Different Slack channels." (project-type, useful when drafting comms)
- "Past incident: Vercel KV had cross-region inconsistency that broke our rate-limiter. Mitigation: include the region in the key." (project-type, captures hard-won knowledge)
- "Senior dev pushed back on adding Redux — said 'we already have React Query + URL state, don't need a state library'." (feedback-type, preserves a validated judgment)

### Bad memory entries

- "The `validateEmail` function is at `lib/newsletter/validate-email.ts`." (read the code; this rots immediately)
- "Specs go in the `specs/` directory." (project structure — belongs in AGENTS.md)
- "We decided PRs open as drafts." (a process decision — belongs in a PDR, reflected in AGENTS.md)
- "Tests go before implementation." (workflow rule — belongs in AGENTS.md / rules)
- "The newsletter signup spec has 5 ACs." (per-feature — belongs in the spec, will go stale as the spec evolves)
- "Today is 2026-04-28." (factual but ephemeral — re-derive each session)

## Memory entry types

This framework's memory system has four types. Choose the one that fits:

| Type | What it captures |
|---|---|
| **`user`** | Who the user is, role, preferences, knowledge gaps |
| **`feedback`** | Guidance the user has given about how to work — both corrections AND validated successes |
| **`project`** | Ongoing work, decisions, gotchas, ambient knowledge specific to this project |
| **`reference`** | Pointers to where information lives in external systems (Linear projects, Slack channels, Grafana dashboards) |

A memory file always has frontmatter:

```yaml
---
name: Short, specific name
description: One-line description (used to decide relevance later)
type: user | feedback | project | reference
---

The body of the memory.
```

For `feedback` and `project` types: lead with the rule/fact, then a `**Why:**` line and a `**How to apply:**` line. Knowing *why* lets future-you (or the AI) judge edge cases.

## Memory hygiene

Memory accumulates. Without hygiene, you end up with contradictory entries, stale references to renamed files, and a pile the AI ignores because it can't tell what's current.

### Practices

- **Update wrong memories rather than appending.** If a memory is now wrong (the rate limit changed, the API was deprecated), edit the existing memory file. Don't add a new one with contradicting information.
- **Remove memories that turned out to be wrong.** Better to forget than to mislead.
- **Quarterly review.** Walk through the memory directory; archive or delete entries that are no longer load-bearing.
- **Don't write memories about things the code shows.** Function locations, class names, file paths — these belong in `git grep`, not memory. Memories that quote code rot immediately.
- **Don't write memories for things you can derive in 10 seconds.** "The dev port is 3000" — if the AI can find that in `package.json`, don't memorize it.

### Verifying before recommending from memory

A memory that names a specific function, file, or flag is a claim that it existed *when the memory was written*. Before recommending action based on a memory:

- If the memory names a file path, verify the file still exists.
- If the memory names a function, grep for it.
- If the user is about to act on the recommendation (not just asking about history), verify first.

"The memory says X exists" is not the same as "X exists now."

## What goes where: examples

| Knowledge | Layer | Why |
|---|---|---|
| "This project uses Next.js 15 + Contentful + Vercel" | AGENTS.md | Project identity, stable, every session needs it |
| "All TypeScript files use strict mode; no `any`" | `.claude/rules/code-quality.md` | Engineering standard, path-scoped |
| "The newsletter signup form rate-limits to 10/IP/min" | `specs/007-newsletter-signup/spec.md` | Feature requirement, per spec folder |
| "We chose Mailchimp over SendGrid in Q4 2025 because of legacy list compatibility" | ADR | Significant decision, captures rationale for future readers |
| "Contentful's `staging-2024` env name is non-default; default in SDK is wrong" | Memory (project) | Recurring gotcha, not a per-feature concern, easy to forget |
| "User prefers terse PR descriptions; doesn't want emoji in commits" | Memory (user) | User-specific preference |
| "Use `pnpm` not `npm`" | Memory (user) OR AGENTS.md | If team-wide, AGENTS.md; if user-specific, memory |
| "Past incident: Vercel KV cross-region inconsistency; include region in key" | Memory (project) | Hard-won knowledge, recurs across rate-limit work |
| "Pipeline bugs are tracked in Linear project INGEST" | Memory (reference) | External-system pointer |

## For consultancy / multi-project teams

Teams that work on many projects (consultancies, agencies) have a unique consideration: **per-client knowledge** that doesn't belong in any specific client's repo but recurs across the consultancy's work.

Recommended split:

- **Per-client repo `AGENTS.md`** — that client's stack, conventions, critical rules. Goes in their repo.
- **Per-client memory entries** (project-type) — gotchas specific to that client's setup. Stored in your local memory, scoped to their repo's project slug.
- **Cross-client memory entries** (reference or project) — recurring patterns (e.g., "Contentful gotchas that affect every Contentful project we build"). Stored at user-level memory, available across all projects.

Example:
- `Our consultancy uses Next.js + Contentful + Vercel as the default stack` → cross-client (user-level memory)
- `Client X's Mailchimp instance has list ID 12345 (production) and 67890 (staging)` → per-client (project memory)
- `For Client Y, the editorial team prefers WhatsApp over Slack for content reviews` → per-client (project memory)
- `Contentful's staging environment naming convention varies per client; always confirm before assuming` → cross-client (user memory)

## Memory and prompt caching

Memory entries are loaded just-in-time when relevant — so they don't bloat every request. This is good for cache efficiency.

But: **AGENTS.md and the rules without `paths:` are loaded every session and form the cache prefix.** If you put recurring-but-volatile knowledge there instead of memory, every edit busts the cache (see [`COST-MODEL.md`](COST-MODEL.md)).

Rule of thumb: **if you'd edit a fact more than once a quarter, it doesn't belong in AGENTS.md / rules. It belongs in memory or a spec.**

## When the AI asks "should I save this to memory?"

The AI may proactively offer to save things. Heuristic for accepting:

- ✓ "Save: this team prefers X over Y for [reason]" — capture validated preference
- ✓ "Save: gotcha — when calling API Z, watch for [edge case]" — recurring gotcha
- ✓ "Save: Linear project INGEST tracks pipeline bugs" — external-system reference
- ✘ "Save: today we worked on the newsletter spec" — ephemeral, doesn't help future sessions
- ✘ "Save: the validateEmail function is at lib/newsletter/" — code-derivable, will rot
- ✘ "Save: this PR is about adding topic selection" — captured in commit history already

When in doubt: don't save. A small, sharp memory beats a bloated one the AI can't navigate.

## See also

- [`AGENTS.md`](../AGENTS.md) — project identity layer
- [`.claude/rules/claude-code.md`](../.claude/rules/claude-code.md) — Claude Code-specific tool config
- [`docs/SPEC-MODEL.md`](SPEC-MODEL.md) — per-feature knowledge layer
- [`docs/architecture/decisions/`](architecture/decisions/) — ADR layer
- [`docs/COST-MODEL.md`](COST-MODEL.md) — cache implications of where knowledge lives
- Tool-specific memory documentation:
  - Claude Code: [memory tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)
  - Cursor: project rules + custom rules
  - Antigravity: see `GEMINI.md`
