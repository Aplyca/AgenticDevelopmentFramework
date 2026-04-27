---
# CUSTOMIZE: Update paths to match your project structure
paths:
  - "src/**"
  - "app/**"
  - "lib/**"
  - "components/**"
---

# Architecture Rules

<!-- CUSTOMIZE: Replace this section with your project's layer structure -->

## Layers

| Layer | Location | Responsibility |
|---|---|---|
| Pages / Views | `app/` or `src/pages/` | UI rendering, user interaction, client-side state |
| API / Routes | `app/api/` or `src/api/` | HTTP endpoints, external service integration |
| Components | `components/` or `src/components/` | Reusable UI components shared across pages |
| Libraries | `lib/` or `src/lib/` | Server-side utilities, clients, helpers |

## Component guidelines
- Shared components go in the components directory. Page-specific logic stays in the page file.
- Extract a component only when used in more than one place, or when a file exceeds ~300 lines.
- Components receive data via props. Avoid global state unless the project explicitly adopts a state management pattern.

## API / endpoint guidelines
- API endpoints are the system boundary. All input validation happens here.
- Always return proper HTTP status codes and consistent response shapes.
- Never expose internal error details to the client.

## Data flow
<!-- CUSTOMIZE: Document your project's data flow -->
```
Client → API Endpoint → External Service / Database
```
- Client code never calls external services directly.
- Credentials and secrets stay in server-side code.

## Dependencies
- Minimize external dependencies. Every new package should earn its place.
- Before adding a dependency: is it actively maintained? Does it solve a problem you can't reasonably solve yourself?
