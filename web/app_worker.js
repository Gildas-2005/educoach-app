// Service worker Educoach — cache hors-ligne (PWA offline-first).
// Stratégie : réseau d'abord pour rester frais en ligne, secours sur le cache
// hors-ligne. La coquille applicative (CORE) est pré-mise en cache à l'install.
'use strict';

const CACHE = 'educoach-v1';

// Fichiers de la coquille, toujours disponibles hors-ligne après 1re visite.
const CORE = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      // addAll échoue si un fichier manque : on ajoute individuellement.
      Promise.allSettled(CORE.map((url) => cache.add(url))),
    ),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  // On ne gère que les ressources du même domaine (canvaskit est bundlé
  // localement via --no-web-resources-cdn).
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      const cached = await cache.match(request, { ignoreSearch: true });
      try {
        const response = await fetch(request);
        if (response && response.ok) {
          cache.put(request, response.clone());
        }
        return response;
      } catch (networkError) {
        if (cached) return cached;
        if (request.mode === 'navigate') {
          const shell = await cache.match('index.html');
          if (shell) return shell;
        }
        throw networkError;
      }
    })(),
  );
});
