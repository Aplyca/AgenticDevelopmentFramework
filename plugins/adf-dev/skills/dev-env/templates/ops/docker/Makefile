# DEV_MODE=docker: the whole stack in Docker. The root Makefile loads this file in that mode; this
# folder holds everything the target needs — the images and service config (ops/docker/<service>/)
# and ports.sh, which finds the ports Docker published.

# Loaded by the root Makefile, never run on its own: its settings and paths are the root's.
ifndef MODE_FILE
$(error run make from the repository root: this file is the $(notdir $(CURDIR)) mode, which the root Makefile loads)
endif

.PHONY: up down build ps logs urls shell test lint reset

up: env guard ## Start the stack, wait until it's healthy, and show where it is
	@ops/native/native.sh stop
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

test: ## Run the tests in the app's container
	@echo "CUSTOMIZE: the test command, e.g. $(COMPOSE) exec -T $(APP) <test command>" >&2; exit 1

lint: ## Run the linters in the app's container
	@echo "CUSTOMIZE: the lint command, e.g. $(COMPOSE) exec -T $(APP) <lint command>" >&2; exit 1

reset: env guard ## DESTRUCTIVE: delete the stack's containers and volumes, then start it again
	$(COMPOSE) down -v --remove-orphans
	@$(MAKE) --no-print-directory up
