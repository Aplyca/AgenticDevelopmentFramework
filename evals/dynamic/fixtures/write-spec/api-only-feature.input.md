# Input — write-spec for an API-only feature (no UI, no personal data)

This fixture verifies that `/write-spec`:
- Classifies a backend-only feature as `feature-type: api` and `personal-data: no`
- Correctly marks Accessibility as Not applicable (no UI)
- Correctly marks Privacy as Not applicable (no personal data)
- Doesn't bloat the spec with sections that don't apply

## Prompt to give the AI

```
/write-spec

We need an internal API endpoint /api/health/contentful that returns whether
our Contentful Delivery API is reachable. Returns 200 with JSON
{"status": "ok"} if Contentful responds within 2 seconds, 503 with
{"status": "down", "reason": "..."} otherwise. Used by our uptime monitor
(Pingdom) — no UI, no auth needed, no personal data.
```

## What to do with this fixture

1. Paste the prompt into your AI tool.
2. Capture the AI's full output.
3. Compare against `api-only-feature.expected.md` invariants.
