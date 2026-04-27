---
# CUSTOMIZE: Update paths to match your project structure
paths:
  - "src/api/**"
  - "app/api/**"
  - "lib/**"
  - "src/lib/**"
---

# Observability Rules

## Error logging
- Catch all errors in API/server code. Never let unhandled exceptions reach the client.
- Log errors with context: function/endpoint name, input data shape, error message.
- Return generic messages to the client. Never expose stack traces or internal details.

## Frontend resilience
- Handle all fetch failures with `.catch()` or try/catch.
- Guard against unexpected API response shapes before using them.
- Silent degradation: if a non-critical call fails, show an empty state rather than crashing.

## Production readiness checklist
<!-- CUSTOMIZE: Check off what applies to your project -->
- [ ] Structured logging (JSON format, log levels, correlation IDs)
- [ ] Error tracking service (Sentry, Datadog, etc.)
- [ ] Health check endpoints for each service
- [ ] Monitoring dashboards for key metrics
- [ ] Alerting on critical failures
