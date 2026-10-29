// Offline support for the web app. Every request goes to the network first,
// so a new deploy shows up on the next load; the last good copy is served
// when the network is down. Only same-origin GET requests are handled.
'use strict';

const CACHE = 'demonica-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        if (key !== CACHE) await caches.delete(key);
      }
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;

  // Every page is the same app (GitHub Pages serves deep links from
  // 404.html), so navigations share one cache entry: the app shell.
  const isPage = request.mode === 'navigate';
  const key = isPage ? self.registration.scope : request;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      try {
        const response = await fetch(request);
        if (response.ok || isPage) await cache.put(key, response.clone());
        return response;
      } catch (error) {
        const cached = await cache.match(key, { ignoreSearch: true });
        if (cached) return cached;
        throw error;
      }
    })(),
  );
});
