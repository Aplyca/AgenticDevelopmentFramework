
# The local environment's tasks: one command surface for people and agents. `make` lists them.
# Docker Compose reads .env itself; this file reads only DEV_MODE and HOST_SERVICES from it, and never
# loads or exports the rest, so no other value reaches a command that doesn't need it. Works with GNU
# make 3.81 (macOS) and later.

COMPOSE ?= docker compose
# CUSTOMIZE: where the app runs unless a checkout's .env says otherwise — docker (the whole stack in
# Docker) or native (the app on the host, its backing services in Docker)
DEFAULT_MODE = docker
# CUSTOMIZE: the app's service, and the backing services native mode still runs in Docker
APP ?= web
SERVICES ?= redis
# CUSTOMIZE: each published port, as <variable>=<service>:<container port>
PORTS ?= APP_PORT=web:3000 REDIS_PORT=redis:6379
# CUSTOMIZE: the app's dev command on the host, listening on $APP_PORT — e.g.
#   NATIVE_CMD = npm run dev -- --port "$$APP_PORT"
NATIVE_CMD = echo "CUSTOMIZE: set NATIVE_CMD in the Makefile to the app's dev command" >&2; exit 1
# CUSTOMIZE: what installs the app's dependencies on the host (native mode's `make build`) — e.g.
#   npm ci · composer install · bundle install · pip install -r requirements.txt
NATIVE_INSTALL_CMD = echo "CUSTOMIZE: set NATIVE_INSTALL_CMD in the Makefile" >&2; exit 1
# CUSTOMIZE: the test and lint commands. They run in the app's container, or on the host in native mode.
TEST_CMD = echo "CUSTOMIZE: set TEST_CMD in the Makefile" >&2; exit 1
LINT_CMD = echo "CUSTOMIZE: set LINT_CMD in the Makefile" >&2; exit 1
export NATIVE_CMD NATIVE_INSTALL_CMD TEST_CMD LINT_CMD

# One value from .env, unquoted, without a trailing comment; empty when it isn't there.
env_value = $(shell sed -n 's/^$(1)=\([^\#]*\).*/\1/p' .env 2>/dev/null | tail -n 1 | tr -d "\"' ")
# The mode: `make up DEV_MODE=native`, then the shell's DEV_MODE, then .env's, then DEFAULT_MODE.
ifeq ($(origin DEV_MODE),undefined)
DEV_MODE := $(call env_value,DEV_MODE)
endif
override DEV_MODE := $(or $(strip $(DEV_MODE)),$(DEFAULT_MODE))
ifeq ($(filter docker native,$(DEV_MODE)),)
$(error DEV_MODE is '$(DEV_MODE)': set it to docker or native in .env)
endif
# The backing services this developer runs on the host instead of in Docker, in native mode.
ifeq ($(origin HOST_SERVICES),undefined)
HOST_SERVICES := $(call env_value,HOST_SERVICES)
endif
DOCKER_SERVICES = $(filter-out $(HOST_SERVICES),$(SERVICES))
# Compose, or — in native mode with nothing in Docker — Compose only if it's there, quietly.
ifeq ($(DEV_MODE)$(strip $(DOCKER_SERVICES)),native)
STACK = @$(COMPOSE)
QUIET = >/dev/null 2>&1 || true
else
STACK = $(COMPOSE)
QUIET =
endif

PORTS_SH = PORTS='$(PORTS)' APP='$(APP)' COMPOSE='$(COMPOSE)' DEV_MODE='$(DEV_MODE)' HOST_SERVICES='$(HOST_SERVICES)' ops/scripts/ports.sh
NATIVE_SH = PORTS='$(PORTS)' APP='$(APP)' COMPOSE='$(COMPOSE)' DEV_MODE='$(DEV_MODE)' HOST_SERVICES='$(HOST_SERVICES)' ops/scripts/native.sh

.DEFAULT_GOAL := help
.PHONY: help env up down build ps logs urls shell services native test lint reset guard

