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

## CSS Guidelines

### Never Use Inline Style Elements

Do not use inline `<style>` tags in templates or components. All CSS must be defined in:
- `app/assets/tailwind/application.css` for global styles
- `app/assets/stylesheets/` for other stylesheet files

**Why:** 
- Inline styles are harder to maintain and debug
- They violate separation of concerns
- They can bypass Tailwind's build process
- They make it difficult to apply consistent theming and dark mode support

**Example - ❌ Don't do this:**
```erb
<div>
  <style>
    .my-class { color: red; }
  </style>
  <p class="my-class">Text</p>
</div>
```

**Example - ✅ Do this instead:**
Define styles in `app/assets/tailwind/application.css` and reference them in templates using Tailwind classes or custom CSS classes.

## Slideover Conventions

Slideovers use the native HTML `<dialog>` element with the `tailwindcss-stimulus-components` Slideover controller. They slide in from the right side of the screen with a backdrop overlay.

### Structure

- **Container**: `<div data-controller="slideover" data-slideover-open-value="true" data-turbo-temporary>`
- **Dialog element**: `<dialog data-slideover-target="dialog">`
- **Closing**: Use `data-action="slideover#close"` on buttons or the `Escape` key
- **Auto-open**: Set `data-slideover-open-value="true"` to open on page load (required for Turbo frame delivery)
- **Animation**: CSS is defined in `app/assets/tailwind/application.css` (see Slide-In Animation section below)

### Styling

- **Backdrop**: `backdrop:bg-black/80` (dark overlay with transparency)
- **Dialog**: `slideover h-full max-h-full m-0 w-96 p-8 bg-surface`
- **Width**: Fixed width of `w-96` (384px), full height with `h-full max-h-full`
- **Header**: Flex layout with title and close button in top-right
- **Close button**: `text-text-secondary hover:text-text-primary transition-colors`
- **Animation**: Use `slide-in-from-right` keyframe animation (250ms ease)

### Slide-In Animation

The following CSS is defined in `app/assets/tailwind/application.css`:

```css
dialog.slideover[open] {
  animation: slide-in-from-right 250ms forwards ease;
}

@keyframes slide-in-from-right {
  from {
    transform: translateX(100%);
  }
}
```

### Turbo Frame Integration

- Place a `<turbo-frame id="modals">` placeholder in `app/views/layouts/application.html.erb`
- Slideover content endpoints return a Turbo frame targeting `modals`
- Link to slideovers with `data: { turbo_frame: "modals", action: "slideover#open" }`

### Example

```erb
<div data-controller="slideover" data-slideover-open-value="true" data-turbo-temporary>
  <dialog data-slideover-target="dialog" class="slideover h-full max-h-full m-0 w-96 p-8 bg-surface backdrop:bg-black/80">
    <div class="flex justify-between items-center mb-6">
      <h2 class="text-lg font-bold">Title</h2>
      <button type="button" data-action="slideover#close" class="text-text-secondary hover:text-text-primary">
        <!-- x-mark icon -->
      </button>
    </div>
    
    <!-- Slideover content -->
    
    <div class="flex justify-end gap-3">
      <button autofocus type="button" data-action="slideover#close">Close</button>
    </div>
  </dialog>
</div>
```
