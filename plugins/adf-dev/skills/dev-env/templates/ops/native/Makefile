# DEV_MODE=native: the app on the host, with the stack's own dev command, against its backing
# services in Docker. The root Makefile loads this file in that mode; native.sh, beside it, runs the
# app in the background, and .run/ (ignored by git) keeps its process, port, and log.

# Loaded by the root Makefile, never run on its own: its settings and paths are the root's.
ifndef MODE_FILE
$(error run make from the repository root: this file is the $(notdir $(CURDIR)) mode, which the root Makefile loads)
endif

# CUSTOMIZE: the backing services that stay in Docker — the project's default. A developer who runs
# some on the host sets their own list in .env (SERVICES=postgres), or SERVICES=none for all of them.
DEFAULT_SERVICES = redis
# Which ones run here: `make up SERVICES=…`, then the shell's SERVICES, then .env's, then the default.
ifeq ($(origin SERVICES),undefined)
SERVICES := $(call env_value,SERVICES)
endif
override SERVICES := $(filter-out none,$(or $(strip $(SERVICES)),$(DEFAULT_SERVICES)))
# CUSTOMIZE: the app's dev command, listening on $APP_PORT — e.g. npm run dev -- --port "$$APP_PORT"
NATIVE_CMD = echo "CUSTOMIZE: set NATIVE_CMD in ops/native/Makefile to the app's dev command" >&2; exit 1
# CUSTOMIZE (optional, for make prod): the production build and server, listening on $APP_PORT —
# e.g. npm run build && npm start -- --port "$$APP_PORT". Delete it with the prod task if there's none.
NATIVE_PROD_CMD = echo "CUSTOMIZE: set NATIVE_PROD_CMD in ops/native/Makefile to the production build and server" >&2; exit 1

export NATIVE_CMD NATIVE_PROD_CMD
NATIVE_SH = SERVICES='$(SERVICES)' COMPOSE='$(COMPOSE)' APP='$(APP)' ops/native/native.sh

.PHONY: up down build ps logs urls prod services test lint format typecheck reset

up: env guard services ## Start the app on the host, wait until it answers, and show where it is
	@$(COMPOSE) stop $(APP) >/dev/null 2>&1 || true
	@$(NATIVE_SH) start
	@$(MAKE) --no-print-directory urls

down: guard ## Stop the app and the backing services; their data stays
	@$(NATIVE_SH) stop
	$(if $(SERVICES),$(COMPOSE) down)
	@$(LAUNCH_JSON)

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

# Optional (C11): delete it, with NATIVE_PROD_CMD, if the project has no production-like run. The
# build runs before the server answers, so it gets longer than the dev server to start.
prod: env guard services ## Build the app for production and serve it on the host in place of the dev server, until make up
	@$(COMPOSE) stop $(APP) >/dev/null 2>&1 || true
	@READY_SECONDS=600 $(NATIVE_SH) start prod
	@$(MAKE) --no-print-directory urls

services: env guard ## Start only the backing services in Docker
	$(if $(SERVICES),$(COMPOSE) up -d --wait $(SERVICES),@echo "No backing services in Docker")
	@$(LAUNCH_JSON)

test: services ## Run the tests on the host, with the services' ports exported; t=<filter> runs only the matching ones
	@eval "$$($(NATIVE_SH) env)" && echo "CUSTOMIZE: the test command after the exports, with t as its filter, e.g. npm test -- $(t)" >&2 && exit 1

lint: ## Run the linters on the host; f=<files> lints only those
	@echo "CUSTOMIZE: the lint command, with f as its files, e.g. npx eslint $(or $(f),.)" >&2; exit 1

format: ## Rewrite files to the project's formatting, on the host; f=<files> formats only those
	@echo "CUSTOMIZE: the format command, e.g. npx prettier --write $(or $(f),.) — or say the stack has no formatter" >&2; exit 1

typecheck: ## Run the type checker on the host
	@echo "CUSTOMIZE: the type checker, e.g. npx tsc --noEmit — or say the stack has none" >&2; exit 1

reset: env guard ## DESTRUCTIVE: delete the services' containers and volumes, then start again
	@$(NATIVE_SH) stop
	$(if $(SERVICES),$(COMPOSE) down -v --remove-orphans)
	@$(MAKE) --no-print-directory up
