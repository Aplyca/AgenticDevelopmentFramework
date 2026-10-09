# 0029: A workflow carries the agent checklists its lenses follow

- **Status:** accepted
- **Date:** 2026-10-09
- **Amends:** [0028](0028-plugins-are-the-source.md) — what `scripts/build-plugins.sh` generates

## Context

Two of the `deep-review` workflow's lenses named an agent's checklist by its committed path. The
security lens named `.claude/agents/security-reviewer/agent.md`, and the UX lens
`.claude/agents/ux-reviewer/agent.md`. A committed project has these files, because
`build-committed.py` writes them. A packaged project, the default install (0018), has none: its
agents are the plugin's `agents/<name>.md`. The workflow can't name those either, because Claude Code
doesn't fill in `${CLAUDE_PLUGIN_ROOT}` in a workflow script (0019, finding 2). So in a packaged
project, these two lenses sent their reviewers to files that weren't there. The reviewers worked
from the one-line summary in the prompt.

`deep-spec-analysis` had the same problem with the spec model. 0019 solved it by carrying the doc's
text in the plugin's copy of the workflow.

## Decision

- **The plugin's workflow carries each checklist it follows.** The line
  `const SECURITY_REVIEWER_CHECKLIST = "…"` holds the `## … checklist` section of
  `agents/security-reviewer.md`, and the security lens's prompt ends with it. The constant's name
  gives the agent's name.
- **The committed workflow points at the project's copy:**
  `const SECURITY_REVIEWER_CHECKLIST = 'Follow the checklist in .claude/agents/security-reviewer/agent.md.'`
  A team that edits its committed agent's checklist still gets the edit in its deep reviews.
- **Only the checklist section is carried.** Each agent's other sections don't apply to a lens:
  - "Before you start" repeats what every lens already gets. The workflow gives it the spec folder
    and the plan, and `AGENTS.md`'s "when to read what" table sends it to `docs/security/SECURITY.md`
    and `docs/GLOSSARY.md`.
  - The output format conflicts with the workflow's schema. The security reviewer's four severities
    and each reviewer's closing verdict don't fit a schema that takes critical, warning, or nit.
- **`scripts/build-plugins.sh` keeps the text equal to the agent's,** as it does for the spec model.
  A new line can be written in its committed form, and the build fills in the text. The round trip
  (`build-committed.py --check`) and the drift check fail on a stale line.
- **A static check** fails when a plugin workflow names a `.claude/agents/` path that a packaged
  project lacks. A glob over the project's own agents, like `deep-context-audit`'s inventory, names
  no file and passes.

## Consequences

- **Positive:**
  - A packaged project's deep review follows the same checklists as a committed one's.
  - Each checklist is still written once, in its agent.
- **Negative / cost:**
  - **Larger lens prompts in a packaged project:** about 2 KB for the security lens and 2.4 KB for
    the UX lens, roughly 500 and 600 tokens. Each goes to its own lens only; the verifiers don't get
    it. For comparison, `deep-spec-analysis` gives every lens 10 KB.
  - **A third generated part in a hand-written folder:** the checklist lines in `deep-review.js`,
    after the spec-model line and `bin/`.
  - **A packaged project can't change a checklist,** the same as for the agent itself. Changing it
    takes the committed install.

## Alternatives considered

- **Run the lens as the agent** (`agent(prompt, { agentType: 'adf:security-reviewer' })`).
  Declined. The reviewer agents are read-only and have no Bash tool, so the lens couldn't read the
  diff (`docs/AGENTS-REFERENCE.md` § Agents inside workflows). The agent's model and output format
  would also override the lens's. And the agent's name differs between the two installs, in a form
  the round trip doesn't convert.
- **Write the checklist into the prompt by hand,** and drop the path. Declined: the copy would drift
  from the agent, and a committed project's edits to its agent would stop reaching its deep reviews.
- **Name the installed copy,** `~/.claude/plugins/cache/<marketplace>/adf/<version>/agents/…`.
  Declined: the version changes with each release, the cache can move
  (`CLAUDE_CODE_PLUGIN_CACHE_DIR`, `--plugin-dir`), and a headless run denies the read (0019,
  findings 3 and 4).
- **Carry the agent's whole body.** Declined: its output format conflicts with the schema, and its
  Step 0 names the `.claude/agents/` path that a packaged project lacks.
