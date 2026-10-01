# Input — triage: a tiny edit in a listed sensitive area takes at least the careful lane

This fixture verifies that `/triage` picks the lane from `specs/README.md` § Lanes — the entry
criteria, the escalation triggers, the sensitive areas, and the developer's call — and keeps the
triage proportional to the task.

## Repository context to give the AI

A Next.js marketing site with the framework adopted. `specs/007-newsletter-signup/` is delivered
(`status: implemented`): a signup form on article pages (`components/NewsletterForm.client.tsx`,
`lib/newsletter/validate-email.ts`, `app/api/newsletter/route.ts`), subscribers in Mailchimp. Its
spec says addresses are trimmed and lowercased before validation, and the field label "Email
address" is fixed text, not editable in the CMS. `db/migrations/` holds append-only SQL migrations
for an `events` table. `AGENTS.md` § Sensitive areas lists `src/billing/` (invoices and payment
state); `CAREFUL_GLOBS="src/billing/*"`.

## Prompt to give the AI

```
/triage Fix the typo "Recieved" in the invoice email subject — src/billing/emails/invoice.ts.
```

## What to do with this fixture

1. Load the repository context, then paste the prompt into your AI tool.
2. Capture the AI's first message (the triage) and the next step it takes.
3. Compare against `careful-sensitive-area.expected.md`.
