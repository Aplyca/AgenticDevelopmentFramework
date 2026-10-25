# 0056: Claude Desktop's Browser lists each checkout's running web services, from an untracked `.claude/launch.json`

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
- **For a localhost `url`, the entry's `port` must match the URL's, and the URL can't have a path.**
  Localhost here covers `localhost`, `*.localhost`, `127.0.0.1`, and `::1`.
- **The docs assume the file is committed.** They warn against putting secrets in it for that reason.

**What spikes in this repository showed:**

- **A new tab lists every entry** as its name exactly as written, then `:port`, with a play button
  that opens the URL. It never shows the host.
- **A worktree session reads its worktree's own file,** not the main checkout's.
- **An edited port shows up without a restart,** on the next new tab and in the agent's
  `preview_start`.
- **Nothing in the file is computed.** `${env:…}` in a `url` is "not a valid URL", and `port` must be
  a JSON number. The docs name one placeholder, `${workspaceFolder}`, in `cwd` only, and no local
  override file.
- **Desktop picks a port only for a command it runs itself:** with `autoPort`, it passed a free port
  as `PORT`. That command has to stay in the foreground. One that started a server and returned
  failed with "the dev server exited during startup".

**The port isn't fixed:**

- **Each checkout has its own.** The parallel-agents module reserves one per worktree.
- **Docker picks a new one each time a service starts** (0032, P2). A port one checkout freed can go
  to another checkout's app.

So a committed entry would be wrong in every checkout but one, and stale after every restart.

## Decision

1. **Each running web service gets a row in `.claude/launch.json`.** A row attaches to the service:
   `url` `http://localhost:<port>` and `port`, with no command. It's named
   `<service> · http://localhost:<port>`, so a new tab shows the full URL, and one click opens it.
2. **Which services:**
   - **Every service `compose.yaml` labels `claude.browser: "true"`:** one with pages a person opens,
     such as the app, its production build, an admin UI, or a mail catcher. Each is listed on the
     port Docker published for it. The templates label the app and `web-prod`, and no backing
     service.
   - **The app on the host in native mode,** while it runs, named after `APP`.
   - **A worktree that runs a server on the host** (parallel-agents with `PORT_SLOTS`) gets `app` on
     the port `worktree-new.sh` reserved. That port stays the worktree's while its env file holds it.
3. **The rows match what runs.** `ops/docker/launch-json.sh` asks Docker Compose what runs, and
   native mode's run state whether the app does, and rewrites the rows to match:
   - **Who runs it:** `make up`, `make prod`, `make down`, and native mode's `make services`, and
     `native.sh` when it starts or stops the app.
   - **A stopped service loses its row,** so a port Docker later hands to another checkout is never
     listed in this one.
4. **Pages inside an app are never rows.** Desktop refuses a path on a localhost `url`. The band and
   `make urls` are where such links go.
5. **The file is each checkout's own:**
   - **Git ignores it.** `/dev-env set up` adds `.claude/launch.json` to `.gitignore` (L7), and the
     parallel-agents setup does when worktrees run a server.
   - **No ignore line, no rows.** Where git doesn't ignore the file — the project commits its own —
     nothing is written, and `make up` says so in one line.
6. **The developer's entries stay:**
   - **Only its own rows change.** They're the attach entries named `<service> · <url>`. Every other
     configuration and setting (`autoVerify`) is kept.
   - **A file with comments is left as it is,** since the app allows comments but plain JSON doesn't.
   - **The file goes once it's empty.** Removing the last row deletes a file that held nothing else.
7. **It never fails the task.** The rows need `python3`, and without it nothing is listed. A problem
   is one line on stderr.
8. **Where the code lives:**
   - **Docker module:** `ops/docker/launch-json.sh`, which native mode uses too, as it uses `guard.sh`
     (L4).
   - **Parallel-agents module:** a function in `_worktree-lib.sh`, since the modules are installed
     independently.
9. **The band doesn't change.** It still shows the app's URL and whether it answers, in the terminal
   too.

## Consequences

- **Positive:**
  - **A new tab in the Browser lists every running web service,** with its full URL and current port,
    in the main checkout and in every worktree. One click opens it.
  - **The agent's preview attaches to what `make up` runs,** with `preview_start` by the row's name,
    instead of a dev server Desktop would start outside the stack's ports and mode.
  - **A new web service needs one label** in `compose.yaml`, which stays the one place the stack is
    described (P3).
  - **No change to the mod,** so 0026 holds as it is.
- **Negative / cost:**
  - **Claude Desktop only.** The terminal and other tools have the band and `make urls`.
  - **The port shows twice in a row** (`web · http://localhost:55123 :55123`): Desktop adds it after
    the name.
  - **A row's name changes with its port,** so the agent reads it from the file, and the script
    recognizes its rows by their shape.
  - **A project that commits `.claude/launch.json` gets no rows,** unless it untracks the file.
  - **Only tasks the framework runs keep the rows current.** If the stack starts or stops some other
    way, such as `docker compose up` by hand or a Docker restart, the rows are stale until the next
    task that runs the script.
  - **One more file a running service leaves** (P5), and one more `python3` use at run time, which
    is skipped without it.
  - **Two copies of the logic,** one per module, each with its own tests.

## Alternatives considered

- **The mod writes the file, or opens the Browser.** Mods are display-only (0026): no file writes and
  no tool calls. They also get no event for a new tab.
- **A committed `launch.json` with a computed port.** Desktop computes nothing in `url` or `port`, and
  its environment is the same for every checkout anyway.
- **A committed `launch.json` with a fixed port, chosen once.** Every worktree would get the same
  port: the second checkout's `make up` fails, `guard.sh` refuses the copied port (P6), and a new tab
  in a worktree would open the main checkout's app.
- **A committed command entry with `autoPort`, so Desktop starts the app itself.** It needs a new
  foreground task. Desktop would then own a second lifecycle beside `make up`: its play button starts
  another copy, or moves the running one to a new port. It also bypasses the worktree port
  reservation.
- **The service list as a setting in the `Makefile`.** A label keeps the fact next to the service it
  describes, and Docker Compose reports it with the service's ports.
- **The plain service name as the row's name.** It's stable, but a new tab then shows only the port.
- **A hook that writes the rows at the start of each session and the end of each turn.** One place in
  the code, but the rows would lag a `make up` run in a terminal until the next turn.
- **Leaving the rows after `make down`.** That's simpler, but it can list a port that Docker has since
  given to another checkout's app, and a click would open the wrong app.
