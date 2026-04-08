# UI Style Guidelines

## Icons

This project exclusively uses [Heroicons](https://heroicons.com/) for all icons.

### Usage Pattern

Icons are rendered as inline SVGs using the **outline** style (24x24 viewBox, stroke-based):

```erb
<svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" d="..." />
</svg>
```

### Standard Sizes

| Context | Class | Size |
|---------|-------|------|
| Inline/buttons | `h-5 w-5` | 20px |
| Mobile nav | `h-6 w-6` | 24px |

### Icon Reference

| Use Case | Heroicon Name |
|----------|---------------|
| Light mode toggle | `sun` |
| Dark mode toggle | `moon` |
| Settings | `cog-8-tooth` |
| Menu open | `bars-3` |
| Menu close | `x-mark` |
| Previous page | `chevron-left` |
| Next page | `chevron-right` |

### Guidelines

1. Always use the **outline** variant for consistency
2. Use `stroke="currentColor"` to inherit text color from parent
3. Apply sizing via Tailwind classes (`h-5 w-5`, etc.)
4. Do not use emoji or text characters for icons
