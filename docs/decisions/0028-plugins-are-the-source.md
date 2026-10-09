# 0028: The plugins are the machinery's source, and a committed install is written from them

- **Status:** accepted
- **Date:** 2026-10-09
- **Amends:** [0016](0016-packaged-install.md) — where the machinery's source lives ("generated from
  `skeleton/`", "the skeleton stays the single source"); [0019](0019-reference-docs-in-the-plugin.md) —
  the reference docs' source; [0023](0023-plugins-by-concern.md) — where a module's skills live, and
  what the build generates

## Context

**Two copies of everything.** Since 0016, `skeleton/` held the framework's machinery and
`scripts/build-plugins.sh` generated the plugins' copies:

- 20 skills, 8 agents, 4 workflows, 13 hook files, and the 4 reference docs;
- the two module skills, `/dispatch` and `/dev-env`.

That's 51 files, about 5,000 lines, in the repository twice.

**Edited in one form, run in the other.** The packaged install is the default (0018), and a packaged
project commits none of these files. It runs the plugins' generated copies, which nobody edited: the
rule was never to edit `plugins/`. So maintainers edited one form, and the default install ran the
other.

**The question** was why the machinery doesn't live in the plugins, and get copied into a project
that needs it committed.

**A test** (2026-10-09). A throwaway script rebuilt the committed form from the plugins' copies,
undoing each change the build makes:

- the Step 0 and the docs note;
- `${CLAUDE_PLUGIN_ROOT}/docs/` paths;
- the `adf:` and `adf-dev:` prefixes, and the commands' names (0027);
- the spec model inlined in a workflow;
- the hooks' paths;
- the flat agent files.

50 of the 51 files came back byte-identical, file modes included. The one that didn't was
`/dispatch`. It named the worktree script two ways, by its path and by its file name, and both had
become `adf-worktree-new`.

**What can't move:**

- **The project's own layer stays in `skeleton/`:** `AGENTS.md`, the rules (a plugin can't carry
  rules, 0016), the settings, `config.sh`, the docs templates, and `specs/`. A module's committed
  files stay in the module.
- **Two parts of a plugin can't be written by hand:**
  - the commands, which inline a module script's helper (0027);
  - the spec model inside `deep-spec-analysis`, since a workflow can't reach the plugin's folder (0019).

## Decision

1. **The plugins are the source of the machinery.**
   - `plugins/adf/` holds the skills, agents, workflows, hook scripts, reference docs, and `/dispatch`.
   - `plugins/adf-dev/` holds `/dev-env`.
   - They are written in the form a packaged project loads: `/adf:triage`, `@adf:code-reviewer`,
     `${CLAUDE_PLUGIN_ROOT}/docs/SPEC-MODEL.md` with the docs note, `adf-worktree-new`, and a Step 0
     in each skill and agent.
2. **`skeleton/` is the project's layer only,** what every adopting project commits and edits as its
   own. A module's `files/` holds only what a project commits. Its `module.json` names the plugin and
   lists the skills that plugin carries.
3. **`scripts/build-committed.py` writes a committed install** into a project, with the skills of the
   modules it's given. `/adopt`, `/upgrade`, and the manual setup in `docs/SETUP.md` run it. It never
   overwrites a file; it lists the ones it kept.
4. **The Step 0 marks what a committed install carries.** Every skill and agent with a Step 0 has a
   committed copy, which is what its Step 0 hands over to. The installer's skills (`/adf:adopt`,
   `/adf:upgrade`, `/adf:cost-report`) and `/adf-connect:connect` run only from their plugin, and
   have none. A static check pins that set, so a Step 0 dropped by mistake can't quietly take a
   skill out of every committed project.
5. **`scripts/forms.py` holds both directions,** and the static checks run the round trip: every
   carried file must come back unchanged from its committed form. That enforces the plugin form's
   conventions at the source. A bare `/triage`, a local `docs/` path, a Step 0 for the wrong name, a
   hook that computes its folder, and a stale spec model each fail, and
   `build-committed.py --check` shows what the file should read.
6. **`scripts/build-plugins.sh` generates only what can't be written by hand:**
   - each plugin's `bin/`, from its modules' scripts;
   - the spec-model line in `adf`'s workflows;
   - every plugin's version.

   `.generated` lists `bin`. The build refuses to start if a listing names anything else, so it never
   deletes a source.
7. **Upgrading a committed project** writes the machinery at both releases, into empty folders, and
   diffs them. A release before v2.0.0 keeps it in `skeleton/` instead.
8. **The reference docs' links follow the release.** `link-reference-docs.py` links
   `plugins/adf/docs/` at a pin from v2.0.0 on, and `skeleton/docs/` at an older one, and moves
   either.
9. **Committed projects get the same files.** The one change is `/dispatch`'s checklist line, which
   now names the script by its path.
10. **It ships with v2.0.0.** No project acts on it.

## Consequences

- **Positive:**
  - One copy: 51 files and about 5,000 lines leave the repository.
  - Maintainers edit the files the default install runs.
  - `skeleton/` is exactly what a project owns. 0016's test is now a folder.
  - A packaged adoption copies the skeleton whole: there's nothing in it to leave out.
  - The two forms can't drift apart: the round trip and the tests of the built committed copy (the
    hooks run, the skills are checked) hold them together.
- **Negative / cost:**
  - **Writing in the plugin form:** the prefixes, the docs note, and a Step 0 in every skill and
    agent. More to type; the round trip holds it exact.
  - **A committed install is a build step.** `/adopt` and `/upgrade` run a script, the manual setup
    runs `python3`, and an upgrade diffs two built folders, not `skeleton/` alone.
  - **Two generated parts sit inside hand-written folders:** `bin/`, and one line of
    `deep-spec-analysis.js`.
  - **People browsing the repository** read the machinery in the plugin form (`/adf:triage`), not the
    form a committed project keeps.
  - **The reverse transform is new code.** `forms.py` is checked by the round trip, the hook tests run
    the built hooks, and the static checks read the built skills, agents, and workflows.

## Alternatives considered

- **Keep the skeleton as the source** (until now). Simple for a committed install, which copies
  `skeleton/` whole. But two copies of every file, and the default install runs the one nobody edits.
- **Flip the build, and commit both forms** (the plugins as the source, `skeleton/` generated). The
  same files would be in the repository twice, as before.
- **Write the committed form without a round trip.** The reverse transform alone would let a plugin
  file drift into a form that doesn't come back, and nothing would say so.
- **Packaged only** (0018's alternative). Teams on other AI tools and Claude Code's cloud sessions
  need the committed files.
- **Put the project's layer in the plugin too,** so `/adopt` copies from `${CLAUDE_PLUGIN_ROOT}`. The
  layer is committed in every project anyway. `/adopt` installs the newest release, which the installed
  plugin may not be, and `/upgrade` needs both releases.
