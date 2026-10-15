# syntax=docker/dockerfile:1

# The app's image for local development: `target: dev` in compose.yaml. A production image gets a
# stage of its own below this one. Every line marked CUSTOMIZE is the stack's.

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
