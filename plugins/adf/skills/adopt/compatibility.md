# The compatibility pass: the project's own instructions against the framework's process

`/adf:adopt` runs this pass on an existing `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or rule, and
merges them by its table. `/adf:upgrade` runs it on every upgrade, against the new release's rules,
since a new framework rule can collide with an old project line. Instructions written before the
framework often carry a process of their own: "ask before each commit", "confirm every step", another
approval or pull-request flow. An agent follows the stricter or the more specific line, or stalls
between the two, and the framework's process never runs (decision 0099).

## Which lines

The project's own lines in `AGENTS.md` (and every nested one), `CLAUDE.md`, `GEMINI.md`,
`.cursor/rules/`, `.claude/rules/`, and `.agents/rules/`, meaning the lines the skeleton's copy of the
file doesn't have:

- **At adoption:** every line of each file the project had before the copy, compared with
  `<framework-root>/skeleton/`. A file the skeleton doesn't ship is the project's in full.
- **At an upgrade:** after the merge, each file compared with the new release's copy, the lines only
  the project's has. A line an earlier pass already settled stays out of the table: an override
  sentence the framework honors, or a line that points to its PDR. It comes back as a row only when
  the new release changes the rule it overrides.

Filled-in template text (a `[bracketed]` placeholder, a CUSTOMIZE section) is classified like any
other line. Most of it is project fact, but a team's ground rules can hold a process line too.

## Classify each line

| Class | What it is | What happens to it |
|---|---|---|
| **Project fact** | The stack, the commands, paths, conventions, boundaries, sensitive areas, the team's vocabulary | Moves into its skeleton section once: `AGENTS.md`'s, or the rule whose subject it is. A fact that section already states is dropped as a duplicate |
| **Process the framework owns** | When to ask or stop, approvals, the commit, branch, and pull-request flow, the testing process, review, model and session handling | Dropped. The table shows the line and the framework rule that replaces it |
| **Deliberate override** | A process line the team means to keep, with a reason | Kept where the framework honors it; otherwise recorded as a PDR with its reason |
| **Can't tell** | A line that could be either process or an override | Asked once, in the table's round |

**Where the framework honors an override.** The line becomes that place's sentence or setting, and
nothing else carries it:

- **A person marks pull requests ready:** the CUSTOMIZE note after `AGENTS.md` § Delivery rules'
  pull-request bullet. Say so in that bullet, and `/adf:open-pr` leaves the draft.
- **Integration and release branches:** the Branches bullet's CUSTOMIZE note, with the full model in
  `CONTRIBUTING.md`.
- **Stakeholder updates approved before they post:** *Updates post* in `docs/TRACKER-INTEGRATION.md`.
- **A prompt before a command:** a `permissions.ask` rule in `.claude/settings.json`. A rule that must
  hold is configuration, not prose (decision 0006).
- **More care in part of the code:** that's a fact. It goes in `AGENTS.md` § Sensitive areas and
  `CAREFUL_GLOBS`, and the careful lane does the rest.

Any other override (a stop the process doesn't make, another approval, a different flow) is a PDR in
`docs/process/` from the template: the reason, what it costs, the alternatives. Its line in the
instructions shrinks to one sentence in its section, pointing to the PDR. A process line nobody can
give a reason for is process the framework owns.

**Hard cases:**

- "Ask before each commit", "confirm every step", "wait for my OK before each task": process. The
  approval gate authorizes the run to a pull request ready for review, stopping only for a decision
  (`AGENTS.md` § How work flows, decision 0097), and commits, the branch's push, and its draft are
  the standing go-ahead (§ Delivery rules).
- "Never push to main": the framework already says it. Drop it as a duplicate.
- "Run `pnpm test` before committing": the command is a fact for § Quick reference; when it runs is
  process the lanes own.
- "Use the largest model for everything": model handling is process, unless the team records why.
- A line that names a person or a team to ask ("check with the data team before touching exports"):
  can't tell. It may be a sensitive area (a fact) or a review rule (an override, with a PDR).

## Show the table, then write

Before writing anything, show one table, with the can't-tell rows carrying their question:

| File:line | Line | Class | Where it goes, or what replaces it |
|---|---|---|---|
| `CLAUDE.md:4` | Tests: `pnpm test` | Project fact | `AGENTS.md` § Quick reference |
| `CLAUDE.md:12` | Ask me before every commit. | Process | Dropped: commits are the standing go-ahead (§ Delivery rules) |
| `CLAUDE.md:15` | A person marks PRs ready for review. | Override | The CUSTOMIZE note in § Delivery rules |
| `.cursor/rules/team.mdc:8` | Confirm before editing more than one file. | Can't tell | A stop the team needs (a PDR), or a habit? |

The developer answers the questions and approves the table in one round: at adoption, beside the
facts table (Step 2), before anything is copied; at an upgrade, in the approval that covers the
conflict resolutions. The pass changes no line before that approval. A row the developer moves to
another class is applied as they say.

## Keep the always-loaded budget

`AGENTS.md` loads in every session, and the framework holds its own copy to 21,000 characters.
The pass never adds process to it:

- a dropped line leaves nothing behind;
- an override is the honored sentence, or one line pointing to its PDR;
- a fact goes in once, and the section that already states it wins.

A long fact that only some tasks need moves to a doc read on demand, behind a pointer that says when
to read it. Give `AGENTS.md`'s size in characters after the pass, and before it when the project
had one.

## Record it

The table goes in the pull request's body under `## Compatibility`, with each row's outcome, or
`- none found`. At adoption, PDR-0001 also names each override kept and links its PDR.
