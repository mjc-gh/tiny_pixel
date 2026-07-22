const TinyPixel = (function() {
  const QS_KEY_NAMES = [
    "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "ref"
  ];

  let propertyId, server;
  let configured = false;
  let spaMode = false;
  let lastUrl = '';

  const locationQueryString = () => {
    const locParams = new URLSearchParams(location.search);
    const qs = new URLSearchParams();

    for (const [key, val] of locParams.entries()) {
      if (QS_KEY_NAMES.includes(key)) {
        qs.append(key, val);
      }
    }

    return qs.toString();
  }

  const getRandom = (length) => {
    const cryptoObj = (typeof window !== 'undefined' && window.crypto) || 
                      (typeof global !== 'undefined' && global.crypto) || 
                      undefined;
    
    if (cryptoObj === undefined) {
      return Math.floor(1e10 * Math.random());
    }

    const arr = new Uint8Array(length);

    cryptoObj.getRandomValues(arr);

    return btoa(String.fromCharCode.apply(null, arr)).replace(/[=/\-]/g, "");
  }

  const isOptedOut = () => {
    return document.cookie.split(';').some(c => 
      c.trim().startsWith('tpOptOut=yes')
    );
  }

  const send = (eventType, referrer) => {
    const params = new URLSearchParams({
      pid: propertyId,
      h: location.hostname,
      p: location.pathname,
      qs: locationQueryString(),
      n: getRandom(12)
    });

    if (eventType)
      params.append("ev", eventType);

    const referrerToUse = referrer || document.referrer;
    if (referrerToUse)
      params.append("r", referrerToUse);

    const img = new Image();
    const cleanup = () => { img.parentNode.removeChild(img) };

    img.setAttribute("aria-hidden", "true");
    img.style.position = "absolute";
    img.src = `${server}/_/pixel.gif?${params}`;

    img.addEventListener("load", cleanup);
    img.addEventListener("error", cleanup);

    document.body.appendChild(img);
  }

  const handleNavigation = () => {
    const currentUrl = location.pathname + location.search + location.hash;
    
    if (currentUrl === lastUrl) {
      return; // Deduplicate same URL
    }
    
    const previousUrl = lastUrl || document.referrer;
    lastUrl = currentUrl;
    
    TinyPixel.emitPageView(previousUrl);
  }

  const initSpaTracking = () => {
    if (!spaMode || typeof window === 'undefined' || typeof history === 'undefined') return;

    // Track initial page URL
    lastUrl = location.pathname + location.search + location.hash;

    // Patch history.pushState
    const originalPushState = history.pushState;
    history.pushState = function(...args) {
      originalPushState.apply(this, args);
      handleNavigation();
    };

    // Patch history.replaceState
    const originalReplaceState = history.replaceState;
    history.replaceState = function(...args) {
      originalReplaceState.apply(this, args);
      handleNavigation();
    };

    // Listen for popstate (browser back/forward)
    window.addEventListener('popstate', handleNavigation);

    // Listen for hashchange (hash-based routing)
    window.addEventListener('hashchange', handleNavigation);
  }

  return {
    setup(script) {
      if (!script) return;

      propertyId = script.dataset.propertyId;
      server = script.dataset.server;
      spaMode = script.dataset.spa === 'true';
      configured = propertyId && server;

      if (!propertyId)
        console.debug("TinyPixel: No data-property-id on <script> tag");
      if (!server)
        console.debug("TinyPixel: No data-server on <script> tag");
      
      if (spaMode)
        initSpaTracking();
    },

    emitPageView: (referrer) => {
      if (!configured) return;
      if (isOptedOut()) return;

      send("view", referrer);
    },

    initSpaTracking
  };
}());

// Auto-initialize only in browser context
if (typeof document !== 'undefined' && document.currentScript) {
  TinyPixel.setup(document.currentScript);
  TinyPixel.emitPageView();
}

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
  module.exports = TinyPixel;
}
