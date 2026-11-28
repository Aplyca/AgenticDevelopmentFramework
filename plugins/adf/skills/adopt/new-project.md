# Adopting into a new project

`/adf:adopt` reads this when the target has no git repository, no commits, or nothing to inspect
yet (no manifest, no source code). Adopting before the first line of code puts the process and the
guardrails in place first. Every other step applies, with these changes:

- **No repository:** offer `git init -b <default branch>` — ask for the name; suggest `main`.
- **No commits:** there is no default branch to branch from. With the developer's yes, make exactly
  one commit on it, holding everything already there — check `git status` first, so no secret goes
  in — with `git add -A && git commit -m "chore: initial commit"` (add `--allow-empty` when the folder
  is empty). Then branch as usual; nothing else lands on the default branch.
- **Step 2 asks instead of reads.** There are no facts to evidence yet. Ask for the planned ones in one
  round, with your recommendations: language and framework, package manager, test runner, hosting,
  branching model (Model A is the usual start), tracker, ways of working, sensitive areas. Mark each
  answer in `AGENTS.md` as planned — `<!-- planned: not in the repository yet -->` — so no one mistakes
  it for a verified fact. A command nobody has run yet stays a `TODO(team)`.
- **The stack is a decision.** Record it as ADR-0001 in `docs/architecture/decisions/` from the
  template, status `proposed`, with the alternatives the developer considered; the adoption's review
  accepts it.
- **Globs point at planned paths or stay empty** — `CAREFUL_GLOBS`, `APPEND_ONLY_GLOBS`,
  `GENERATED_GLOBS`, the rules' `paths:` — and no nested `AGENTS.md` yet.
- **Step 6:** commands that can't run yet are a GAP — "no code yet" — not a failure.
- **Step 7 without a remote:** commit on the adoption branch, then put the full PR body in your reply —
  not an offer to draft it — with the steps that follow: add the remote, push the branch, and open
  the draft pull request with that body.
- **After the adoption,** the scaffold — the framework's init, the first test — is the first task
  through the lanes; usually full, since it sets the structure others follow. Once that code lands,
  run `/init-project` to replace the planned entries with verified facts, and `/context-audit` to find
  what's stale.
