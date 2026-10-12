# The end-to-end suite in Docker mode, so the host needs no Node: Playwright's official image, with
# its browsers, at the same version as @playwright/test in e2e/package.json — a different version
# can't find its browser. The suite is copied in, so `docker compose run --build e2e` tests the files
# as they are now, and only a change to the lockfile reinstalls the dependencies.

# CUSTOMIZE: the version — the same as @playwright/test's in e2e/package.json
FROM mcr.microsoft.com/playwright:v1.63.0-noble

WORKDIR /suite
COPY e2e/package.json e2e/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY e2e/ ./

ENTRYPOINT ["npx", "--no-install", "playwright", "test"]
