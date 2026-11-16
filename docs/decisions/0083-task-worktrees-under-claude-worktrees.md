# 0083: A task's worktree sits under `.claude/worktrees/` — no worktree beside the main checkout (parallel-agents module)

- **Status:** accepted; amended by [0085](0085-the-session-moves-with-enterworktree.md) (the move out of the app's worktree, its § Found later's open problem, is `EnterWorktree`)
- **Date:** 2026-11-15
- **Amends:** [0021](0021-sibling-worktree-and-chip.md) — where the scripts put a task's worktree;
  [0040](0040-workers-move-out-of-the-apps-worktree.md) — why a session leaves the desktop app's
  worktree; [0042](0042-each-session-moves-to-its-task-worktree.md) — where the session moves

## Context

**Where worktrees went.** Since 0021, `adf-worktree-new` put each task's worktree beside the main
checkout (`../feat-newsletter-signup`), or under `WORKTREE_PARENT`. Two reasons were recorded:

- a team wanted every task's worktree beside the main checkout (0021);
- in the desktop app's own worktree, nested in the main checkout, ESLint read the main checkout's
  configuration and failed (0040).

[Issue 153](https://github.com/aplyca/AgenticDevelopmentFramework/issues/153) asked whether the
location still earns its cost. Agents manage the local code, and developers review through the pull
request, so the first reason no longer holds.

**What the location costs:**

- **A parent folder of the project's own.** The main checkout needs one, or its worktrees sit among
  other repositories (`worktree.conf`'s advice).
- **A trust prompt per worktree.** The desktop app asks before it moves a session into a folder
  outside every folder the developer trusted. That stops only once the developer trusts the parent
  folder.
- **A dead end in a terminal.** `EnterWorktree` always asks for a path outside `.claude/worktrees/`.
  From inside Claude Code's own worktree it can't reach one, so `/adf:dispatch` gave the developer
  `cd <path> && claude` and stopped.

**A spike (2026-11-15).** Throwaway repositories, each with a main checkout on `main` with its
dependencies installed and a task branch that changes something. Each tool ran in a worktree of that
branch nested under `.claude/worktrees/` and in one beside the main checkout, before and after the
worktree's own `npm install`:

| Tool | Nested, no install | Nested, installed | Beside |
|---|---|---|---|
| ESLint 9, flat config; the task upgrades a plugin | The main checkout's ESLint and older plugin: "Could not find rule" | Correct | "command not found" until installed, then correct |
| ESLint 8, `.eslintrc` without `root: true` | Passes, with the main checkout's packages | "couldn't determine the plugin uniquely" — 0040's failure | Correct |
| ESLint 8, `.eslintrc` with `root: true` | Passes, with the main checkout's packages | Correct | Correct |
| TypeScript 5.9; the task drops a `@types` package but still uses its global | Passes — wrongly | Passes — wrongly: every parent folder's `node_modules/@types` is included | Fails, as it should (TS2304) |
| TypeScript 7.0, the same | Fails, as it should | Fails, as it should | Fails, as it should |

- **Three causes, each with a fix.** A nested worktree goes wrong only through a parent folder:
  - packages and commands it doesn't have itself — Node resolves packages, and `npm run` finds
    commands, in every parent folder;
  - TypeScript before 6.0 including every parent's `@types`;
  - an `.eslintrc` that doesn't stop at `root: true`.

  Newer tools stop at the nearest configuration.
- **A container hides the main checkout.** A project that runs its tools in the docker module's
  container isn't affected: the container mounts only the worktree.
- **Claude Code nests every worktree.** Per its documentation (checked 2026-11-15), it creates them
  under `.claude/worktrees/`. No project setting moves them; the desktop app's location is each
  user's own preference.

**What the location never decided.** The scripts give the env file, the port, the setup, the
`<type>/<slug>` branch, and the base branch wherever the folder is. Two probes in the desktop app,
the same day:

- **The app forgets a branch switch.** A session switched its app worktree to a new branch, and the
  app kept recording the generated one.
- **The app reuses its folders.** Archiving the session deleted no branch and kept the folder, on a
  detached HEAD. The next new session opened in that same folder, on a new branch.

So a task still gets a worktree of its own, named after its branch. What changes is only where that
worktree sits.

## Decision

- **Every task's worktree goes under the main checkout's `.claude/worktrees/`,** named after its
  branch (`.claude/worktrees/feat-newsletter-signup`), beside Claude Code's own. `WORKTREE_PARENT`
  goes, and no other location is offered.
- **The port lock moves** to the repository's shared git directory (`.git/agent-worktree-ports.lock`),
  out of the folder the app keeps its worktrees in.
- **Older worktrees are reused where they are.** `adf-worktree-new` finds a branch's worktree
  wherever it sits, so one beside the main checkout from an older release keeps working.
  `adf-worktree-rm` removes it as before.
- **A missing ignore line is named.** `adf-worktree-new` notes when git doesn't ignore
  `.claude/worktrees/`.
- **The guide names the three causes** and the fix for each: the container or an install in the
  worktree, `compilerOptions.types` or TypeScript 6.0+, and `"root": true` or the flat config.
- **The rest stands.** The task's worktree is still the scripts', and the session still moves there
  (0042), approved by the approve-worktree-move hook (0035). The app's own worktree is still only
  where a session starts (0040). The reason is now that the app reuses that folder, its branch is
  generated, and it has none of the scripts' setup.
- **The text follows.** The hooks' messages, `/adf:dispatch`, the parallel-agents guide, and the
  module's docs say `.claude/worktrees/`.

## Consequences

- **Positive:**
  - No parent folder to set up for the main checkout.
  - Trusting the main checkout covers every task's worktree.
  - A terminal session in Claude Code's own worktree moves with `EnterWorktree` instead of
    stopping.
  - One folder holds every worktree of the repository, and there's one setting fewer.
- **Negative / cost:**
  - **A project with one of the three causes** gets wrong results until it applies the fix. In the
    TypeScript case, a typecheck passes locally and fails in CI. The guide names each cause, and
    nothing checks for them.
  - **A team that set `WORKTREE_PARENT` loses it.**
  - **Checked at runtime afterwards:** see § Found later. One check found a problem that isn't
    this decision's: the desktop app no longer lets a session move out of its own worktree.

## Found later (2026-11-15) — the runtime check

Three probe sessions ran in the desktop app on this repository. Their targets were task worktrees
that the module's script created under `.claude/worktrees/`. `adf-worktree-new` and
`adf-worktree-rm` ran end to end, and the ignore note stayed quiet where git ignores the folder.

- **The desktop app refuses to move a session out of its own worktree.**
  - A session the app started in its own worktree called `change_directory` with the task's
    worktree. The app's own hook refused it before any approval or trust check: the session "can't
    be moved (it runs in an isolated worktree, shares another session's folder, or runs on a remote
    host)". The app points at `request_directory` instead.
  - The refusal doesn't depend on where the target sits, so it isn't this decision's. It stops the
    move 0040 and 0042 rely on for every session that starts in the app's worktree, which includes
    every chip's. `/adf:dispatch` falls back to giving the developer the path.
  - Whether trusting the main checkout covers the nested folder stays unanswered: the move never
    reached that check.
- **`EnterWorktree` reaches the task's worktree without a prompt.**
  - From a session already in a worktree, `EnterWorktree` into `.claude/worktrees/<task>` entered it
    with no approval asked.
  - Into a folder outside `.claude/worktrees/`, from the app's worktree, the session waited for the
    developer's answer before it moved. The documentation's "always asks" holds; its "only under
    `.claude/worktrees/` from a worktree session" doesn't.
  - As 0021 found, the app keeps showing the session in its own folder after the move.
- **The app leaves the scripts' worktrees alone.**
  - Archiving a session parked only its own worktree, on a detached HEAD, and deleted no branch.
  - The next new session reused that parked folder, on a new branch.
  - A task worktree on its branch, in the same folder, stayed as it was through both.
  - The app's sweep about 30 days after an archive wasn't tested.

The location holds. The move out of the app's worktree is the open problem, for a decision of its
own.

## Alternatives considered

- **Nested by default, beside the main checkout as an opt-in.** Two locations to explain and test,
  for the projects that can fix their tools instead.
- **Work in Claude Code's own worktree,** switching its branch and setting it up in place. The app
  reuses an archived session's folder for a later session, with that folder's ignored files and
  Compose project. It also keeps recording the generated branch after a switch.
- **A `WorktreeCreate` hook that places Claude Code's worktrees.** It is told only a generated name,
  and it turns off `.worktreeinclude` (0021).
