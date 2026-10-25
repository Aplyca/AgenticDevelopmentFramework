# DEV_MODE=docker: the whole stack in Docker. The root Makefile loads this file in that mode; this
# folder holds everything the target needs — the images and service config (ops/docker/<service>/),
# guard.sh, which keeps a worktree off the main checkout's stack, and launch-json.sh, which lists the
# running web services in Claude Desktop's Browser.

# Loaded by the root Makefile, never run on its own: its settings and paths are the root's.
ifndef MODE_FILE
$(error run make from the repository root: this file is the $(notdir $(CURDIR)) mode, which the root Makefile loads)
endif

.PHONY: up down build ps logs urls prod shell test lint format typecheck reset

up: env guard ## Start the stack, wait until it's healthy, and show where it is
	@APP='$(APP)' COMPOSE='$(COMPOSE)' ops/native/native.sh stop
	$(COMPOSE) up -d --wait
	@$(LAUNCH_JSON)
	@$(MAKE) --no-print-directory urls

down: guard ## Stop the stack, the production build too; its data stays
	$(COMPOSE) --profile prod down
	@$(LAUNCH_JSON)

build: env ## Rebuild the images
	$(COMPOSE) build

ps: ## The services, their state, and their health
	$(COMPOSE) ps

logs: ## The last 100 lines of every service's log, or one service's: make logs s=web
	$(COMPOSE) logs --tail 100 --no-color $(s)

urls: ## Where each service is now, and its health — Docker picks the ports .env doesn't pin
	@$(COMPOSE) ps --format 'table {{.Service}}\t{{.Ports}}\t{{.Status}}'
	@$(COMPOSE) ps $(APP) --format '{{range .Publishers}}{{if .PublishedPort}}The app: http://localhost:{{.PublishedPort}} {{end}}{{end}}'
	@$(COMPOSE) ps $(APP)-prod --format '{{range .Publishers}}{{if .PublishedPort}}The production build: http://localhost:{{.PublishedPort}} {{end}}{{end}}' 2>/dev/null || true

# Optional (C11): delete it, with the $(APP)-prod service and the Dockerfile's prod stage, if the
# project has no production-like run.
prod: env guard ## Build the app for production and serve it beside the dev server, then show where; make logs s=web-prod
	$(COMPOSE) --profile prod up -d --build --wait $(APP)-prod
	@$(LAUNCH_JSON)
	@$(MAKE) --no-print-directory urls

shell: ## A shell in the app's container, for people
	$(COMPOSE) exec $(APP) sh

test: ## Run the tests in the app's container; t=<filter> runs only the matching ones
	@echo "CUSTOMIZE: the test command, with t as its filter, e.g. $(COMPOSE) exec -T $(APP) <test command> $(t)" >&2; exit 1

lint: ## Run the linters in the app's container; f=<files> lints only those
	@echo "CUSTOMIZE: the lint command, with f as its files, e.g. $(COMPOSE) exec -T $(APP) <lint command> $(f)" >&2; exit 1

format: ## Rewrite files to the project's formatting, in the app's container; f=<files> formats only those
	@echo "CUSTOMIZE: the format command, e.g. $(COMPOSE) exec -T $(APP) <format command> $(f) — or say the stack has no formatter" >&2; exit 1

typecheck: ## Run the type checker in the app's container
	@echo "CUSTOMIZE: the type checker, e.g. $(COMPOSE) exec -T $(APP) <type check command> — or say the stack has none" >&2; exit 1

reset: env guard ## DESTRUCTIVE: delete the stack's containers and volumes, then start it again
	$(COMPOSE) --profile prod down -v --remove-orphans
	@$(MAKE) --no-print-directory up
