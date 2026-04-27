# Architecture Overview

## System context

[What does this system do? Who are the users? What external systems does it interact with?]

## Key components

[List the major building blocks and their responsibilities.]

| Component | Responsibility | Technology |
|---|---|---|
| [e.g., Web App] | [User-facing interface] | [e.g., Next.js 15] |
| [e.g., API Layer] | [Business logic, service orchestration] | [e.g., Node.js API routes] |
| [e.g., Database] | [Persistent storage] | [e.g., PostgreSQL] |
| [e.g., External Service] | [Third-party integration] | [e.g., Stripe, Auth0] |

## Data flow

[Describe how data moves through the system. Include a diagram if possible.]

```
[User] → [Frontend] → [API] → [Database]
                         ↓
                   [External Service]
```

## Technology stack

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | [e.g., React 19] | [Why this choice?] |
| Backend | [e.g., Next.js API routes] | [Why this choice?] |
| Database | [e.g., PostgreSQL 16] | [Why this choice?] |
| Infrastructure | [e.g., AWS ECS on Fargate] | [Why this choice?] |
| CI/CD | [e.g., GitHub Actions] | [Why this choice?] |

For detailed rationale on individual decisions, see [Architecture Decision Records](architecture/decisions/).

## Non-functional requirements

| Requirement | Target | Notes |
|---|---|---|
| Availability | [e.g., 99.9%] | [SLA context] |
| Response time | [e.g., p95 < 500ms] | [For which endpoints?] |
| Scalability | [e.g., 10K concurrent users] | [Growth projections] |
| Data retention | [e.g., 7 years] | [Regulatory requirement?] |

## Constraints and assumptions

- [e.g., Must deploy to AWS (organizational mandate)]
- [e.g., No PII stored outside EU (GDPR)]
- [e.g., Team has 3 backend engineers, 2 frontend]
- [e.g., Must integrate with existing auth provider]

## Key architectural decisions

[Link to the most important ADRs that shape this system.]

- [ADR-0001: Choice of framework](architecture/decisions/0001-framework.md)
- [ADR-0002: Database selection](architecture/decisions/0002-database.md)
- [ADR-0003: Deployment platform](architecture/decisions/0003-deployment-platform.md)

## Diagrams

[Include or link to architecture diagrams. Use C4 model levels for structure:]

- **Context diagram** — the system and its environment (users, external systems)
- **Container diagram** — the applications, databases, and services that compose the system
- **Component diagram** — internal structure of a specific container (only if complex)

[Use Mermaid, PlantUML, or SVG files in `docs/architecture/diagrams/`.]
