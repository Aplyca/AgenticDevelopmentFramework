import { expect, test } from './fixtures';

// CUSTOMIZE: the newsletter site's home page, a critical flow: its smoke test proves the app answers
// and renders. The expected heading is the page's, written here, never read from the code.
test('the home page shows its heading', { tag: '@smoke' }, async ({ page }) => {
  await page.goto('/');

  await expect(page.getByRole('heading', { level: 1, name: 'The newsletter site' })).toBeVisible();
});
