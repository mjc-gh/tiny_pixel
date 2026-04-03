# TinyPixel Tracking Script

The TinyPixel tracking script (`pkg/tiny_pixel.js`) is a lightweight, privacy-focused analytics tracking script that collects page view events and sends them to a TinyPixel analytics server.

## Overview

The tracking script is designed to be minimal and performant. It:
- Collects page view events with minimal data
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
4. **Public API**: `setup()` and `emitPageView()` methods
5. **Auto-initialization**: Browser-context setup and module export for testing

### Module Structure

```javascript
const TinyPixel = (function() {
  // Internal implementation
  return {
    setup(script),
    emitPageView()
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
- Logs debug messages if configuration is incomplete
- Handles null/undefined script gracefully

**Example:**
```html
<script 
  src="https://analytics.example.com/tp.js"
  data-property-id="prop_123"
  data-server="https://analytics.example.com">
</script>
```

### `TinyPixel.emitPageView()`

Sends a page view event to the configured analytics server.

**Behavior:**
- Returns early if not configured
- Creates an invisible image element with pixel tracking URL
- Includes page metadata (hostname, pathname, referrer)
- Automatically appends and removes the image from the DOM

**Return Value:** undefined

## Query Parameters

When emitting a page view, the tracking script includes these query parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `pid` | Property ID | `prop_123` |
| `h` | Hostname | `example.com` |
| `p` | Pathname | `/products` |
| `qs` | Query string (UTM params only) | `utm_source=google&utm_medium=cpc` |
| `n` | Nonce (random value) | `K3mJ9qL2` |
| `ev` | Event type | `view` |
| `r` | Referrer | `https://google.com` |

## UTM Parameter Filtering

The tracking script only captures standard UTM parameters in the query string:
- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_term`
- `utm_content`

Other query parameters are not included, preserving privacy.

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
- Graceful handling of missing attributes
- Referrer inclusion/exclusion

See `pkg/tiny_pixel.test.js` for comprehensive test specifications.

## Development

### Build/Minification

The production version is located at `public/tp.js`. When making changes to the source:

1. Update `pkg/tiny_pixel.js`
2. Minify the changes and update `public/tp.js`
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
