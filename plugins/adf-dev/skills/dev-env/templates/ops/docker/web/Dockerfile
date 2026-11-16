# syntax=docker/dockerfile:1

# The app's image for local development: `target: dev` in compose.yaml. The tools stage below it is
# what the checks and `make run` start, and the prod stage is the production build, for `make prod`.
# Every line marked CUSTOMIZE is the stack's.

# CUSTOMIZE: the base image, pinned to a version — e.g. the Node.js image the newsletter site runs on
FROM <image>:<version> AS dev
WORKDIR /app

# CUSTOMIZE: the dependency manifests, then the install, so the layer is rebuilt only when they change.
# It fills a new dependency volume (compose.yaml's deps); make deps keeps that volume up to date.
COPY <manifests> ./
RUN <install command>

COPY . .

# CUSTOMIZE: the port the app listens on, as compose.yaml publishes it
EXPOSE 3000
# CUSTOMIZE: the dev command, listening on every interface so the published port reaches it
CMD ["<dev command>"]

# The tools: what make deps, test, lint, format, typecheck, and run start — `target: tools` in
# compose.yaml's tools service, with the whole checkout mounted over /app. No Docker CLI: a tool
# that needs the Docker daemon gets a service of its own (D8).
FROM dev AS tools
# CUSTOMIZE: what only the checks need and the app doesn't — a system library a linter loads — or
# nothing
CMD ["sh"]

# Optional: the production build, as a deploy builds it, and the production server — `target: prod`
# in compose.yaml's web-prod. Delete it with that service if the project has no production-like run.
FROM dev AS prod
# CUSTOMIZE: the production build command
RUN <build command>
# CUSTOMIZE: the production server, listening on every interface
CMD ["<production server command>"]
