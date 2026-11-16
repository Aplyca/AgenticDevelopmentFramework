# DEV_MODE=docker: the whole stack in Docker, and nothing on the host but Docker, git, and make. The
# root Makefile loads this file in that mode; this folder holds everything the target needs — the
# images and service config (ops/docker/<service>/), guard.sh, which keeps a worktree off the main
# checkout's stack, and launch-json.sh, which lists the running web services in Claude Desktop's
# Browser.

# Loaded by the root Makefile, never run on its own: its settings and paths are the root's.
ifndef MODE_FILE
$(error run make from the repository root: this file is the $(notdir $(CURDIR)) mode, which the root Makefile loads)
endif

.PHONY: up stop down build deps ps logs urls prod shell test lint format typecheck run reset

up: env guard ## Start the stack, wait until it's healthy, and show where it is
	@APP='$(APP)' COMPOSE='$(COMPOSE)' ops/native/native.sh stop
	$(COMPOSE) up -d --wait
	@$(LAUNCH_JSON)
	@$(MAKE) --no-print-directory urls

stop: guard ## Stop the stack, the production build too, to free memory and CPU; its containers and data stay, and make up starts it again
	$(COMPOSE) --profile prod stop
	@$(LAUNCH_JSON)

down: guard ## Stop the stack, the production build too, and remove its containers and networks; its data stays
	$(COMPOSE) --profile prod down
	@$(LAUNCH_JSON)

build: env ## Rebuild the images, the tools' too, then bring this checkout's dependencies up to date
	$(COMPOSE) --profile tools build
	@$(MAKE) --no-print-directory deps

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

# The tools service (compose.yaml, D6): deps, test, lint, format, typecheck, and run each start a
# container of their own over the whole checkout, removed when it ends, so the stack needn't be up
# and nothing runs on the host (M11). The ones that reach no backing service pass --no-deps.
deps: ## Install the dependencies from the lockfile into this checkout's volume, where the app and the tools read them
	@echo "CUSTOMIZE: the install command, from the lockfile, e.g. $(COMPOSE) run --rm --no-deps tools <install command>" >&2; exit 1

test: ## Run the tests in the tools container; t=<filter> runs only the matching ones; tier=<smoke|critical|regression>, suite=<name>
	@echo "CUSTOMIZE: the test command, with t as its filter, and tier and suite as the unit module's scripts and path (npm run test:$(tier) -- tests/$(suite)), e.g. $(COMPOSE) run --rm tools <test command> $(t)" >&2; exit 1

lint: ## Run the linters in the tools container; f=<files> lints only those
	@echo "CUSTOMIZE: the lint command, with f as its files, e.g. $(COMPOSE) run --rm --no-deps tools <lint command> $(f)" >&2; exit 1

format: ## Rewrite files to the project's formatting, in the tools container; f=<files> formats only those
	@echo "CUSTOMIZE: the format command, e.g. $(COMPOSE) run --rm --no-deps tools <format command> $(f) — or say the stack has no formatter" >&2; exit 1

typecheck: ## Run the type checker in the tools container
	@echo "CUSTOMIZE: the type checker, e.g. $(COMPOSE) run --rm --no-deps tools <type check command> — or say the stack has none" >&2; exit 1

# The command reaches the container's shell as one argument, from the environment (C10): never
# the make variable pasted into the recipe, where the host's shell would read its quotes.
run: ## Run a command in the tools container, for what no task covers: make run cmd='npm outdated' — a $ for the container is written $$
	@[ -n "$$cmd" ] || { echo "make run needs a command: make run cmd='<command>'" >&2; exit 1; }
	$(COMPOSE) run --rm tools sh -c "$$cmd"

reset: env guard ## DESTRUCTIVE: delete the stack's containers and volumes, then start it again
	$(COMPOSE) --profile prod down -v --remove-orphans
	@$(MAKE) --no-print-directory up
