@AGENTS.md

# [PROJECT NAME] — Antigravity / Gemini Instructions

<!-- This file extends AGENTS.md (imported above) with Antigravity and Gemini-specific notes. AGENTS.md holds the instructions every AI tool shares — read it first; it wins over anything here except the constitution. If your Gemini tooling doesn't expand @-imports, configure it to load AGENTS.md as a context file. -->

## How work flows here

`AGENTS.md` is the operating contract. In short, every task starts with **triage** (deliverable,
kind, lane, environment). The lane follows risk, not size: **fast** (a precise request, a few files,
no risk area — edit, prove it with a test, commit), **careful** (the same in a risk area, plus its
checklist and the developer's yes), or **full** — the spec-driven flow:

1. **Spec folder** — `specs/NNN-<slug>/spec.md` from `specs/_templates/`: the multi-perspective spec (`docs/SPEC-MODEL.md`).
2. **Plan and tasks** — `plan.md` (constitution check, change surface, test strategy, documentation plan, assumptions) and `tasks.md` (one task per commit, each naming its test).
3. **Approval gate** — stop and show the developer the scope, the change surface, and the assumptions; no implementation code until `status: approved`. Commit the folder (`spec:`).
4. **Docs first** — pre-implementable docs (`docs:`), when the plan lists any.
5. **One task at a time** — write the test, watch it fail, write the code, watch it pass, commit (`feat:` / `fix:`), tick the task.
6. **Reconcile docs, run the full gate, record the gate results** in `tasks.md`.
7. **Deliver only when asked** — push and open a **draft** pull request; a human QCs it and marks it ready.

Change requests amend the existing spec folder (a light `CR N` for a precise adjustment, a full one
when there's something to decide); answers need no lane; changes to how the team works become PDRs in `docs/process/`. The skills in
`.claude/skills/` (shared through `.agents/skills`) are the step-by-step playbooks — read the one
for the step you're on.

## Antigravity agent structure

If this project uses Antigravity's `.agent/` directory:

| Directory | Purpose |
|---|---|
| `.agent/rules/` | Governance rules for agent behavior |
| `.agent/skills/` | Reusable skill definitions |
| `.agent/workflows/` | Multi-step operation definitions |

<!-- CUSTOMIZE: remove this section if the project doesn't use Antigravity's .agent/ structure. -->

## Documentation references

| Document | Read when… |
|---|---|
| `docs/CONSTITUTION.md` | Always — the gate every spec, plan, and review checks against |
| `specs/README.md` | Starting any change |
| `docs/SPEC-MODEL.md` | Writing or reviewing a spec |
| `docs/ARCHITECTURE.md` | Designing features, reviewing data flow |
| `docs/security/SECURITY.md` | Touching auth, data handling, endpoints |
| `docs/infrastructure/OVERVIEW.md` | Changing deployment, CI/CD, environments |
| `docs/GLOSSARY.md` | Writing specs or user-facing text |
| `docs/architecture/decisions/` · `docs/process/` | Making or revisiting a technical (ADR) or process (PDR) decision |
