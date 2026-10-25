# 0056: Claude Desktop's Browser lists each checkout's running app, from an untracked `.claude/launch.json`

- **Status:** accepted
- **Date:** 2026-10-25
- **Builds on:** [0026](0026-display-only-mods.md) — the band above the prompt shows the local URL;
  [0032](0032-local-environment-layout.md) — ports Docker picks;
  [0034](0034-local-environment-modes.md) — the app in Docker or on the host
- **Amends:** the local environment's specification — L7 and P5, and a new P8

## Context

**The developer checks the change on the local environment before the draft pull request**
(0022). The band above the prompt shows the URL and whether it answers (0026). Claude Desktop now has
a built-in Browser beside the conversation, and it's where that check happens most easily.

**What a mod can't do** (mod API 2.1.308): it gets no event when the Browser opens or a tab is
created, and it has no slot in the app's own interface, such as the Environment box. Calling the
Browser's tools from a mod would be a tool call, which 0026 rules out.

**What the app does on its own** (desktop docs, checked 2026-10-25):

- **`.claude/launch.json` names dev servers.** A configuration with a command starts one, and a
  configuration with a `url` and no command attaches to a server that already runs.
- **For a `localhost` `url`, the entry's `port` must match the URL's.** So an entry holds a concrete
  port.
- **The docs assume the file is committed.** They warn against putting secrets in it for that reason.

**What a spike showed** (two throwaway servers, one session in the main checkout and one in a
worktree):

- **A new tab lists every entry** as its name and port, with a play button that opens the URL and
  starts nothing.
- **A worktree session reads its worktree's own file,** not the main checkout's.
- **An edited port shows up without a restart,** on the next new tab and in the agent's
  `preview_start`.

**The port isn't fixed:**

- **Each checkout has its own.** The parallel-agents module reserves one per worktree.
- **Docker picks a new one each time the app starts** (0032, P2). A port one checkout freed can go to
  another checkout's app.

So a committed entry would be wrong in every checkout but one, and stale after every restart.

## Decision

1. **The running app gets an entry in `.claude/launch.json`.** The entry attaches to the app (`url`
   `http://localhost:<port>` and `port`, no command), so a new tab lists it and one click opens it.
2. **What writes it is whatever learns the port, at that moment:**
   - **Docker mode:** `make up` sets the entry once the stack is healthy, on the port Docker
     published.
   - **Native mode:** `native.sh start` sets it once the app answers.
   - **A worktree that runs a server on the host** (parallel-agents with `PORT_SLOTS`):
     `worktree-new.sh` sets it on the port it reserved, which stays that worktree's while its env file
     holds it.
3. **The entry goes when the app stops.** `make down` unsets it, and so does `native.sh stop`, which
   each mode's `up` runs for the other mode (M8). A port Docker later hands to another checkout is
   then never listed in this one.
4. **The file is each checkout's own:**
   - **Git ignores it.** `/dev-env set up` adds `.claude/launch.json` to `.gitignore` (L7), and the
     parallel-agents setup does when worktrees run a server.
   - **No ignore line, no entry.** Where git doesn't ignore the file — the project commits its own —
     nothing is written, and `make up` says so in one line.
5. **The developer's entries stay:**
   - **Only its own entry changes.** The entry is named after the app's service (`APP`, such as
     `web`), or `app` from `worktree-new.sh`. Every other configuration and setting (`autoVerify`) is
     kept.
   - **Some files are left as they are:** a file with comments, which the app allows but plain JSON
     doesn't, and a configuration of that name that runs a command.
   - **The file goes once it's empty.** Unsetting the last entry deletes a file that held nothing else.
6. **It never fails the task.** The entry needs `python3`, and without it nothing is listed. A
   problem is one line on stderr.
7. **Where the code lives:**
   - **Docker module:** `ops/docker/launch-json.sh`, which native mode uses too, as it uses
     `guard.sh` (L4).
   - **Parallel-agents module:** a function in `_worktree-lib.sh`, since the modules are installed
     independently.
8. **The band doesn't change.** It still shows the URL and whether it answers, in the terminal too.

## Consequences

- **Positive:**
  - **A new tab in the Browser lists the checkout's app,** on its current port, in the main checkout
    and in every worktree, and one click opens it.
  - **The agent's preview attaches to the app** that `make up` runs, with `preview_start` by the app's
    name, instead of a dev server Desktop would start outside the stack's ports and mode.
  - **No change to the mod,** so 0026 holds as it is.
- **Negative / cost:**
  - **Claude Desktop only.** The terminal and other tools have the band and `make urls`.
  - **A project that commits `.claude/launch.json` gets no entry,** unless it untracks the file.
  - **Only tasks the framework runs keep the entry current.** If the stack starts or stops some other
    way, such as `docker compose up` by hand or a Docker restart, the entry is stale until the next
    `make up` or `make down`.
  - **One more file a running app leaves** (P5), and one more `python3` use at run time, which is
    skipped without it.
  - **Two copies of the merge logic,** one per module, each with its own tests.

## Alternatives considered

- **The mod writes the file, or opens the Browser.** Mods are display-only (0026): no file writes and
  no tool calls. They also get no event for a new tab.
- **A committed `launch.json`.** It holds one port, which is wrong in every worktree, and stale after
  Docker picks a new one.
- **A configuration with a command and `autoPort`, so Desktop starts the app itself.** Desktop would
  then pick the port and run the dev command outside `make up`. That bypasses the stack's mode (M10),
  Docker's ports, and the worktree port reservation.
- **A hook that writes the entry at the start of each session and the end of each turn.** One place
  in the code, but the entry would lag a `make up` run in a terminal until the next turn. It would
  also look the port up again instead of taking it where it's learned.
- **Leaving the entry after `make down`.** That's simpler, but it can list a port that Docker has
  since given to another checkout's app, and a click would open the wrong app.
