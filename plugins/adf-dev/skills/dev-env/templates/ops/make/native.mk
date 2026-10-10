# DEV_MODE=native: the app on the host, with the stack's own dev command, against its backing
# services in Docker. The root Makefile loads this file in that mode.

# CUSTOMIZE: the backing services that run in Docker — empty when they all run on the host
SERVICES ?= redis
# CUSTOMIZE: the app's dev command, listening on $APP_PORT — e.g. npm run dev -- --port "$$APP_PORT"
NATIVE_CMD = echo "CUSTOMIZE: set NATIVE_CMD in ops/make/native.mk to the app's dev command" >&2; exit 1

export NATIVE_CMD
NATIVE_SH = $(PORTS_SH:ports.sh=native.sh)

.PHONY: up down build ps logs urls services test lint reset

up: env guard services ## Start the app on the host, wait until it answers, and show where it is
	@$(COMPOSE) stop $(APP) >/dev/null 2>&1 || true
	@$(NATIVE_SH) start
	@$(PORTS_SH) urls

down: guard ## Stop the app and the backing services; their data stays
	@ops/scripts/native.sh stop
	$(if $(SERVICES),$(COMPOSE) down)

build: env ## Install the app's dependencies on the host
	@echo "CUSTOMIZE: the install command, e.g. npm ci · composer install · bundle install" >&2; exit 1

ps: ## The app on the host, and the backing services
	@APP='$(APP)' ops/scripts/native.sh status
	$(if $(SERVICES),$(COMPOSE) ps)

logs: ## The last 100 lines of the app's log, and of each service's: make logs s=redis
	$(if $(s),,@ops/scripts/native.sh logs)
	$(if $(SERVICES),$(COMPOSE) logs --tail 100 --no-color $(s))

urls: ## Where the app and each backing service are now
	@$(PORTS_SH) urls

services: env guard ## Start only the backing services in Docker
	$(if $(SERVICES),$(COMPOSE) up -d --wait $(SERVICES),@echo "No backing services in Docker")

test: services ## Run the tests on the host, with the services' ports exported
	@eval "$$($(PORTS_SH) env)" && echo "CUSTOMIZE: the test command after the exports, e.g. npm test" >&2 && exit 1

lint: ## Run the linters on the host
	@echo "CUSTOMIZE: the lint command, e.g. npm run lint" >&2; exit 1

reset: env guard ## DESTRUCTIVE: delete the services' containers and volumes, then start again
	@ops/scripts/native.sh stop
	$(if $(SERVICES),$(COMPOSE) down -v --remove-orphans)
	@$(MAKE) --no-print-directory up
