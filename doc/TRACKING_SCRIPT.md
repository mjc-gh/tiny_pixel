# TinyPixel Tracking Script

The TinyPixel tracking script (`pkg/tiny_pixel.js`) is a lightweight, privacy-focused analytics tracking script that collects page views and custom events and sends them to a TinyPixel analytics server.

## Overview

The tracking script is designed to be minimal and performant. It:
- Collects page view and custom events with minimal data
- Supports UTM parameter filtering
- Uses image pixel requests for maximum compatibility
- Requires no external dependencies
- Works in all modern browsers

## Implementation

The tracking script uses an IIFE (Immediately Invoked Function Expression) pattern that auto-initializes in browser contexts while remaining testable.

### Architecture

The script is organized into functional sections:

1. **Configuration**: UTM parameter names and internal state
2. **Utilities**: Helper functions for URL parsing and random value generation
3. **Core Logic**: Image pixel transmission
4. **Public API**: `setup()`, `emitPageView()`, and `emitEvent()` methods
5. **Auto-initialization**: Browser-context setup and module export for testing

### Module Structure

```javascript
const TinyPixel = (function() {
  // Internal implementation
  return {
    setup(script),
    emitPageView(referrer),
    emitEvent(name, value),
    initSpaTracking()
  };
}());
```

## API Reference

### `TinyPixel.setup(script)`

Configures the tracking script with server details from a script element's data attributes.

**Parameters:**
- `script` (HTMLScriptElement|null): The script element to extract configuration from

**Behavior:**
- Extracts `data-property-id` and `data-server` attributes
- Extracts optional `data-spa` attribute (set to `"true"` to enable SPA tracking)
- Logs debug messages if configuration is incomplete
- Handles null/undefined script gracefully
- Automatically initializes SPA tracking if `data-spa="true"`

**Example:**
```html
<script
  src="https://analytics.example.com/tp.js"
  data-property-id="prop_123"
  data-server="https://analytics.example.com"
  data-spa="true">
</script>
```

### `TinyPixel.emitPageView()`

Sends a page view event to the configured analytics server.

**Parameters:**
- `referrer` (string|optional): Custom referrer to use instead of `document.referrer`. Used internally for SPA page tracking.

**Behavior:**
- Returns early if not configured
- Creates an invisible image element with pixel tracking URL
- Includes page metadata (hostname, pathname, referrer)
- Automatically appends and removes the image from the DOM

**Return Value:** undefined

### `TinyPixel.emitEvent(name, value)`

Sends a custom event to the configured analytics server.

**Parameters:**
- `name` (string): Non-empty event name. The reserved name `view` is not accepted.
- `value` (number|optional): A finite numeric value. `0`, negative, integer, and fractional values are valid.

**Examples:**
```javascript
TinyPixel.emitEvent('signup');
TinyPixel.emitEvent('purchase', 19.99);
```

Invalid names and values are ignored without throwing. Event names and values are sent in a GET URL; do not include secrets, personal information, or large payloads.

## Query Parameters

When emitting an event, the tracking script includes these query parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `pid` | Property ID | `prop_123` |
| `h` | Hostname | `example.com` |
| `p` | Pathname | `/products` |
| `qs` | Query string (UTM params only) | `utm_source=google&utm_medium=cpc` |
| `n` | Nonce (random value) | `K3mJ9qL2` |
| `ev` | `view` for page views or the custom event name | `view` or `signup` |
| `v` | Optional finite numeric custom event value | `19.99` |
| `r` | Referrer | `https://google.com` |

## UTM Parameter Filtering

The tracking script only captures standard UTM parameters in the query string:
- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_term`
- `utm_content`

Other query parameters are not included, preserving privacy.

## Opt-Out Mechanism

Users can opt out of TinyPixel tracking by setting a browser cookie. This suppresses both page views and custom events:

| Cookie Name | Value | Effect |
|-------------|-------|--------|
| `tpOptOut` | `yes` | Disables all tracking pixel requests |

### Setting the Opt-Out Cookie

Website owners can provide an opt-out page that sets this cookie:

```javascript
// Opt out of tracking
document.cookie = "tpOptOut=yes; path=/; max-age=31536000"; // 1 year

