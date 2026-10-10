---
# CUSTOMIZE: Update paths to match your project's infra files
paths:
  - "compose.yaml"
  - "compose.*.yaml"
  - "docker-compose.yml"
  - "docker-compose.yaml"
  - "Dockerfile"
  - "Makefile"
  - "ops/**"
  - ".env.example"
  - ".github/**"
  - "infra/**"
---

# Deployment Rules

## Environments
<!-- CUSTOMIZE: Define your project's environments -->

| Environment | Purpose | Setup |
|---|---|---|
| Local | Development | `make up` in the checkout's mode — Docker, or the app on the host — or equivalent |
| Test | Automated tests | Their own port, mock services |
| Staging | Pre-production validation | Mirrors production config |
| Production | Live | Full infrastructure |

## Command surface
- A `Makefile` at the root holds the common tasks, for people and agents alike; `make help` lists
  them. A task the team runs often gets a target instead of a command copied around.
- With Docker: `env`, `up`, `down`, `build`, `ps`, `logs`, `urls`, `test`, `lint`, and `reset` —
  the only one that deletes data. `logs` shows the last lines and never follows.
- One file per mode: the root `Makefile` loads `ops/<DEV_MODE>/Makefile` — `ops/docker/Makefile`, or
  `ops/native/Makefile` for the app on the host — and both define the same tasks, so nobody types a different
  command for the mode. `DEV_MODE` in `.env` picks it; `DEFAULT_MODE` in the `Makefile` is the
  project's default. `make help` names the mode in force.

## Port assignments
<!-- CUSTOMIZE: List the port variables your local environment publishes -->
- No fixed host ports. Each service a person or the host reaches is published on the port in its
  `<NAME>_PORT` variable — `APP_PORT`, `REDIS_PORT` — which `.env.example` leaves empty, so Docker
  picks a free one each time the service starts and any number of checkouts and worktrees run side by
  side. `make urls` shows where each one is.
- A developer pins a port in their own `.env` when something must know it in advance (an OAuth
  callback, an app that builds its own URL).
- Tests use a port of their own — never the dev server's, so a test run doesn't collide with it.

## Environment variables
- Never hard-code service URLs. Always use environment variables.
- Never commit `.env`, `.env.local`, or any file containing credentials.
- Three levels:
  - **`.env`** at the root, untracked — what Docker Compose reads to fill each `${…}` in
    `compose.yaml`, and what the app reads when it runs on the host. `make env` creates it from the
    template.
  - **`environment:`** on each service in `compose.yaml` — what that container gets, in container form
    (service names, container ports). Never `env_file:`, which hands every variable to every container.
  - **`.env.example`**, committed — every variable by name, with placeholder values or none, never a
    real one.

## Docker (if applicable)
- `compose.yaml` at the root defines the full local stack; overrides go beside it as
  `compose.<name>.yaml`.
- Operational code lives in `ops/`, **one folder per target**, and the app's code doesn't. A target
  keeps everything it needs in its folder — its make file, scripts, images, and config:
  - `ops/docker/` — the stack in Docker: `Makefile`, `guard.sh`, and each service's image and
    config in `ops/docker/<service>/`;
  - `ops/native/` — the app on the host: `Makefile`, `native.sh`, and `.run/` (ignored by git);
  - `ops/agent/` — the parallel-agents module, when installed;
  - <!-- CUSTOMIZE: each deployment target the project adds, e.g. `ops/vercel/`, `ops/ecs/` -->
  A folder with a `Makefile` is a local mode `DEV_MODE` can pick; a deployment target has none
  (its tasks go in a file of another name, such as `deploy.mk`).
  Targets may use each other's files (native's backing services are Docker's; ECS deploys the image
  `ops/docker/web/` builds), but nothing goes in a shared `scripts/` or `make/` folder. A file a tool
  reads from a fixed place stays there: `compose.yaml` at the root, `vercel.json`, `.github/`.
- Published ports bind to `127.0.0.1` from a port variable: `"127.0.0.1:${APP_PORT:-}:3000"`.
- No `container_name:` and no top-level `name:` — the checkout's folder names the Compose project.
- Pin image versions. A service another one waits for has a healthcheck, and the one that waits uses
  `depends_on` with `condition: service_healthy`. Data lives in named volumes.
- Native mode (`DEV_MODE=native`) runs the app on the host with its own dev command, against the
  backing services in Docker (`DEFAULT_SERVICES` in `ops/native/Makefile`). A developer who runs some
  on the host sets their own `SERVICES` in `.env` (or `none`) and pins those services' ports there. `make up` starts the app in the background and waits until
  it answers; its process, port, and log stay in `ops/native/.run/`, which git ignores.
- Volume-mount config files so changes persist without rebuilding.
- Use multi-stage builds for production images, and keep secrets out of the build context
  (`<Dockerfile>.dockerignore` beside each Dockerfile).

## Conformance
<!-- CUSTOMIZE: with the docker module, the local environment follows the specification `/dev-env`
carries (SPECIFICATION.md, beside its skill). List here each requirement this project departs from
on purpose, by ID, with the reason — an audit reports it as an exception, not a gap. -->
- None.

## CI/CD (if applicable)
- Tests pass before merge; a failure the reviewer accepts is explained in the pull request.
- Use the same test configuration locally and in CI.
- Never skip hooks or checks in CI (`--no-verify`, `--force`).
