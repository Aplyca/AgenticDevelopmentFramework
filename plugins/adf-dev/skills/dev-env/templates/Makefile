
# The local environment's tasks: one command surface for people and agents. `make` lists them.
# What both modes share is here. ops/ holds one folder per target, and each local mode's tasks are
# in ops/<mode>/Makefile; the mode in force loads its file. Docker Compose reads .env itself; this
# file reads only DEV_MODE from it, and never loads or exports the rest. Works with GNU make 3.81
# (macOS) and later.

COMPOSE ?= docker compose
# CUSTOMIZE: where the app runs unless a checkout's .env says otherwise — docker (ops/docker/Makefile)
# or native (ops/native/Makefile)
DEFAULT_MODE = docker
# CUSTOMIZE: the app's service, and each published port, as <variable>=<service>:<container port>
APP ?= web
PORTS ?= APP_PORT=web:3000 REDIS_PORT=redis:6379

# The mode: `make up DEV_MODE=native`, then the shell's DEV_MODE, then .env's, then DEFAULT_MODE.
ifeq ($(origin DEV_MODE),undefined)
DEV_MODE := $(shell sed -n 's/^DEV_MODE=\([^\#]*\).*/\1/p' .env 2>/dev/null | tail -n 1 | tr -d "\"' ")
endif
override DEV_MODE := $(or $(strip $(DEV_MODE)),$(DEFAULT_MODE))
MODE_FILE = ops/$(DEV_MODE)/Makefile
ifeq ($(wildcard $(MODE_FILE)),)
$(error DEV_MODE is '$(DEV_MODE)', and there's no $(MODE_FILE), so it isn't a local mode: set DEV_MODE in .env to docker or native)
endif

PORTS_SH = PORTS='$(PORTS)' APP='$(APP)' COMPOSE='$(COMPOSE)' DEV_MODE='$(DEV_MODE)' ops/docker/ports.sh

.DEFAULT_GOAL := help
.PHONY: help env guard

help: ## List the tasks
	@echo "Mode: $(DEV_MODE) ($(MODE_FILE)) — DEV_MODE in .env sets it; the default is $(DEFAULT_MODE)"
	@awk 'BEGIN { FS = ":.*## " } /^[a-z][a-z-]*:.*## / { printf "  make %-9s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

env: ## Create .env from .env.example, if it's missing
	@if [ -f .env ]; then echo ".env is there; left as it is"; \
	else cp .env.example .env && chmod 600 .env && echo "Created .env from .env.example: fill in the credentials it names"; fi

guard:
	@$(PORTS_SH) guard

include $(MODE_FILE)