// Opt back in (remove cookie)
document.cookie = "tpOptOut=; path=/; max-age=0";
```

When the `tpOptOut` cookie is set to `"yes"`, `TinyPixel.emitPageView()` and `TinyPixel.emitEvent()` return immediately without sending tracking requests.

### Event Validation

Custom event names must be strings containing at least one non-whitespace character, and `view` is reserved for page views. Values must be numbers for which `Number.isFinite()` is true. An omitted value is valid, and `0` is a valid supplied value. The API silently ignores invalid input.

## Single Page Application (SPA) Support

For Single Page Applications that use client-side routing (History API or hash-based navigation), TinyPixel can automatically track page view events when the URL changes.

### Enabling SPA Mode

Add the `data-spa="true"` attribute to the tracking script tag:

```html
<script
  src="https://analytics.example.com/tp.js"
  data-property-id="prop_123"
  data-server="https://analytics.example.com"
  data-spa="true">
</script>
```

### How It Works

When SPA mode is enabled, TinyPixel listens to the following events:

1. **`history.pushState()` calls** - When your SPA framework navigates using the History API
2. **`history.replaceState()` calls** - When your SPA replaces the current history entry
3. **`popstate` events** - When the user clicks browser back/forward buttons
4. **`hashchange` events** - When the URL hash fragment changes (hash-based routing)

### Referrer Tracking

For SPA navigations, TinyPixel automatically sets the previous page URL as the referrer for attribution purposes. This maintains accurate referrer data even though the browser's `document.referrer` property doesn't update on client-side navigation.

Example flow:
1. User visits `/products` (initial page view with `document.referrer` as external referrer)
2. User clicks link to `/products/item123` (new page view with referrer set to `/products`)
3. User clicks back button to `/products` (new page view with referrer set to `/products/item123`)

### Deduplication

TinyPixel prevents duplicate page view events when multiple navigation events fire for the same URL. For example, both `popstate` and `hashchange` events might fire for the same URL change - TinyPixel ensures only one page view is recorded.

### Implementation Details

- SPA tracking is disabled by default (opt-in only via `data-spa="true"`)
- History API methods are wrapped to detect all navigation patterns
- The script tracks the full URL (pathname + search + hash) to detect changes
- Initial page view is emitted before SPA listeners are activated
- SPA listeners remain active for the lifetime of the page (no cleanup)

### Browser Compatibility

SPA mode works in all modern browsers that support:
- History API (`history.pushState` and `history.replaceState`)
- `popstate` events
- `hashchange` events

## Random Value Generation

The script generates a random nonce using:
1. `window.crypto.getRandomValues()` (preferred)
2. `Math.random()` fallback (if crypto unavailable)

The random value is base64-encoded (with padding removed) for use as a tracking nonce.

## Browser Compatibility

The tracking script works in all modern browsers that support:
- `URLSearchParams` (IE 11+)
- `Image` element (all browsers)
- `crypto.getRandomValues()` (all modern browsers, with Math.random fallback)

## Testing

Unit tests for the tracking script are located in `pkg/tiny_pixel.test.js` and use Bun's test runner.

### Running Tests

```bash
cd pkg
bun test
```

### Test Coverage

Tests verify:
- Configuration extraction and error handling
- UTM parameter filtering
- Random value generation
- Page view emission with correct parameters
- Custom event emission, values, URL encoding, and browser-global access
- Graceful handling of missing attributes
- Referrer inclusion/exclusion
- SPA mode activation via `data-spa` attribute
- History API tracking (`pushState`, `replaceState`)
- Browser navigation tracking (`popstate`, `hashchange`)
- URL deduplication for SPA navigations
- Previous URL tracking as referrer on SPA navigation
- Opt-out behavior with SPA tracking

See `pkg/tiny_pixel.test.js` for comprehensive test specifications.

## Development

### Build/Minification

The production version is located at `public/tp.js`. When making changes to the source:

1. Update `pkg/tiny_pixel.js`
2. Regenerate `public/tp.js`: `cd pkg && bun run build`
3. Run tests to ensure functionality: `cd pkg && bun test`

### File Structure

```
pkg/
├── tiny_pixel.js        # Source tracking script
├── tiny_pixel.test.js   # Unit tests
└── package.json         # NPM configuration with Bun test runner

public/
└── tp.js                # Minified production version
```

## Version Management

The project uses `mise` (or asdf) to manage tool versions. See `.tool-versions` for:
- Ruby version
- Bun version for testing

Run `mise install` to install the correct versions locally.

## Performance Considerations

- The tracking script uses image pixel requests (most compatible, minimal overhead)
- Random values are generated on-demand (lazy evaluation)
- Query parameters are built efficiently using URLSearchParams
- Image cleanup is automatic via load/error event listeners
- The script has minimal impact on page performance
