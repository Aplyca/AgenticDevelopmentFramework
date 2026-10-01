# Infrastructure Overview

<!-- owner: [team or person] · last_updated: [YYYY-MM-DD] · scope: hosting, environments, CI/CD, monitoring -->

## Architecture

[Describe the production infrastructure at a high level. Include a diagram if possible.]

```
[e.g.,
Users → CDN → Load Balancer → App Instances (PaaS) → Database (Managed)
                                    ↓
                              External Services
]
```

## Platform

| Component | Service | Provider | Tier/Plan |
|---|---|---|---|
| Application | [e.g., App Service, ECS, Cloud Run] | [e.g., Azure, AWS, GCP] | [e.g., Standard S1] |
| Database | [e.g., Azure Database for PostgreSQL] | [e.g., Azure] | [e.g., Flexible Server, GP] |
| Cache | [e.g., Azure Cache for Redis] | [e.g., Azure] | [e.g., Basic C0] |
| CDN | [e.g., Azure Front Door, CloudFront] | [e.g., Azure] | [e.g., Standard] |
| Storage | [e.g., Blob Storage, S3] | [e.g., Azure] | [e.g., Hot tier] |
| CI/CD | [e.g., GitHub Actions] | [GitHub] | [e.g., Team plan] |
| Monitoring | [e.g., Application Insights, Datadog] | [e.g., Azure] | [e.g., Standard] |

## Environments

| Environment | Purpose | URL | Branch | Auto-deploy? |
|---|---|---|---|---|
| Development | Local development | `localhost:[port]` | Any | No |
| Staging | Pre-production validation | [staging URL] | `main` | Yes |
| Production | Live | [production URL] | Release tag | Manual approval |

## Environment variables

[List all environment variables required by the application. Never include actual values — reference the secrets manager.]

| Variable | Description | Required | Source |
|---|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Yes | [e.g., Key Vault, SSM] |
| `REDIS_URL` | Redis connection string | Yes | [e.g., Key Vault, SSM] |
| `API_KEY` | External service API key | Yes | [e.g., Key Vault, SSM] |
| `NODE_ENV` | Runtime environment | Yes | Platform config |

## Networking

### Ingress
- [e.g., HTTPS only, TLS 1.2+, managed by platform]
- [e.g., Custom domain: app.example.com]
- [e.g., WAF enabled with OWASP ruleset]

### Internal communication
- [e.g., All services communicate over private network / VNet]
- [e.g., Database not accessible from public internet]

### Egress
- [e.g., Outbound traffic to external APIs via NAT gateway]
- [e.g., Allowed destinations: Stripe API, SendGrid, etc.]

## Scaling

| Component | Strategy | Min | Max | Trigger |
|---|---|---|---|---|
| App instances | [Auto-scale] | [2] | [10] | [CPU > 70%] |
| Database | [Vertical] | [2 vCores] | [8 vCores] | [Manual] |
| Cache | [Fixed] | [1 instance] | [1 instance] | [N/A] |

## CI/CD pipeline

```
Push to main
  → Run tests
  → Build container / artifact
  → Deploy to staging (auto)
  → Run smoke tests
  → Deploy to production (manual approval)
```

### Pipeline configuration
- [e.g., `.github/workflows/deploy.yml`]
- [e.g., Build: multi-stage Dockerfile]
- [e.g., Tests: run on port 3100, mock external services]

## Backups and disaster recovery

| What | Frequency | Retention | Recovery time target |
|---|---|---|---|
| Database | [e.g., Daily automated] | [e.g., 30 days] | [e.g., < 1 hour] |
| File storage | [e.g., Geo-redundant] | [e.g., 90 days] | [e.g., < 30 min] |
| Application config | [e.g., In version control] | [e.g., Git history] | [e.g., Minutes] |

## Monitoring and alerting

| Metric | Threshold | Alert channel |
|---|---|---|
| Error rate | [e.g., > 1% for 5 min] | [e.g., Slack #alerts, PagerDuty] |
| Response time (p95) | [e.g., > 2s for 5 min] | [e.g., Slack #alerts] |
| CPU usage | [e.g., > 85% for 10 min] | [e.g., Slack #infra] |
| Database connections | [e.g., > 80% pool] | [e.g., PagerDuty] |
| Disk usage | [e.g., > 85%] | [e.g., Slack #infra] |
| Uptime | [e.g., < 99.9% rolling 30d] | [e.g., PagerDuty] |

### Dashboards
- [e.g., Grafana: https://grafana.example.com/d/app-overview]
- [e.g., Application Insights: Azure portal link]

## Cost estimation

| Component | Monthly estimate | Notes |
|---|---|---|
| Compute | [e.g., $150] | [2 instances, Standard tier] |
| Database | [e.g., $100] | [Flexible Server, 2 vCores] |
| Storage | [e.g., $20] | [50 GB hot tier] |
| CDN | [e.g., $30] | [Based on estimated traffic] |
| Monitoring | [e.g., $50] | [Standard data ingestion] |
| **Total** | **[e.g., $350/month]** | |

## Runbooks

[Link to operational runbooks for common tasks.]

- [Deployment rollback — e.g. `docs/operations/rollback.md`]
- [Database recovery — e.g. `docs/operations/database-recovery.md`]
- [Scaling up — e.g. `docs/operations/scaling.md`]
- [Incident response — e.g. `docs/security/INCIDENT-RESPONSE.md`]
