# Input — write-tests reads from multiple spec sections

This fixture verifies that `/write-tests` derives test scope from MORE than just Functional ACs — specifically, from testable requirements in Security, Accessibility, Performance.

## Setup

Assume `specs/contact-form.md` is committed. Its content (paste this into the file before running, or treat it as the spec the AI is told to read):

```
---
title: "Contact form on homepage"
area: "marketing"
status: approved
feature-type: ui
personal-data: yes
---

## Functional [REQUIRED]
### Acceptance criteria
1. Visitor sees the contact form on the homepage with name, email, and message fields.
2. Submitting a valid form shows a success message.
3. Submitting with empty required fields shows inline errors.

### Edge cases
- Email field is malformed → inline error
- Message exceeds 5000 characters → inline error

## Out of scope [REQUIRED]
- File attachments (out of scope this iteration)

## Accessibility [REQUIRED if UI]
- All form inputs have programmatically associated labels
- Inline errors use role="alert"
- Form is fully keyboard-navigable in tab order: name → email → message → submit
- Touch targets ≥44×44px on mobile

## Security [REQUIRED]
- reCAPTCHA v3 protects the form; submissions with score <0.5 are rejected
- Rate limit: 5 submissions per IP per hour
- Server-side validation rejects payloads exceeding 10KB

## Privacy [REQUIRED]
- Email and name stored in Salesforce (US region, existing DPA)
- IP stored in Vercel KV with 1-hour TTL for rate limiting only

## Performance [optional — non-default]
- Form submission API responds in <500ms p95 (excluding reCAPTCHA verification)

## Testing [REQUIRED]
### Mandatory test scope
- Every functional AC has at least one E2E test
- Email validator has unit tests
- Server-side validation tested with crafted payloads

### Additional test types beyond ACs
- Automated axe scan in E2E for the form page
- Manual screen-reader pass before merge
```

## Prompt to give the AI

```
/write-tests contact-form
```

## What to do with this fixture

1. Ensure the spec above is in `specs/contact-form.md`.
2. Run the prompt with the framework loaded.
3. Capture the AI's test plan (Phase 1 output, before any tests are written).
4. Compare against `tests-from-spec.expected.md`.
