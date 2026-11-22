# Set up — write a stack, or bring one to the specification

`/adf-dev:dev-env` reads this for the set up mode (step 4), with
`<this skill's base directory>/SPECIFICATION.md`: no stack yet, or one that doesn't meet the
specification. The requirement IDs below are the specification's.

1. **No stack yet?** Writing one is an infrastructure change — `/adf:triage` it like any change (the
   careful lane at least). Copy the templates in `<this skill's base directory>/templates/` to the
   same paths in the repository — `compose.yaml`, `Makefile`, `.env.example`, `ops/docker/`, and
   `ops/native/` — never over a file that's there. Then fill every `CUSTOMIZE` from facts you
   verified, so the result meets the specification for this project:
   - the app's service, its container port, its Dockerfile, and its dev command;
   - each backing service the code uses (its client library, the variable its URL comes from),
     pinned, with a healthcheck the app's `depends_on` waits on;
   - every variable the code reads: by name in `.env.example`, and in container form in its
     service's `environment:` — a credential as `${NAME:-}`, passed through from `.env`;
   - the tools service (D6, D7): the Dockerfile's `tools` stage, the variables the tests read, the
     backing services they need in its `depends_on`, the folder the install writes as the `deps`
     volume's mount point in the app's service and in `tools`, the cache volume's `name:` (the
     repository's), and the variable that points the package manager's cache at `/cache`;
   - in the `Makefile`: `APP` and `DEFAULT_MODE` (`docker` unless the team runs the app on the host);
   - the label `claude.browser: "true"` on each service P8 names, and on no backing service;
   - in each mode's `Makefile`, its own commands: in `ops/docker/`, `deps`, `test`, `lint`,
     `format`, and `typecheck` in the tools container (`$(COMPOSE) run --rm tools …`, `--no-deps`
     where no backing service is needed); in `ops/native/`, `DEFAULT_SERVICES` (the backing services
     that stay in Docker), `NATIVE_CMD` (the app's dev command, listening on `$APP_PORT`), and its
     `deps` (installing dependencies on the host), `test`, `lint`, `format`, and `typecheck`. `test`
     passes `t` to the test runner as its filter, and `lint` and `format` pass `f` as the files
     (C3). Each from the project's package manifest, README, or docs — never a guess at the stack.
     A project that never runs natively keeps `ops/native/Makefile` as the template wrote it;
   - the production build, `make prod` (C11): the Dockerfile's `prod` stage — the build command and
     the production server, as the project's deploy runs them — `web-prod`'s port and
     `environment:`, and `NATIVE_PROD_CMD`. A project with no production-like run deletes the task
     in both mode files, the service, and the stage.

   Then `chmod +x ops/docker/guard.sh ops/docker/launch-json.sh ops/native/native.sh`, and make sure
   `.gitignore` has `.env`, `ops/native/.run/`, and `.claude/launch.json` (P8).
2. **A stack that doesn't meet the specification?** Audit it in the order its § Conformance gives,
   and show the gaps in one table — the requirement's ID, what the project has, the change. A
   departure `.claude/rules/deployment.md` records with its reason is an exception, not a gap. The
   usual ones:
   - a Compose file away from the root, or under a legacy name;
   - Dockerfiles, service config, or scripts outside `ops/`, or in `ops/` by kind of file
     (`ops/scripts/`, `ops/make/`) rather than in their target's folder;
   - no `Makefile`, or one without the tasks;
   - `env_file:`, or a variable the code reads that no `environment:` passes;
   - a `${VAR}` that `.env.example` doesn't declare — a gap to report, not to fill with a guess;
   - a fixed host port, or one bound to every interface;
   - `container_name:` or a top-level `name:`;
   - a service another one waits for without a healthcheck and `condition: service_healthy`;
   - no `DEV_MODE`: a `Makefile` with its own `native` or `dev` targets beside the Docker ones, which
     the two mode files replace;
   - a `test` that doesn't take `t=`, or a `lint` or `format` that doesn't take `f=` — one with a
     variable of its own (`args=`) or none: name each task and what it takes (C3). `make` ignores a
     variable a task doesn't take, so until it's fixed `make test t=<file>` runs the whole suite and
     `make lint f=<file>` lints everything; § Quick reference writes what the task takes meanwhile;
   - no `run` task, or one that pastes `$(cmd)` into the recipe or runs it anywhere but a container
     that meets D5 in Docker mode (C10): until it meets C10, `make run` runs some or all of its
     command on the host, without a prompt;
   - checks that `exec` into the app's container, so they need `make up` and see only what the app
     mounts, or no tools service (D6);
   - dependencies on the host — a dependency folder in the checkout that the host filled, a
     `SETUP_CMD`, git hook, or doc step that installs there — or a task that runs a runtime or CLI
     on the host (M11);
   - another task that runs a command it's given on the host (`make exec`) without an ask rule (C10);
   - an app or tools service that mounts the Docker socket or a path outside the checkout, or runs
     `privileged` (D5): `make run` would reach the host from it. A CLI that needs the socket gets a
     service of its own, and its command-taking task an ask rule (D8);
   - an app or tools service that mounts the checkout without the empty `tmpfs` over
     `/app/.claude/worktrees` (D5): in the main checkout, `make run` reaches every nested worktree's
     files and `.env`;
   - a task that deletes data under a name other than `reset` (`db-drop`, a `clean` that removes
     volumes), which `DEV-SETUP.md` doesn't name as one: `Bash(make *)` runs it without a prompt
     (C9), so an agent has to know to ask in chat first;
   - a task that waits for input or never returns, such as a `logs` that follows (C9): an agent that
     runs it waits until its timeout.

   The migration is an infrastructure change: propose it through `/adf:triage` (the careful lane),
   and move nothing before the developer approves. It moves files with `git mv`, adds the template's
   tasks to an existing `Makefile` without renaming the team's own, and updates whatever names the
   old paths — CI, docs, scripts.
3. **Start it:** `make env` — it creates `.env` from `.env.example` and names the credentials for the
   developer to fill in — then `docker compose config --quiet`, and `make up`, which waits until
   every service is healthy and prints where each one is. `make ps`: every service is running, and
   healthy where it has a check. After a Dockerfile change, `make build` first; after a lockfile
   change, `make deps`.
4. **Verify it works:** `curl -fsS` on the app's URL from `make urls` (its health route or home page),
   and the project's quickest test that needs the stack passes against it — in the configured mode
   only (M10). With a dev command for the host, write native mode's file too
   (`<this skill's base directory>/native.md`, step 2), read it against M4–M8, and report it as not
   run: the developer runs it once they switch.

   In Docker mode, check M11 with the stack down (`make down`): make a scratch folder, link
   `docker` into it — with each `docker-credential-*` helper beside it, which pulls need — and `git`
   and `make`, then run `make deps`, `make lint`, `make typecheck`, and `make test`, each with
   `PATH=<scratch folder>:/usr/bin:/bin:/usr/sbin:/sbin`. Each passes; a "command not found" is a
   gap. A runtime the system ships in `/usr/bin` isn't caught this way: read the recipes for one.
   Then `make stop`: `make test` started the backing services the tests need.
5. **Write down what you verified** — a docs change, so it goes through triage too:
   - `DEV-SETUP.md`: the Docker row of Prerequisites — in Docker mode Docker, git, and make are all
     the host needs (M11), and § IDE setup says what the editor does without the dependencies —
     § 2 `make deps`, § 3 `make env`, § 4 `make up` and `make urls`
     with the services, § 6 the two modes — `DEV_MODE` in `.env`, and what native mode needs on the
     host — and the command surface;
   - `AGENTS.md` § Quick reference: `make up`, `make stop` (keeps containers and data), `make down`
     (removes containers; data stays), and `make urls` for where the app is — the words of C12 —
     and the one-file commands of the tests and lint lines, as the tasks take them (C3);
   - `.claude/hooks/config.sh`: `LOCAL_URL='http://localhost:${APP_PORT}'`;
   - `deployment.md`: `paths:` naming `compose.yaml`, `Makefile`, `ops/**`, and `.env.example`, and in
     § Docker any convention the project adds;
   - `DEV-SETUP.md`: each project task that deletes data under a name other than `reset`, named
     as one. No ask rule goes in for it: docker and make commands run without a prompt (C9), and a
     team that wants one adds its own. A task that runs a command it's given on the host, or in a
     service outside D5, under a name other than `run` does get them: on the variable that carries
     its command, `Bash(make *<variable>=*)` and `Bash(<variable>=*)` in `permissions.ask` (C10,
     D8) — a permission change: name it in the change the developer approves.

   § Troubleshooting gets only problems you actually met. For example, the newsletter site: `web`
   (the Next.js app, on container port 3000) and `redis` (the signup rate limiter), started with
   `make up`, found with `make urls`.
