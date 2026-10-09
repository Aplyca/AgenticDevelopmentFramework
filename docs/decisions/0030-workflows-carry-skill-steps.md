# 0030: A workflow carries the skill steps its agents follow

- **Status:** accepted
- **Date:** 2026-10-09
- **Amends:** [0029](0029-workflows-carry-agent-checklists.md) — what a workflow carries, and the paths
  the static check covers

## Context

The `deep-drift-sweep` workflow told each auditor to follow "the method in
`.claude/skills/spec-drift/SKILL.md`". A committed project has that file, because `build-committed.py`
writes it. A packaged project, the default install (0018), doesn't: its skill is the plugin's
`skills/spec-drift/SKILL.md`, which a workflow script can't name (0019, finding 2). So in a packaged
project, the auditors worked from the paragraph in the prompt. It names the five categories but doesn't
define them. It also leaves out parts of the skill's walk through the spec: whether each acceptance
criterion's test still asserts what the criterion says, and whether anything the spec put out of scope
was built anyway.

0029 fixed the same problem for `deep-review`'s agent checklists. Its static check looked only at
`.claude/agents/` paths, so it missed this one.

Three ways to give the auditors the method were weighed:

1. **Carry the skill's text** in the plugin's workflow, as 0029 does for the checklists. The whole
   `SKILL.md` is about 10 KB, and every auditor, one per spec, would get it.
2. **Have each auditor load the skill**, `/adf:spec-drift`, which the committed form names
   `/spec-drift`. 0019 found that a workflow's agent can load a plugin skill. Checked:
   - **The skill is model-invocable.** Its frontmatter has no `disable-model-invocation`, and neither
     does any other skill of `adf`'s, so the Skill tool can load it. The round trip already converts
     the name between the two forms.
   - **In a packaged project, its Step 0 decides.** The plugin's copy opens: unless the project's
     instructions say "This project uses the packaged install", open
     `.claude/skills/spec-drift/SKILL.md` instead, and if it doesn't exist, "say so and stop". The
     note is in the project's `.claude/rules/claude-code.md`. Nothing has tested whether a workflow's
     agent gets the project's rules. If it doesn't, the auditor stops.
   - **In a committed project,** `/spec-drift` is the project's copy, which has no Step 0, and runs
     as written.
3. **Something simpler:** drop the path, and let the prompt's paragraph and the schema's category
   names stand.

## Decision

- **The plugin's workflow carries the skill's `## Steps` section.** The line
  `const SPEC_DRIFT_STEPS = "…"` holds it, and each auditor's prompt ends with it. The constant's name
  gives the skill's name.
- **The committed workflow points at the project's copy:**
  `const SPEC_DRIFT_STEPS = 'Follow the steps in .claude/skills/spec-drift/SKILL.md.'` A team that
  edits its committed skill still gets the edit in its sweeps.
- **Only the steps are carried,** about 4.8 KB, half the file. The other sections are for a person
  running one audit: when to run it, its modes (with no argument, it asks which spec to audit), and the
  rationalizations and red flags around it. The workflow picks the specs and verifies the findings
  itself.
- **The mechanism is 0029's, applied to a skill.** `scripts/forms.py` converts a `const <SKILL>_STEPS`
  line both ways, as it does `const <AGENT>_CHECKLIST`, and `scripts/build-plugins.sh` keeps the text
  equal to the skill's. The skill must be `adf`'s own, not a module's, so that every committed install
  has the file the line points at. It must have exactly one `## Steps` section.
- **The static check covers `.claude/skills/` paths too.** It fails when a plugin workflow names a
  `.claude/agents/` or `.claude/skills/` path that a packaged project lacks. A glob over the project's
  own skills, like the one in `deep-context-audit`'s inventory, names no file and passes.
- **The spec model names the playbooks by skill.** Its "Related" list named
  `.claude/skills/write-spec/`, `write-plan/`, and `implement/`, which a packaged project lacks.
  `deep-spec-analysis` carries that text, so the extended check flagged it. The list now names
  `/adf:write-spec`, `/adf:write-plan`, and `/adf:implement`, as the rest of the doc does. A
  committed project's copy reads `/write-spec`.

## Consequences

- **Positive:**
  - A packaged project's drift sweep follows the same method as a committed one's.
  - The method is still written once, in the skill.
- **Negative / cost:**
  - **Larger auditor prompts in a packaged project:** about 4.8 KB, roughly 1,200 tokens, per spec
    audited. The verifiers don't get it. A committed project's auditor reads the whole file instead,
    9.6 KB.
  - **A fourth generated part in a hand-written folder:** the steps line in `deep-drift-sweep.js`.
  - **A packaged project can't change the steps,** the same as for the skill itself.

## Alternatives considered

- **Load the skill by name (option 2).** Declined:
  - Its Step 0 stops the auditor unless the agent has the packaged-install note, and no one has shown
    that a workflow's agent does. A stopped auditor returns no findings, which the sweep counts as a
    spec without drift.
  - Loading is the model's choice. A prompt asks for the tool call but can't make it happen. An
    auditor that skips it works from the paragraph, as before.
  - The skill is written for a person: with no argument it asks which spec to audit, and it presents
    a text report.
  - It costs more: the whole file, about 10 KB with its Step 0, enters each auditor's context, and
    loading it takes one more turn.
- **Carry the whole skill (option 1 as stated).** Declined: it's twice the text, and the plugin's copy
  opens with the same Step 0, which would stop the auditor in the same way. 0029 carries only the
  checklist section for the same reason.
- **Drop the path and keep the paragraph (option 3).** Declined: the paragraph doesn't define the
  categories, and it leaves out parts of the walk. Adding them to the prompt or the schema by hand
  would make a copy that drifts from the skill, and a committed project's edits to its skill would stop
  reaching its sweeps. 0029 declined a hand-written checklist for the same reasons.
