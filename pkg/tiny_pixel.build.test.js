import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'bun:test';

describe('TinyPixel production build', () => {
  it('runs as a classic browser script and emits the initial page view', () => {
    const script = readFileSync(fileURLToPath(new URL('../public/tp.js', import.meta.url)), 'utf8');
    const images = [];
    const context = {
      URLSearchParams,
      Uint8Array,
      btoa: (value) => Buffer.from(value, 'binary').toString('base64'),
      location: {
        hostname: 'example.com',
        pathname: '/page',
        search: '?utm_source=test',
        hash: ''
      },
      document: {
        currentScript: {
          dataset: {
            propertyId: 'test-property',
            server: 'https://analytics.example.com'
          }
        },
        cookie: '',
        referrer: '',
        body: {
          appendChild: (image) => images.push(image)
        }
      },
      Image: class {
        style = {};
        listeners = {};

        setAttribute() {}

        addEventListener(name, callback) {
          this.listeners[name] = callback;
        }
      }
    };

    runInNewContext(script, context);

    expect(context.TinyPixel).toBeDefined();
    expect(images).toHaveLength(1);
    expect(images[0].src).toContain('https://analytics.example.com/_/pixel.gif?');
    expect(images[0].src).toContain('utm_source%3Dtest');
  });
});
