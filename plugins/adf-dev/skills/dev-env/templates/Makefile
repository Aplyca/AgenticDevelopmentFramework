# The local environment's tasks: one command surface for people and agents. `make` lists them.
# Docker Compose reads .env itself; this file never loads or exports it, so no value from it reaches
# a command that doesn't need it. Works with GNU make 3.81 (macOS) and later.

COMPOSE ?= docker compose
# CUSTOMIZE: the app's service, and the backing services `make native` starts in Docker
APP ?= web
SERVICES ?= redis
# CUSTOMIZE: each published port, as <variable>=<service>:<container port>
PORTS ?= APP_PORT=web:3000 REDIS_PORT=redis:6379
# CUSTOMIZE: the app's dev command on the host, listening on $APP_PORT — e.g.
#   NATIVE_CMD = npm run dev -- --port "$$APP_PORT"
NATIVE_CMD = echo "CUSTOMIZE: set NATIVE_CMD in the Makefile to the app's dev command" >&2; exit 1

PORTS_SH = PORTS='$(PORTS)' APP='$(APP)' COMPOSE='$(COMPOSE)' ops/scripts/ports.sh

.DEFAULT_GOAL := help
.PHONY: help env up down build ps logs urls shell services native test lint reset guard

help: ## List the tasks
	@awk 'BEGIN { FS = ":.*## " } /^[a-z][a-z-]*:.*## / { printf "  make %-9s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

env: ## Create .env from .env.example, if it's missing
	@if [ -f .env ]; then echo ".env is there; left as it is"; \
	else cp .env.example .env && chmod 600 .env && echo "Created .env from .env.example: fill in the credentials it names"; fi

up: env guard ## Start the stack, wait until it's healthy, and show where it is
	$(COMPOSE) up -d --wait
	@$(PORTS_SH) urls

down: guard ## Stop the stack; its data stays
	$(COMPOSE) down

build: env ## Rebuild the images
	$(COMPOSE) build

ps: ## The services, their state, and their health
	$(COMPOSE) ps

logs: ## The last 100 lines of every service's log, or one service's: make logs s=web
	$(COMPOSE) logs --tail 100 --no-color $(s)

urls: ## Where each published service is now — Docker picks the ports it isn't given
	@$(PORTS_SH) urls

shell: ## A shell in the app's container, for people
	$(COMPOSE) exec $(APP) sh

services: env guard ## Start only the backing services
	$(COMPOSE) up -d --wait $(SERVICES)

native: services ## Run the app on the host, against the backing services in Docker
	-@$(COMPOSE) stop $(APP) >/dev/null 2>&1
	@eval "$$($(PORTS_SH) env)" && echo "==> The app on the host: http://localhost:$$APP_PORT" && $(NATIVE_CMD)

test: ## Run the tests
	@echo "CUSTOMIZE: the test command, e.g. $(COMPOSE) exec $(APP) <test command>" >&2; exit 1

lint: ## Run the linters
	@echo "CUSTOMIZE: the lint command" >&2; exit 1

reset: env guard ## DESTRUCTIVE: delete the stack's containers and volumes, then start it again
	$(COMPOSE) down -v --remove-orphans
	@$(MAKE) --no-print-directory up

guard:
	@$(PORTS_SH) guard
