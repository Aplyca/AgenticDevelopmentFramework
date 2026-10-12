# The end-to-end tasks for Docker mode: add them to ops/docker/Makefile, and `e2e smoke` to its
# .PHONY line. The suite runs in the e2e service (compose.yaml), against this checkout's stack.

e2e: up ## Run the end-to-end tests against the stack: make e2e t=<file filter> g=<title filter>
	@mkdir -p e2e/test-results e2e/playwright-report
	$(COMPOSE) --progress quiet run --rm --build $(if $(CI),-e CI) e2e $(t) $(if $(g),--grep "$(g)")

smoke: up ## Run the smoke tests: one per critical flow
	@mkdir -p e2e/test-results e2e/playwright-report
	$(COMPOSE) --progress quiet run --rm --build $(if $(CI),-e CI) e2e --grep @smoke
