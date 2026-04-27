---
# CUSTOMIZE: Update paths to match your project structure
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "styles/**"
  - "css/**"
---

# UI / UX Rules

## Principles
1. **Clarity over decoration** — every element communicates state or enables action.
2. **Status at a glance** — state should be immediately visible through color, icons, and text.
3. **Progressive disclosure** — most important information first. Details on drill-down.
4. **Consistent language** — same terms for the same concepts everywhere.

## Color system
<!-- CUSTOMIZE: Define your project's color semantics -->
- Success / approved: green tones
- Active / in progress: blue tones
- Error / rejected: red tones
- Neutral / pending: gray tones

Use light variants for backgrounds, full-strength for text and borders.

## Interaction patterns
- **Loading states** — show skeleton placeholders or spinners while data loads. Never show a blank screen.
- **Empty states** — clear message when a list has no items. Tell the user what to do next.
- **Error states** — user-friendly message explaining what happened and what action to take.
- **Form validation** — inline errors below the relevant field. Disable submit until valid.
- **Destructive actions** — confirm before delete, reject, or cancel operations.

## Accessibility baseline
- Use semantic HTML (`<button>`, `<a>`, `<input>`, not styled divs with click handlers).
- Non-link clickable elements need keyboard support (`tabIndex`, `role`, key handlers).
- Color is never the sole indicator of state — icons or text labels accompany color.
- Form inputs have associated labels.
- Sufficient contrast for text readability.

## Responsiveness
- Layout adapts to narrow viewports without breaking.
- Horizontal overflow content scrolls rather than breaking layout.
- Touch targets are large enough on narrow viewports.
