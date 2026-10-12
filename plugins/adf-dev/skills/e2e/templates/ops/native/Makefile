# The end-to-end tasks for native mode: add them to ops/native/Makefile, and `e2e smoke` to its
# .PHONY line. The suite runs on the host, against the app on the port native.sh reports. Its
# `build` installs the suite's dependencies and its browser too — add this line to it:
#
#	npm ci --prefix e2e --no-audit --no-fund && cd e2e && npx --no-install playwright install chromium

E2E_RUN = [ -d e2e/node_modules ] || { echo "The suite's dependencies aren't installed: run make build" >&2; exit 1; }; \
	eval "$$($(NATIVE_SH) env)" && cd e2e && E2E_BASE_URL="http://localhost:$$APP_PORT" npx --no-install playwright test

e2e: up ## Run the end-to-end tests on the host, against the app: make e2e t=<file filter> g=<title filter>
	@$(E2E_RUN) $(t) $(if $(g),--grep "$(g)")

smoke: up ## Run the smoke tests on the host: one per critical flow
	@$(E2E_RUN) --grep @smoke
