# Security

## Security principles

1. **Defense in depth** — no single control is sufficient. Layer security at network, application, and data levels.
2. **Least privilege** — services, users, and processes get only the permissions they need.
3. **Secure by default** — default configurations must be secure. Insecure options require explicit opt-in.
4. **Shift left** — address security during design and development, not after deployment.
5. **Assume breach** — design systems that limit blast radius when (not if) a component is compromised.

## Authentication and authorization

### Authentication
- [e.g., OAuth 2.0 / OpenID Connect via Auth0]
- [e.g., JWT tokens with RS256 signing]
- [e.g., Token expiry: access token 15min, refresh token 7 days]
- [e.g., MFA required for admin roles]

### Authorization
- [e.g., Role-based access control (RBAC)]
- [e.g., Roles: admin, editor, viewer]
- [e.g., Permissions checked at API layer, not frontend only]

| Role | Permissions |
|---|---|
| [Admin] | [Full access, user management, configuration] |
| [Editor] | [Create, read, update own resources] |
| [Viewer] | [Read-only access] |

## Data protection

### Data classification

| Classification | Description | Examples | Controls |
|---|---|---|---|
| **Confidential** | Business-critical, legally protected | Passwords, API keys, PII | Encrypted at rest + transit, access logged |
| **Internal** | Not public, but not regulated | Internal metrics, user preferences | Encrypted in transit, access controlled |
| **Public** | Intended for public access | Marketing content, public APIs | Integrity protection |

### Encryption

- **In transit:** [e.g., TLS 1.2+ for all connections, HSTS enabled]
- **At rest:** [e.g., AES-256 for database, managed keys via Key Vault/KMS]
- **Secrets:** [e.g., Stored in Azure Key Vault / AWS Secrets Manager, never in code or environment files]

### PII handling
- [e.g., Collected: email, name, company name]
- [e.g., Not collected: payment information, government IDs]
- [e.g., Retention: deleted 30 days after account closure]
- [e.g., Access: only via API with auth, logged in audit trail]

## Application security

### Input validation
- All user input validated at API boundaries (type, format, length, range)
- Frontend validation is for UX only — never trust it for security
- Parameterized queries for all database operations (no string interpolation)
- File uploads validated for type, size, and content (not just extension)

### Output encoding
- Use framework's safe rendering (React JSX, Vue templates, etc.)
- Never use `dangerouslySetInnerHTML` or equivalent with user data
- API responses never include stack traces, internal errors, or system paths
- Error messages are generic and user-friendly

### Session management
- [e.g., Stateless JWT tokens, no server-side sessions]
- [e.g., Tokens stored in httpOnly, Secure, SameSite cookies]
- [e.g., CSRF protection via SameSite cookies + origin header validation]

### Headers
- [e.g., Content-Security-Policy: default-src 'self']
- [e.g., X-Frame-Options: DENY]
- [e.g., X-Content-Type-Options: nosniff]
- [e.g., Strict-Transport-Security: max-age=31536000]

## Dependency security

- Review new dependencies before adding (maintained? known vulns? trusted?)
- Run `[npm audit / pip audit / go vet]` in CI and before releases
- Automated dependency updates via [e.g., Dependabot, Renovate]
- Critical vulnerabilities block the CI pipeline

## Secrets management

### Rules
- **Never** commit secrets to git (passwords, API keys, tokens, certificates)
- **Never** log secrets (mask in log output)
- **Never** pass secrets via URL query parameters
- **Always** use environment variables or a secrets manager
- **Always** rotate secrets on suspected compromise

### Secret storage

| Secret type | Storage | Rotation |
|---|---|---|
| Database credentials | [e.g., Key Vault] | [e.g., Quarterly] |
| API keys | [e.g., Key Vault] | [e.g., Annually] |
| JWT signing keys | [e.g., Key Vault] | [e.g., Annually] |
| TLS certificates | [e.g., Managed by platform] | [e.g., Auto-renewed] |

## Threat model

### STRIDE analysis

[For each major component, identify threats using the STRIDE framework.]

| Component | Threat type | Threat | Mitigation |
|---|---|---|---|
| [API endpoints] | Spoofing | [Attacker impersonates user] | [JWT validation, token expiry] |
| [API endpoints] | Tampering | [Attacker modifies request] | [Input validation, HTTPS] |
| [Database] | Information Disclosure | [Data leaked via error messages] | [Generic error responses, access control] |
| [Frontend] | Tampering | [XSS injection] | [React JSX escaping, CSP headers] |
| [Auth service] | Elevation of Privilege | [User gains admin access] | [RBAC, server-side permission checks] |
| [File uploads] | Denial of Service | [Large file exhausts storage] | [Size limits, rate limiting] |

### Attack surface

- [e.g., Public API endpoints: /api/auth/*, /api/public/*]
- [e.g., Admin endpoints: /api/admin/* (requires admin role)]
- [e.g., File upload: /api/upload (size limited, type validated)]
- [e.g., Webhooks: /api/webhooks/* (signature validated)]

## Compliance

[List applicable regulations and standards. Remove what doesn't apply.]

| Standard | Applicability | Status | Notes |
|---|---|---|---|
| GDPR | [e.g., Yes — EU users] | [e.g., In progress] | [Privacy policy, data deletion] |
| SOC 2 | [e.g., Not yet] | [e.g., Planned] | [Needed for enterprise clients] |
| HIPAA | [e.g., No] | [N/A] | [No health data processed] |
| PCI DSS | [e.g., No] | [N/A] | [No payment processing] |
| OWASP Top 10 | [e.g., Yes] | [e.g., Addressed] | [See application security section] |

## Incident response

### Severity levels

| Level | Description | Response time | Example |
|---|---|---|---|
| **Critical** | Active exploitation, data breach | Immediate | Unauthorized data access |
| **High** | Exploitable vulnerability found | < 4 hours | SQL injection in production |
| **Medium** | Vulnerability with limited exposure | < 24 hours | XSS in admin panel |
| **Low** | Minor issue, no immediate risk | < 1 week | Outdated dependency with no exploit |

### Response process

1. **Detect** — monitoring alert, bug report, or security researcher notification
2. **Assess** — determine severity, scope, and impact
3. **Contain** — stop the bleeding (disable endpoint, revoke credentials, block IP)
4. **Investigate** — root cause analysis, determine what was accessed
5. **Remediate** — fix the vulnerability, deploy patch
6. **Recover** — restore normal operations, verify fix
7. **Post-mortem** — document what happened, what we learned, and what we'll improve

### Contacts

| Role | Contact | Escalation |
|---|---|---|
| Security lead | [name, email, phone] | [First responder] |
| Engineering lead | [name, email, phone] | [If security lead unavailable] |
| Legal | [name, email] | [For data breach notification] |

## Security checklist for new features

Before merging any feature, verify:

- [ ] Input validated at API boundaries (type, format, length)
- [ ] No user input in SQL, shell commands, or HTML without escaping
- [ ] No secrets in code, logs, or client-side storage
- [ ] Authentication required for protected endpoints
- [ ] Authorization checked server-side (not just frontend)
- [ ] Error messages don't expose internals
- [ ] Dependencies checked for known vulnerabilities
- [ ] HTTPS used for all external communication
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Rate limiting on authentication and public endpoints
