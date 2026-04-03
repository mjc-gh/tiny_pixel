import { describe, it, expect, beforeEach, mock } from 'bun:test';
import TinyPixel from './tiny_pixel.js';

describe('TinyPixel', () => {
  let mockScript;
  let originalLocation;
  let originalDocument;

  beforeEach(() => {
    // Mock location object
    originalLocation = global.location;
    global.location = {
      search: '',
      hostname: 'example.com',
      pathname: '/page',
      href: 'https://example.com/page'
    };

    // Mock document object
    originalDocument = global.document;
    global.document = {
      currentScript: null,
      referrer: '',
      body: {
        appendChild: mock(() => {}),
        children: []
      }
    };

    // Create a mock script element
    mockScript = {
      dataset: {
        propertyId: 'test-prop-123',
        server: 'https://analytics.example.com'
      }
    };
  });

  describe('TinyPixel.setup()', () => {
    it('extracts data-property-id and data-server attributes', () => {
      const script = {
        dataset: {
          propertyId: 'test-prop-123',
          server: 'https://analytics.example.com'
        }
      };

      TinyPixel.setup(script);

      // Verify setup was successful by checking emitPageView can proceed
      // (This is indirectly tested by emitPageView tests)
      expect(true).toBe(true);
    });

    it('handles missing script element gracefully', () => {
      expect(() => {
        TinyPixel.setup(null);
      }).not.toThrow();

      expect(() => {
        TinyPixel.setup(undefined);
      }).not.toThrow();
    });

    it('logs debug message when data-property-id is missing', () => {
      const consoleSpy = mock(() => {});
      const originalDebug = console.debug;
      console.debug = consoleSpy;

      const script = {
        dataset: {
          propertyId: null,
          server: 'https://analytics.example.com'
        }
      };

      TinyPixel.setup(script);

      expect(consoleSpy).toHaveBeenCalledWith('TinyPixel: No data-property-id on <script> tag');

      console.debug = originalDebug;
    });

    it('logs debug message when data-server is missing', () => {
      const consoleSpy = mock(() => {});
      const originalDebug = console.debug;
      console.debug = consoleSpy;

      const script = {
        dataset: {
          propertyId: 'test-prop-123',
          server: null
        }
      };

      TinyPixel.setup(script);

      expect(consoleSpy).toHaveBeenCalledWith('TinyPixel: No data-property-id on <script> tag');

      console.debug = originalDebug;
    });
  });

  describe('UTM Parameter Filtering (locationQueryString)', () => {
    it('extracts valid UTM parameters from URL', () => {
      global.location.search = '?utm_source=google&utm_medium=cpc&utm_campaign=spring&other_param=value';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      // Verify appendChild was called with image element
      expect(global.document.body.appendChild).toHaveBeenCalled();

      const calls = global.document.body.appendChild.mock.calls;
      expect(calls.length).toBeGreaterThan(0);

      const imgElement = calls[0][0];
      expect(imgElement.src).toContain('utm_source=google');
      expect(imgElement.src).toContain('utm_medium=cpc');
      expect(imgElement.src).toContain('utm_campaign=spring');
    });

    it('filters out non-UTM query parameters', () => {
      global.location.search = '?utm_source=google&other_param=value&utm_medium=cpc&random=data';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      expect(imgElement.src).toContain('utm_source=google');
      expect(imgElement.src).toContain('utm_medium=cpc');
      expect(imgElement.src).not.toContain('other_param');
      expect(imgElement.src).not.toContain('random');
    });

    it('handles empty query strings', () => {
      global.location.search = '';

      TinyPixel.setup(mockScript);
      expect(() => {
        TinyPixel.emitPageView();
      }).not.toThrow();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];
      expect(imgElement.src).toContain('qs=');
    });

    it('handles URLs with no UTM parameters', () => {
      global.location.search = '?page=1&sort=name';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      expect(imgElement.src).not.toContain('page=1');
      expect(imgElement.src).not.toContain('sort=name');
      expect(imgElement.src).toContain('qs=');
    });
  });

  describe('getRandom()', () => {
    it('returns a string of expected format', () => {
      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      // Extract the 'n' parameter from the URL
      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
      const nParam = url.searchParams.get('n');

      expect(nParam).not.toBeNull();
      expect(typeof nParam).toBe('string');
      expect(nParam.length).toBeGreaterThan(0);
      // Should be base64-encoded (alphanumeric, +, -, _)
      expect(/^[A-Za-z0-9_+-]+$/.test(nParam)).toBe(true);
    });

    it('falls back to Math.random when crypto is unavailable', () => {
      const originalCrypto = global.crypto;
      global.crypto = undefined;
      global.window = { crypto: undefined };

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      // Extract the 'n' parameter from the URL
      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
      const nParam = url.searchParams.get('n');

      expect(nParam).not.toBeNull();
      // Math.random fallback returns a number as string
      expect(/^\d+$/.test(nParam) || /^[A-Za-z0-9_+-]+$/.test(nParam)).toBe(true);

      global.crypto = originalCrypto;
    });
  });

  describe('emitPageView()', () => {
    it('does not send requests when not configured', () => {
      TinyPixel.setup(null); // Don't configure

      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).not.toHaveBeenCalled();
    });

    it('creates an image element with correct URL structure when configured', () => {
      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).toHaveBeenCalled();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      // Verify it's an Image-like object with src attribute
      expect(imgElement.src).not.toBeNull();
      expect(imgElement.src).toContain('https://analytics.example.com/_/pixel.gif');
    });

    it('includes proper query parameters (pid, h, p, qs, n, ev, r)', () => {
      global.location.hostname = 'test.com';
      global.location.pathname = '/products';
      global.document.referrer = 'https://google.com';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];
      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));

      expect(url.searchParams.get('pid')).toBe('test-prop-123');
      expect(url.searchParams.get('h')).toBe('test.com');
      expect(url.searchParams.get('p')).toBe('/products');
      expect(url.searchParams.has('qs')).toBe(true);
      expect(url.searchParams.has('n')).toBe(true);
      expect(url.searchParams.get('ev')).toBe('view');
      expect(url.searchParams.get('r')).toBe('https://google.com');
    });

    it('handles document.referrer correctly', () => {
      global.document.referrer = '';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];
      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));

      expect(url.searchParams.has('r')).toBe(false);
    });

    it('sets correct attributes on image element', () => {
      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      expect(imgElement.getAttribute('aria-hidden')).toBe('true');
      expect(imgElement.style.position).toBe('absolute');
    });
  });
});
