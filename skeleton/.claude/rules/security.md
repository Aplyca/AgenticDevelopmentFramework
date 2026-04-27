---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.py"
  - "**/*.go"
  - "**/*.rs"
---

# Security Rules

## Non-negotiable

1. **No injection vulnerabilities** — never interpolate user input into HTML, SQL, shell commands, HTTP headers, or file paths without proper escaping or parameterization.
2. **No credentials in client code** — API keys, passwords, tokens, and service URLs stay in environment variables, accessed only in server-side code. Never expose them to the browser or client.
3. **No secrets in git** — `.env`, `.env.local`, credential files, and private keys must be in `.gitignore`. Never commit real passwords or API keys.
4. **Validate at system boundaries** — API endpoints must validate incoming request data (required fields, types, bounds) before processing. Client-side validation is for UX, not security.

## API endpoints
- Check HTTP method or use the appropriate handler export.
- Return 400 for missing/invalid input, not 500.
- Don't expose internal error details (stack traces, database errors, service messages) to the client. Log them server-side, return a generic message.

## Client-side code
- Use the framework's safe rendering (React JSX, Vue templates, Angular bindings). Avoid raw HTML injection with user-provided data.
- Don't store sensitive data in client storage (localStorage, sessionStorage, cookies without httpOnly).

## Dependencies
- Review new dependencies before adding. Check: actively maintained? Known vulnerabilities? Widely used?
- Run your language's audit tool periodically (`npm audit`, `pip audit`, `go vet`, etc.). Address high/critical vulnerabilities.
