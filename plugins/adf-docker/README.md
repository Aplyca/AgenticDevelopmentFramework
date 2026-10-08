# adf-docker

The `docker` module's machinery for a packaged install of the [Agentic Development Framework](https://github.com/aplyca/AgenticDevelopmentFramework): `/adf-docker:dev-env`.

The docker module's skill for a packaged install: /adf-docker:dev-env sets up a Docker Compose local environment from verified facts, gives each worktree its own stack, diagnoses one signal-first, and resets it without touching other projects. Turn it on only where the docker module is installed; elsewhere it stops.

**Generated** from [`modules/docker/`](https://github.com/aplyca/AgenticDevelopmentFramework/tree/main/modules/docker) by `scripts/build-plugins.sh` ([decision 0023](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/docs/decisions/0023-area-plugins-for-modules.md)); never edit it here.

It is listed in the `aplyca` marketplace beside `aplyca-adf`, at the same version. `/aplyca-adf:adopt` and `/aplyca-adf:upgrade` turn it on in a packaged project that installs the `docker` module; a committed project copies the module's files instead and leaves it off. Anywhere else its skills say so and stop. What the module adds, and how to install and customize it: [`MODULE.md`](https://github.com/aplyca/AgenticDevelopmentFramework/blob/main/modules/docker/MODULE.md).
