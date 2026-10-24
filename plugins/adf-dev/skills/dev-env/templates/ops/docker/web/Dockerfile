# syntax=docker/dockerfile:1

# The app's image for local development: `target: dev` in compose.yaml. The production build, for
# `make prod`, is the prod stage below it. Every line marked CUSTOMIZE is the stack's.

# CUSTOMIZE: the base image, pinned to a version — e.g. the Node.js image the newsletter site runs on
FROM <image>:<version> AS dev
WORKDIR /app

# CUSTOMIZE: the dependency manifests, then the install, so the layer is rebuilt only when they change
COPY <manifests> ./
RUN <install command>

COPY . .

# CUSTOMIZE: the port the app listens on, as compose.yaml publishes it
EXPOSE 3000
# CUSTOMIZE: the dev command, listening on every interface so the published port reaches it
CMD ["<dev command>"]

# Optional: the production build, as a deploy builds it, and the production server — `target: prod`
# in compose.yaml's web-prod. Delete it with that service if the project has no production-like run.
FROM dev AS prod
# CUSTOMIZE: the production build command
RUN <build command>
# CUSTOMIZE: the production server, listening on every interface
CMD ["<production server command>"]