help: ## List the tasks
	@echo "Mode: $(DEV_MODE) — DEV_MODE in .env sets it (docker or native); the default is $(DEFAULT_MODE)"
	@awk 'BEGIN { FS = ":.*## " } /^[a-z][a-z-]*:.*## / { printf "  make %-9s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

env: ## Create .env from .env.example, if it's missing
	@if [ -f .env ]; then echo ".env is there; left as it is"; \
	else cp .env.example .env && chmod 600 .env && echo "Created .env from .env.example: fill in the credentials it names"; fi

up: env guard ## Start the local environment in its mode, wait until it answers, and show where it is
ifeq ($(DEV_MODE),native)
	@$(MAKE) --no-print-directory services
	-@$(COMPOSE) stop $(APP) >/dev/null 2>&1
	@$(NATIVE_SH) start
else
	@ops/scripts/native.sh stop
	$(COMPOSE) up -d --wait
endif
	@$(PORTS_SH) urls

down: guard ## Stop the local environment; its data stays
	@ops/scripts/native.sh stop
	$(STACK) down $(QUIET)

build: env ## Rebuild the images — and, in native mode, install the app's dependencies on the host
ifeq ($(DEV_MODE),native)
	@sh -c "$$NATIVE_INSTALL_CMD"
	$(if $(strip $(DOCKER_SERVICES)),$(COMPOSE) build $(DOCKER_SERVICES))
else
	$(COMPOSE) build
endif

ps: ## What runs, its state, and its health
ifeq ($(DEV_MODE),native)
	@$(NATIVE_SH) status
endif
	$(STACK) ps $(QUIET)

logs: ## The last 100 lines of every log, or one service's: make logs s=web
ifeq ($(DEV_MODE),native)
	@$(if $(filter-out $(APP),$(s)),,echo "==> $(APP) (on the host)" && ops/scripts/native.sh logs)
	$(if $(filter $(APP),$(s))$(if $(strip $(DOCKER_SERVICES)),,x),,$(COMPOSE) logs --tail 100 --no-color $(s))
else
	$(COMPOSE) logs --tail 100 --no-color $(s)
endif

urls: ## Where each service is now — Docker picks the ports it isn't given
	@$(PORTS_SH) urls

shell: ## A shell in the app's container, for people (docker mode)
ifeq ($(DEV_MODE),native)
	@echo "The app runs on the host in native mode: use your own shell" >&2; exit 1
else
	$(COMPOSE) exec $(APP) sh
endif

services: env guard ## Start only the backing services that run in Docker
	$(if $(strip $(DOCKER_SERVICES)),$(COMPOSE) up -d --wait $(DOCKER_SERVICES),@echo "No backing services in Docker")

native: services ## Run the app on the host in the foreground, whatever the mode — Ctrl-C stops it
	-@$(COMPOSE) stop $(APP) >/dev/null 2>&1
	@ops/scripts/native.sh stop
	@eval "$$($(PORTS_SH) env)" && echo "==> The app on the host: http://localhost:$$APP_PORT" && sh -c "$$NATIVE_CMD"

test: ## Run the tests — in the app's container, or on the host in native mode
ifeq ($(DEV_MODE),native)
	@eval "$$($(PORTS_SH) env)" && sh -c "$$TEST_CMD"
else
	$(COMPOSE) exec -T $(APP) sh -c "$$TEST_CMD"
endif

lint: ## Run the linters — in the app's container, or on the host in native mode
ifeq ($(DEV_MODE),native)
	@sh -c "$$LINT_CMD"
else
	$(COMPOSE) exec -T $(APP) sh -c "$$LINT_CMD"
endif

reset: env guard ## DESTRUCTIVE: delete the stack's containers and volumes, then start it again
	@ops/scripts/native.sh stop
	$(STACK) down -v --remove-orphans $(QUIET)
	@$(MAKE) --no-print-directory up

guard:
	@$(PORTS_SH) guard
