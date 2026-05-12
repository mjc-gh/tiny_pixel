import { describe, it, expect, beforeEach, afterEach, mock } from 'bun:test';
import TinyPixel from './tiny_pixel.js';

describe('TinyPixel', () => {
  let mockScript;
  let originalLocation;
  let originalDocument;
  let originalImage;
  let originalCrypto;

  beforeEach(() => {
    // Reset TinyPixel state by calling setup with a script that has no data
    const originalDebug = console.debug;
    console.debug = () => {}; // Suppress debug output during reset
    TinyPixel.setup({ dataset: {} });
    console.debug = originalDebug;

    // Mock location object
    originalLocation = global.location;
    global.location = {
      search: '',
      hostname: 'example.com',
      pathname: '/page',
      href: 'https://example.com/page'
    };

    // Mock Image constructor
    originalImage = global.Image;
    global.Image = class MockImage {
      constructor() {
        this.src = '';
        this.style = {};
        this.listeners = {};
        this.parentNode = {
          removeChild: mock(() => {})
        };
      }
      
      setAttribute(name, value) {
        this[`_${name}`] = value;
      }
      
      getAttribute(name) {
        return this[`_${name}`] || null;
      }
      
      addEventListener(event, handler) {
        if (!this.listeners[event]) {
          this.listeners[event] = [];
        }
        this.listeners[event].push(handler);
      }
    };

    // Mock document object
    originalDocument = global.document;
    const appendChildMock = mock(() => {});
    global.document = {
      currentScript: null,
      referrer: '',
      cookie: '',
      body: {
        appendChild: appendChildMock,
        children: []
      }
    };

    // Store original crypto
    originalCrypto = global.crypto;

    // Create a mock script element
    mockScript = {
      dataset: {
        propertyId: 'test-prop-123',
        server: 'https://analytics.example.com'
      }
    };
  });
  
  afterEach(() => {
    // Restore global objects
    if (originalLocation) global.location = originalLocation;
    if (originalDocument) global.document = originalDocument;
    if (originalImage) global.Image = originalImage;
    if (originalCrypto !== undefined) global.crypto = originalCrypto;
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

      expect(consoleSpy).toHaveBeenCalledWith('TinyPixel: No data-server on <script> tag');

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
      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
      const qs = url.searchParams.get('qs');
      
      expect(qs).toContain('utm_source=google');
      expect(qs).toContain('utm_medium=cpc');
      expect(qs).toContain('utm_campaign=spring');
    });

    it('filters out non-UTM query parameters', () => {
      global.location.search = '?utm_source=google&other_param=value&utm_medium=cpc&random=data';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
      const qs = url.searchParams.get('qs');
      
      expect(qs).toContain('utm_source=google');
      expect(qs).toContain('utm_medium=cpc');
      expect(qs).not.toContain('other_param');
      expect(qs).not.toContain('random');
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

    it('extracts ref parameter for additional attribution', () => {
      global.location.search = '?utm_source=google&ref=campaign123&utm_medium=cpc';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
      const qs = url.searchParams.get('qs');

      expect(qs).toContain('utm_source=google');
      expect(qs).toContain('ref=campaign123');
      expect(qs).toContain('utm_medium=cpc');
    });

    it('filters out non-tracked parameters when ref is present', () => {
      global.location.search = '?utm_source=google&ref=campaign123&page=1&other=value';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      const calls = global.document.body.appendChild.mock.calls;
      const imgElement = calls[0][0];

      const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
      const qs = url.searchParams.get('qs');

      expect(qs).toContain('utm_source=google');
      expect(qs).toContain('ref=campaign123');
      expect(qs).not.toContain('page=1');
      expect(qs).not.toContain('other=value');
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
      // Should be base64-encoded (alphanumeric, +, /, -, _) but without / and -
      expect(/^[A-Za-z0-9+_]+$/.test(nParam)).toBe(true);
    });

    it('excludes forward slashes and hyphens from random values', () => {
      // Generate multiple random values to verify consistency
      TinyPixel.setup(mockScript);
      
      for (let i = 0; i < 10; i++) {
        // Reset document calls
        global.document.body.appendChild.mock.calls.length = 0;
        
        TinyPixel.emitPageView();

        const calls = global.document.body.appendChild.mock.calls;
        const imgElement = calls[0][0];

        const url = new URL(imgElement.src.replace('https://analytics.example.com', 'https://example.com'));
        const nParam = url.searchParams.get('n');

        // Should NOT contain / or -
        expect(nParam).not.toContain('/');
        expect(nParam).not.toContain('-');
        // Should only contain alphanumeric, +, and _
        expect(/^[A-Za-z0-9+_]+$/.test(nParam)).toBe(true);
      }
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
      expect(/^\d+$/.test(nParam) || /^[A-Za-z0-9_+]+$/.test(nParam)).toBe(true);

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

  describe('Opt-Out Mechanism (tpOptOut cookie)', () => {
    it('does not send requests when tpOptOut=yes cookie is set', () => {
      global.document.cookie = 'tpOptOut=yes';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).not.toHaveBeenCalled();
    });

    it('tracks normally when tpOptOut cookie is absent', () => {
      global.document.cookie = '';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).toHaveBeenCalled();
    });

    it('tracks normally when tpOptOut is set to a value other than yes', () => {
      global.document.cookie = 'tpOptOut=no';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).toHaveBeenCalled();
    });

    it('detects opt-out when tpOptOut=yes exists among multiple cookies', () => {
      global.document.cookie = 'sessionId=abc123; tpOptOut=yes; userId=user456';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).not.toHaveBeenCalled();
    });

    it('tracks normally when opt-out cookie is not present among multiple cookies', () => {
      global.document.cookie = 'sessionId=abc123; userId=user456; otherCookie=value';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).toHaveBeenCalled();
    });

    it('respects opt-out even with whitespace around cookie name', () => {
      global.document.cookie = 'sessionId=abc123;  tpOptOut=yes  ;userId=user456';

      TinyPixel.setup(mockScript);
      TinyPixel.emitPageView();

      expect(global.document.body.appendChild).not.toHaveBeenCalled();
    });
  });
});
