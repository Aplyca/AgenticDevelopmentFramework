import { randomUUID } from 'node:crypto';
import { test as base, expect } from '@playwright/test';

// Every test imports test and expect from here, so what tests share is defined once.
export const test = base.extend<{ uniqueId: string }>({
  // A value no other test uses, for the data a test creates: `signup+${uniqueId}@example.com`. The
  // stack is the developer's own, so a test never relies on data it didn't create.
  uniqueId: async ({}, use) => {
    await use(randomUUID().slice(0, 8));
  },

  // CUSTOMIZE: stub each third party the browser calls, so no test reaches a real one, e.g.:
  // page: async ({ page }, use) => {
  //   await page.route('https://plausible.io/**', (route) => route.fulfill({ status: 202 }));
  //   await use(page);
  // },
});

export { expect };
