---
# CUSTOMIZE: Update paths to match your project's infra files
paths:
  - "docker-compose.yml"
  - "docker-compose.yaml"
  - "Dockerfile"
  - "Makefile"
  - ".github/**"
  - "infra/**"
---

# Deployment Rules

## Environments
<!-- CUSTOMIZE: Define your project's environments -->

| Environment | Purpose | Setup |
|---|---|---|
| Local | Development | `make dev` or equivalent |
| Test | Automated tests | Dedicated port, mock services |
| Staging | Pre-production validation | Mirrors production config |
| Production | Live | Full infrastructure |

## Port assignments
<!-- CUSTOMIZE: List your port assignments -->
- Development server: port XXXX
- Test server: port YYYY (NEVER use the dev port for tests)
- Services: list each with its port

## Environment variables
- Never hard-code service URLs. Always use environment variables.
- Never commit `.env`, `.env.local`, or any file containing credentials.
- Document all required env vars in a `.env.example` file (with placeholder values, not real ones).

## Docker (if applicable)
- `docker-compose.yml` defines the full local stack.
- Volume-mount config files so changes persist without rebuilding.
- Use multi-stage builds for production images.

## CI/CD (if applicable)
- Tests must pass before merge.
- Use the same test configuration locally and in CI.
- Never skip hooks or checks in CI (`--no-verify`, `--force`).
