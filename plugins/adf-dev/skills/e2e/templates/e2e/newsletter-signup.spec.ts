import { expect, test } from './fixtures';

// CUSTOMIZE: the newsletter signup — a critical flow, with its smoke test, and an edge case beside it.
test.describe('newsletter signup', () => {
  test('a valid signup replaces the form with the success message', { tag: '@smoke' }, async ({ page, uniqueId }) => {
    await page.goto('/');

    await page.getByLabel('Email address').fill(`signup+${uniqueId}@example.com`);
    await page.getByRole('button', { name: 'Subscribe' }).click();

    await expect(page.getByRole('status')).toBeVisible();
    await expect(page.getByLabel('Email address')).toBeHidden();
  });

  test('an invalid address shows the inline error and keeps the form', async ({ page }) => {
    await page.goto('/');

    await page.getByLabel('Email address').fill('reader@');
    await page.getByRole('button', { name: 'Subscribe' }).click();

    await expect(page.getByRole('alert')).toHaveText('Enter a valid email address.');
    await expect(page.getByLabel('Email address')).toBeFocused();
  });
});
