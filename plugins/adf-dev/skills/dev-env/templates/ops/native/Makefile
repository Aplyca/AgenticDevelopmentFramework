# DEV_MODE=native: the app on the host, with the stack's own dev command, against its backing
# services in Docker. The root Makefile loads this file in that mode; native.sh, beside it, runs the
# app in the background, and .run/ (ignored by git) keeps its process, port, and log.

# Loaded by the root Makefile, never run on its own: its settings and paths are the root's.
ifndef MODE_FILE
$(error run make from the repository root: this file is the $(notdir $(CURDIR)) mode, which the root Makefile loads)
endif

# CUSTOMIZE: the backing services that run in Docker — empty when they all run on the host
SERVICES ?= redis
# CUSTOMIZE: the app's dev command, listening on $APP_PORT — e.g. npm run dev -- --port "$$APP_PORT"
NATIVE_CMD = echo "CUSTOMIZE: set NATIVE_CMD in ops/native/Makefile to the app's dev command" >&2; exit 1

export NATIVE_CMD
NATIVE_SH = SERVICES='$(SERVICES)' COMPOSE='$(COMPOSE)' APP='$(APP)' ops/native/native.sh

.PHONY: up down build ps logs urls services test lint reset

up: env guard services ## Start the app on the host, wait until it answers, and show where it is
	@$(COMPOSE) stop $(APP) >/dev/null 2>&1 || true
	@$(NATIVE_SH) start
	@$(MAKE) --no-print-directory urls

down: guard ## Stop the app and the backing services; their data stays
	@ops/native/native.sh stop
	$(if $(SERVICES),$(COMPOSE) down)

build: env ## Install the app's dependencies on the host
	@echo "CUSTOMIZE: the install command, e.g. npm ci · composer install · bundle install" >&2; exit 1

ps: ## The app on the host, and the backing services
	@$(NATIVE_SH) status
	$(if $(SERVICES),$(COMPOSE) ps)

logs: ## The last 100 lines of the app's log, and of each service's: make logs s=redis
	$(if $(s),,@ops/native/native.sh logs)
	$(if $(SERVICES),$(COMPOSE) logs --tail 100 --no-color $(s))

urls: ## Where the app and each backing service are now
	@$(NATIVE_SH) status
	$(if $(SERVICES),@$(COMPOSE) ps --format 'table {{.Service}}\t{{.Ports}}\t{{.Status}}')

services: env guard ## Start only the backing services in Docker
	$(if $(SERVICES),$(COMPOSE) up -d --wait $(SERVICES),@echo "No backing services in Docker")

test: services ## Run the tests on the host, with the services' ports exported
	@eval "$$($(NATIVE_SH) env)" && echo "CUSTOMIZE: the test command after the exports, e.g. npm test" >&2 && exit 1

lint: ## Run the linters on the host
	@echo "CUSTOMIZE: the lint command, e.g. npm run lint" >&2; exit 1

reset: env guard ## DESTRUCTIVE: delete the services' containers and volumes, then start again
	@ops/native/native.sh stop
	$(if $(SERVICES),$(COMPOSE) down -v --remove-orphans)
	@$(MAKE) --no-print-directory up
