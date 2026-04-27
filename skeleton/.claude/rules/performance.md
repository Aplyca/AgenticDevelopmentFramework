---
# CUSTOMIZE: Update paths to match your project structure
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "package.json"
  - "requirements.txt"
  - "go.mod"
  - "Cargo.toml"
---

# Performance Rules

## Dependencies / bundle size
- Minimize external dependencies. Each new package increases bundle size, attack surface, and maintenance burden.
- Before adding a dependency, check its size impact. Justify anything large.
- Use lazy loading / dynamic imports for heavy modules not needed on initial render.

## Data fetching
- Fetch data after mount / on demand, not during render (unless using SSR/SSG patterns).
- Use polling sparingly. Prefer event-driven updates (WebSocket, SSE) for production.
- Always handle fetch errors — no unhandled promise rejections.

## Rendering (frontend)
- Memoize expensive computations that depend on props/state.
- Don't memoize trivial computations — the overhead exceeds the benefit.
- Avoid unnecessary re-renders from inline object/function creation only when it causes measurable issues. Don't prematurely optimize.

## Assets
- Optimize images (use framework image components where available).
- Minimize custom fonts. Use system fonts where acceptable.

## What NOT to optimize prematurely
- Server-side rendering performance (unless measured as a bottleneck).
- Code splitting beyond framework defaults (unless the app is large).
- Database query optimization (unless queries are measurably slow).
- CDN caching (configure when deploying to production).
