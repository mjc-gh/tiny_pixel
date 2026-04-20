# Turbo Rails Development Guidelines

Concise reference for building Rails applications with Turbo (Drive, Frames, Streams).

## Core Philosophy

- **HTML over the wire**: Server renders HTML; browser handles display
- **Minimal JavaScript**: Use Stimulus for behavior, not rendering logic
- **Progressive enhancement**: Build without Turbo first, layer it on
- **Reuse templates**: Same partials for initial load and live updates

## Turbo Drive

### How It Works
- Intercepts link clicks and form submissions
- Fetches pages via `fetch`, replaces `<body>`, merges `<head>`
- Maintains persistent JavaScript process (no full reloads)

### Form Submissions
- **POST/PUT/PATCH/DELETE** must return **HTTP 303 redirect**
- Validation errors: return **422 Unprocessable Content** with re-rendered form
- Server errors: return **5xx** status codes

```ruby
# Controller pattern
def create
  @model = Model.new(model_params)
  if @model.save
    redirect_to @model, status: :see_other # 303
  else
    render :new, status: :unprocessable_entity # 422
  end
end
```

### Key Data Attributes
| Attribute | Purpose |
|-----------|---------|
| `data-turbo="false"` | Disable Turbo on element/descendants |
| `data-turbo-action="replace"` | Replace history instead of push |
| `data-turbo-method="delete"` | Change link HTTP method |
| `data-turbo-confirm="Sure?"` | Show confirmation dialog |
| `data-turbo-permanent` | Persist element across navigations (requires `id`) |
| `data-turbo-temporary` | Remove before caching (flash messages) |
| `data-turbo-track="reload"` | Force reload when asset changes |
| `data-turbo-prefetch="false"` | Disable hover prefetching |

## Turbo Frames

### Basic Pattern
```erb
<%= turbo_frame_tag "message_1" do %>
  <h1>Message content</h1>
  <a href="/messages/1/edit">Edit</a>  <!-- Stays in frame -->
<% end %>
```

### With a Model Instance
Generates a unique ID attribute using model ID (ie: `"post_123"`)
```erb
<%= turbo_frame_tag @post do %>
  <h1><%= @post.title %></h1>
<% end %>
```

### Loading Strategies
```erb
<!-- Eager load immediately -->
<%= turbo_frame_tag "sidebar", src: "/sidebar" %>

<!-- Lazy load when visible -->
<%= turbo_frame_tag "comments", src: "/comments", loading: "lazy" %>

<!-- With loading indicator -->
<%= turbo_frame_tag "data", src: "/data" do %>
  <p>Loading...</p>
<% end %>
```

### Navigation Targeting
```html
<!-- All links target whole page -->
<%= turbo_frame_tag "nav", target: "_top" do %>
  ...
<% end %>

<!-- Single link escapes frame -->
<%= link_to "Logout", "/logout", data: { turbo_frame: "_top" } %>

<!-- Link targets different frame -->
<%= link_to "Preview", "/preview", data: { turbo_frame: "preview_panel" } %>
```

### Promote to Page Visit (update URL)
```erb
<%= turbo_frame_tag "articles", data: { turbo_action: "advance" } do %>
  <%= link_to "Next", "/articles?page=2" %>
<% end %>
```

### Morphing on Refresh
```erb
<%= turbo_frame_tag "paginated", refresh: "morph", src: "/items" %>
```

### Frame Response Requirements
- Response **must** contain matching `<turbo-frame id="...">` element using `turbo_frame_tag`
- Missing frame triggers error; use `turbo-visit-control` meta for login redirects

## Turbo Streams

### Eight Actions
| Action | Effect |
|--------|--------|
| `append` | Add to end of target container |
| `prepend` | Add to start of target container |
| `replace` | Replace entire target element |
| `update` | Replace target's innerHTML |
| `remove` | Delete target element |
| `before` | Insert before target |
| `after` | Insert after target |
| `refresh` | Trigger page refresh |

### Rails Controller Pattern
```ruby
def create
  @message = Message.create!(message_params)

  respond_to do |format|
    format.turbo_stream  # renders create.turbo_stream.erb
    format.html { redirect_to messages_url }
  end
end

def destroy
  @message.destroy

  respond_to do |format|
    format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
    format.html { redirect_to messages_url }
  end
end
```

### Turbo Stream Templates
```erb
<%# app/views/messages/create.turbo_stream.erb %>
<%= turbo_stream.append :messages, @message %>
<%= turbo_stream.update :count, Message.count %>
```

### Integration Tests

Make requests with `as: :turbo_stream` to simulate Turbo Stream requests:
```ruby
post post_path, as: :turbo_stream
patch post_path(post), as :turbo_stream
```

## Best Practices

### DO
- Return 303 redirects after successful form submissions
- Return 422 for validation errors with re-rendered form
- Use `data-turbo-permanent` with unique `id` for persistent elements
- Use `data-turbo-temporary` for flash messages
- Keep frames focused; don't over-decompose

### DON'T
- Return 200 with HTML body after POST (causes URL issues)
- Nest frames unnecessarily
- Use frames just for Turbo Streams (use regular elements with ID attributes)
- Rely on full page reloads to reset state
- Send JavaScript in Turbo Stream responses
