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

# Code Quality Rules

## Type safety
- Use the language's type system fully. Avoid escape hatches (`any` in TypeScript, `interface{}` in Go, `Any` in Python).
- Explicit types at API boundaries (function signatures, route handlers, component props).
- Use `unknown` + type guards (or equivalent) when handling external data.

## Naming

| Element | Convention |
|---|---|
| Files (components/classes) | PascalCase |
| Files (utilities/hooks) | camelCase |
| Functions/methods | camelCase |
| Constants | UPPER_SNAKE_CASE |
| CSS classes / URLs | kebab-case |

Adapt to your language's idioms (e.g., snake_case for Python, PascalCase for Go exports).

## File organization

1. Imports / dependencies
2. Types / interfaces
3. Constants
4. Helper functions (pure, no side effects)
5. Main export (component, handler, class)
6. Styles (if colocated)

## Principles

- **No premature abstraction** — three similar lines are better than a wrapper used once. Extract only when genuinely shared.
- **No speculative features** — build what the spec says, nothing more. No feature flags, config options, or extension points "for the future."
- **Delete, don't comment** — when removing code, delete it. Git preserves history. No commented-out blocks or `// removed` markers.
- **Comment *why*, never *what*** — self-evident code needs no comments. Comments explain intent, constraints, or non-obvious decisions.

## Error handling

- API endpoints: catch all errors, log with context (endpoint name, input shape, error message), return appropriate HTTP status codes. Never let stack traces reach the client.
- Frontend / client code: handle all fetch/request failures with `.catch()` or try/catch. Show user-friendly error states with actionable messages.
- Silent degradation for non-critical failures: if a secondary call fails (logs, analytics, optional data), show empty state rather than crashing the view.
- Guard external data before using it — check types, check for null/undefined, verify array before calling array methods.
- Don't use try/catch as flow control. Catch at the boundary, not around every line. Never swallow errors silently — at minimum, log them.

## Git

- Concise commit messages in imperative mood. Explain *why*, not *what*.
- One logical change per commit. Don't mix unrelated changes.
- Don't commit generated files, build artifacts, or dependency directories.
