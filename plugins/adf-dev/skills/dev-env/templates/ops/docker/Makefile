# DEV_MODE=docker: the whole stack in Docker. The root Makefile loads this file in that mode; this
# folder holds everything the target needs — the images and service config (ops/docker/<service>/)
# and guard.sh, which keeps a worktree off the main checkout's stack.

# Loaded by the root Makefile, never run on its own: its settings and paths are the root's.
ifndef MODE_FILE
$(error run make from the repository root: this file is the $(notdir $(CURDIR)) mode, which the root Makefile loads)
endif

.PHONY: up down build ps logs urls shell test lint format typecheck reset

up: env guard ## Start the stack, wait until it's healthy, and show where it is
	@ops/native/native.sh stop
	$(COMPOSE) up -d --wait
	@$(MAKE) --no-print-directory urls

down: guard ## Stop the stack; its data stays
	$(COMPOSE) down

build: env ## Rebuild the images
	$(COMPOSE) build

ps: ## The services, their state, and their health
	$(COMPOSE) ps

logs: ## The last 100 lines of every service's log, or one service's: make logs s=web
	$(COMPOSE) logs --tail 100 --no-color $(s)

urls: ## Where each service is now, and its health — Docker picks the ports .env doesn't pin
	@$(COMPOSE) ps --format 'table {{.Service}}\t{{.Ports}}\t{{.Status}}'
	@$(COMPOSE) ps $(APP) --format '{{range .Publishers}}{{if .PublishedPort}}The app: http://localhost:{{.PublishedPort}} {{end}}{{end}}'


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
	$(COMPOSE) down -v --remove-orphans
	@$(MAKE) --no-print-directory up
