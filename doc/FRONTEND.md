# UI Style Guidelines

## Stimulus Controller Patterns

The dashboard uses a centralized `Turbo.visit()` pattern in the Stimulus controller:

1. **State Management**: All filter state stored as Stimulus values
2. **Navigation**: All user actions call `visit()` method which navigates with Turbo
3. **Server Rendering**: Server receives request with all filter params in URL
4. **Frame Re-rendering**: Turbo automatically re-renders all turbo-frames with new content

This pattern eliminates manual frame source manipulation and simplifies the frontend logic significantly.

## Icons

This project uses the [heroicon-rails](https://github.com/mattes/heroicon-rails) gem to render [Heroicons](https://heroicons.com/) consistently throughout the application.

### Usage Pattern

Icons are rendered using the `heroicon` helper, which supports different icon types (`:outline`, `:mini`, etc.):

```erb
<%= heroicon "eye", type: :outline, class: "h-5 w-5" %>
<%= heroicon "chevron-left", type: :mini, class: "h-5 w-5" %>
```

### Icon Types

| Type | Use Case | Scale |
|------|----------|-------|
| `:outline` | Default icons, buttons, navigation | 24x24 viewBox |
| `:mini` | Pagination, compact spaces | 20x20 viewBox |

### Standard Sizes

| Context | Class | Size |
|---------|-------|------|
| Inline/buttons | `h-5 w-5` | 20px |
| Mobile nav | `h-6 w-6` | 24px |

### Icon Reference

| Use Case | Heroicon Name | Type |
|----------|---------------|------|
| Light mode toggle | `sun` | `:outline` |
| Dark mode toggle | `moon` | `:outline` |
| Settings | `cog-8-tooth` | `:outline` |
| Menu open | `bars-3` | `:outline` |
| Menu close | `x-mark` | `:outline` |
| Previous page | `chevron-left` | `:mini` |
| Next page | `chevron-right` | `:mini` |
| Eye (password visible) | `eye` | `:outline` |
| Eye slash (password hidden) | `eye-slash` | `:outline` |
| Code snippet | `code-bracket` | `:outline` |

### Guidelines

1. Always use the `heroicon` helper from the gem for consistency
2. Use `type: :outline` by default, `type: :mini` for pagination and compact spaces
3. Apply sizing via Tailwind classes (`h-5 w-5`, etc.)
4. Use `data:` attribute for Stimulus controller integration: `<%= heroicon "x-mark", data: { "action-target": "icon" }, class: "h-5 w-5" %>`
5. Do not use emoji or inline SVG elements for icons

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

## Design Tokens System

The application uses CSS custom properties (design tokens) to maintain consistency across light and dark modes. All color-based styling must use design tokens instead of hardcoded Tailwind classes.

### Token Categories

Tokens are organized by purpose in `app/assets/tailwind/application.css`:

| Category | Light Mode Example | Dark Mode Example | Usage |
|----------|-------------------|-------------------|-------|
| **Backgrounds** | `--color-background` | (darker shade) | Page backgrounds |
| **Surfaces** | `--color-surface` | (darker shade) | Cards, containers |
| **Borders** | `--color-border` | (lighter shade) | Element dividers |
| **Text/Content** | `--color-content-primary` | (lighter shade) | Body text |
| **Primary Action** | `--color-primary` | (lighter shade) | Links, buttons |
| **Danger/Alert** | `--color-danger-bg`, `-border`, `-text` | (with dark variants) | Error states |
| **Warning** | `--color-warning-bg`, `-border`, `-text` | (with dark variants) | Warning states |
| **Success** | `--color-success-bg`, `-border`, `-text` | (with dark variants) | Success states |

### Usage Pattern

Always use token-based class names in templates instead of hardcoded colors:

**❌ Don't do this (hardcoded Tailwind):**
```erb
<div class="bg-red-100 border border-red-400 text-red-700">
  Error message
</div>
```

**✅ Do this instead (design tokens):**
```erb
<div class="bg-danger-bg border border-danger-border text-danger-text">
  Error message
</div>
```

### Variant-Based Components

When creating components with multiple variants (success, danger, warning), use token-based classes:

```erb
<div class="bg-<%= @variant %>-bg border border-<%= @variant %>-border text-<%= @variant %>-text">
  <!-- content -->
</div>
```

The component receives the variant (`:success`, `:danger`, `:warning`) and Tailwind resolves to the correct token for the current theme mode.

### Adding New Tokens

When adding new design tokens:

1. Define in `@theme` block for light mode defaults
2. Define in `.dark` block for dark mode overrides
3. Use semantic names (e.g., `--color-success-bg` not `--color-green-bg`)
4. Ensure sufficient contrast for accessibility (WCAG AA minimum)
5. Verify both light and dark mode appearance

### Token Definitions

See `app/assets/tailwind/application.css` for current token definitions and their color values.

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
- **Close button**: `text-content-secondary hover:text-content-primary transition-colors`
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
      <button type="button" data-action="slideover#close" class="text-content-secondary hover:text-content-primary">
         <%= heroicon "x-mark", type: :outline, class: "h-5 w-5" %>
      </button>
    </div>
    
    <!-- Slideover content -->
    
    <div class="flex justify-end gap-3">
      <button autofocus type="button" data-action="slideover#close">Close</button>
     </div>
   </dialog>
 </div>
 ```

## ViewComponent Patterns

The application uses [ViewComponent](https://viewcomponent.org/) to create reusable, testable UI components.

### When to Create a Component

Create a ViewComponent when:
- A UI element appears in multiple places in the application
- A template has complex logic or styling that warrants encapsulation
- The element needs to be easily tested in isolation
- The element has multiple variants or configuration options

### Component Structure

**File Organization:**
- Component class: `app/components/{name}_component.rb`
- Component template: `app/components/{name}_component.html.erb`
- Component tests: `test/components/{name}_component_test.rb`

**Class Structure:**
```ruby
# frozen_string_literal: true

class AlertComponent < ViewComponent::Base
  def initialize(variant: :danger, message: "")
    @variant = variant
    @message = message
  end

  private

  def variant_title
    case @variant
    when :success
      "Success"
    when :danger
      "Error"
    end
  end
end
```

### Styling Components with Design Tokens

Always use design tokens for color-based styling (see Design Tokens System section):

```erb
<div class="bg-<%= @variant %>-bg border border-<%= @variant %>-border text-<%= @variant %>-text">
  <strong><%= variant_title %></strong>
  <%= @message %>
</div>
```

This ensures:
- Automatic dark mode support through token definitions
- Consistent theming across the application
- Single source of truth for colors

### Stimulus Controller Integration

Components can use Stimulus controllers for interactivity:

```erb
<div data-controller="alert" data-alert-dismiss-after-value="5000" role="alert">
  <!-- content -->
  <button data-action="alert#close">Dismiss</button>
</div>
```

### Testing Components

All ViewComponents require tests. Use `ViewComponent::TestCase`:

```ruby
class AlertComponentTest < ViewComponent::TestCase
  def test_renders_with_success_variant
    render_inline(AlertComponent.new(variant: :success, message: "Saved!"))
    
    assert_text "Success"
    assert_text "Saved!"
    assert_selector ".bg-success-bg"
  end
end
```

**Test Guidelines:**
- Test all variants and configuration options
- Verify correct CSS classes are applied
- Check rendered content and attributes
- Minimize test cases while maximizing coverage
- Don't test framework features (delegated to ViewComponent library)

### Component Examples

- **AlertComponent**: Multi-variant alert with Stimulus controller
- **SiteCardComponent**: Display site information with links
- **PaginationComponent**: Pagination controls with styling
- See `app/components/` for more examples
