# Reference — how the subsystems work

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: on-demand, code-level reference for AI agents and developers -->

Deep, code-level explanations of the subsystems that are hard to understand from rules alone.
**Open only the page you need** for the task at hand — this layer exists so that agents don't load
(or re-derive) the whole codebase to understand one mechanism.

| If you need… | Read |
|---|---|
| The non-negotiable rules | [`../CONSTITUTION.md`](../CONSTITUTION.md) |
| General rules, stack, commands | `AGENTS.md` and the nested `AGENTS.md` files |
| The high-level system map | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) |
| **How a subsystem actually works, at the code level** | the pages below |

## Pages

<!-- CUSTOMIZE: one page per complex subsystem. Good candidates: authorization (every layer where a
     check lives), data access and CRUD conventions, routing, the data model, external integrations,
     background jobs. Each page: what it is for, the real control flow with `file:line` links, the
     invariants that must survive edits, and the traps. -->

- [`authorization.md` — where each access check lives and how they combine. Read before touching anything access-related.]
- [`data-access.md` — how reads and writes flow through the service layer; conventions such as soft delete]

## How to use these pages

1. Start from `AGENTS.md` for the rules; nested `AGENTS.md` files win for the folders they cover.
2. When a task needs to understand *how* a subsystem works, open the matching page here.
3. Treat each page as a **map, not the territory**: verify any detail against the linked source
   before relying on it. The code is the source of truth.

## Maintenance

These pages don't update themselves. When a change alters a subsystem, update its page **in the same
pull request** — reference docs and code diverge the moment one merges without the other.
`/context-audit` flags pages whose linked code has moved.
