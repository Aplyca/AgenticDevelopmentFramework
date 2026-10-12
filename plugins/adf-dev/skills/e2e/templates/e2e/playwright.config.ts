import { defineConfig, devices } from '@playwright/test';

// The suite tests the stack this checkout already runs: `make e2e` starts it and sets E2E_BASE_URL.
// The suite never starts a server of its own, so two checkouts' suites run side by side.
const baseURL = process.env.E2E_BASE_URL;
if (!baseURL) {
  throw new Error(
    'E2E_BASE_URL is not set: run the suite with `make e2e` or `make smoke`, which start the stack and point the tests at it',
  );
}
const ci = !!process.env.CI;

export default defineConfig({
  testDir: '.',
  testMatch: '**/*.spec.ts',
  fullyParallel: true,
  forbidOnly: ci,
  // None locally: a test that needs a retry is flaky, and gets fixed. CI's retries capture the trace.
  retries: ci ? 2 : 0,
  reporter: ci ? [['line'], ['html', { open: 'never' }]] : 'line',
  outputDir: 'test-results',
  use: {
    baseURL,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  // CUSTOMIZE: another browser only when the spec's Compatibility section asks for it
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
