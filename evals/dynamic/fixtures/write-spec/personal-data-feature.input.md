# Input — write-spec for a personal-data-collecting UI feature

This fixture verifies that `/write-spec` correctly:
- Classifies a UI feature collecting email as `feature-type: ui` and `personal-data: yes`
- Triggers the conditional Accessibility (UI) and Privacy (personal data) requirements
- Refuses to mark approved if those sections are empty

## Setup

Assume the project's `specs/` directory exists with `README.md` and the `_templates/` (`spec.md`, `plan.md`, `tasks.md`) from the framework.

## Prompt to give the AI

```
/write-spec

Marketing wants a contact form on the homepage. Visitors enter their name,
email, and a free-text message. Submissions go to our CRM (Salesforce). The
form should A/B test its headline copy via Contentful.
```

## What to do with this fixture

1. Paste the prompt into your AI tool with the framework loaded.
2. Capture the AI's full output (the spec it drafts + any clarifying questions).
3. Compare against `personal-data-feature.expected.md` invariants.
