const assets = [
  "./index.html",
  "./app.js",
  "./voice-clips.js",
  "./install.js",
  "./manifest.json",
  "./mascot.jpg",
  "./icon.png",
  "./icon-180.png",
  "./icon-192.png",
  "./icon-512.png",
  "./lesson-cards/lesson-001.jpg",
  "./lesson-cards/lesson-002.jpg",
  "./lesson-cards/lesson-003.jpg",
  "./lesson-cards/lesson-004.jpg",
  "./lesson-cards/lesson-005.jpg",
  "./lesson-cards/lesson-006.jpg",
  "./lesson-cards/lesson-007.jpg",
  "./lesson-cards/lesson-008.jpg",
  "./lesson-cards/lesson-009.jpg",
  "./lesson-cards/lesson-010.jpg",
  "./lesson-cards/lesson-011.jpg",
  "./lesson-cards/lesson-012.jpg",
  "./lesson-cards/lesson-013.jpg",
  "./lesson-cards/lesson-014.jpg",
  "./lesson-cards/lesson-015.jpg",
  "./lesson-cards/lesson-016.jpg",
  "./lesson-cards/lesson-017.jpg",
  "./lesson-cards/lesson-018.jpg",
  "./lesson-cards/lesson-019.jpg",
  "./lesson-cards/lesson-020.jpg",
  "./lesson-cards/lesson-021.jpg",
  "./lesson-cards/lesson-022.jpg",
  "./lesson-cards/lesson-023.jpg",
  "./lesson-cards/lesson-024.jpg",
  "./lesson-cards/lesson-025.jpg",
  "./lesson-cards/lesson-026.jpg",
  "./lesson-cards/lesson-027.jpg",
  "./lesson-cards/lesson-028.jpg",
  "./lesson-cards/lesson-029.jpg",
  "./lesson-cards/lesson-030.jpg",
  "./lesson-cards/lesson-031.jpg",
  "./lesson-cards/lesson-032.jpg",
  "./lesson-cards/lesson-033.jpg",
  "./lesson-cards/lesson-034.jpg",
  "./lesson-cards/lesson-035.jpg",
  "./lesson-cards/lesson-036.jpg",
  "./lesson-cards/lesson-037.jpg",
  "./lesson-cards/lesson-038.jpg",
  "./lesson-cards/lesson-039.jpg",
  "./lesson-cards/lesson-040.jpg",
  "./lesson-cards/lesson-041.jpg",
  "./lesson-cards/lesson-042.jpg",
  "./lesson-cards/lesson-043.jpg",
  "./lesson-cards/lesson-044.jpg",
  "./lesson-cards/lesson-045.jpg",
  "./lesson-cards/lesson-046.jpg",
  "./lesson-cards/lesson-047.jpg",
  "./lesson-cards/lesson-048.jpg",
  "./lesson-cards/lesson-049.jpg",
  "./lesson-cards/lesson-050.jpg",
  "./lesson-cards/lesson-051.jpg",
  "./lesson-cards/lesson-052.jpg",
  "./lesson-cards/lesson-053.jpg",
  "./lesson-cards/lesson-054.jpg",
  "./lesson-cards/lesson-055.jpg",
  "./lesson-cards/lesson-056.jpg",
  "./lesson-cards/lesson-057.jpg",
  "./lesson-cards/lesson-058.jpg",
  "./lesson-cards/lesson-059.jpg",
  "./lesson-cards/lesson-060.jpg",
  "./lesson-cards/lesson-061.jpg",
  "./lesson-cards/lesson-062.jpg",
  "./lesson-cards/lesson-063.jpg",
  "./lesson-cards/lesson-064.jpg",
  "./lesson-cards/lesson-065.jpg",
  "./lesson-cards/lesson-066.jpg",
  "./lesson-cards/lesson-067.jpg",
  "./lesson-cards/lesson-068.jpg",
  "./lesson-cards/lesson-069.jpg",
  "./lesson-cards/lesson-070.jpg",
  "./lesson-cards/lesson-071.jpg",
  "./lesson-cards/lesson-072.jpg",
  "./lesson-cards/lesson-073.jpg",
  "./lesson-cards/lesson-074.jpg",
  "./lesson-cards/lesson-075.jpg",
  "./lesson-cards/lesson-076.jpg",
  "./lesson-cards/lesson-077.jpg",
  "./lesson-cards/lesson-078.jpg",
  "./lesson-cards/lesson-079.jpg",
  "./lesson-cards/lesson-080.jpg",
  "./lesson-cards/lesson-081.jpg",
  "./lesson-cards/lesson-082.jpg",
  "./lesson-cards/lesson-083.jpg",
  "./lesson-cards/lesson-084.jpg",
  "./lesson-cards/lesson-085.jpg",
  "./lesson-cards/lesson-086.jpg",
  "./lesson-cards/lesson-087.jpg",
  "./lesson-cards/lesson-088.jpg",
  "./lesson-cards/lesson-089.jpg",
  "./lesson-cards/lesson-090.jpg",
  "./lesson-cards/lesson-091.jpg",
  "./lesson-cards/lesson-092.jpg",
  "./lesson-cards/lesson-093.jpg",
  "./lesson-cards/lesson-094.jpg",
  "./lesson-cards/lesson-095.jpg",
  "./lesson-cards/lesson-096.jpg",
  "./lesson-cards/lesson-097.jpg",
  "./lesson-cards/lesson-098.jpg",
  "./lesson-cards/lesson-099.jpg",
  "./lesson-cards/lesson-100.jpg"
];
const cacheName = 'kyryk-mary-v21';
const scope = self.registration.scope;
const home = new URL('index.html', scope).href;
const localAssets = new Set(assets.map(file => new URL(file, scope).href));

self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(cacheName);
    await cache.addAll(assets.map(file => new Request(new URL(file, scope), {cache: 'reload'})));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    for (const name of await caches.keys()) {
      if (name.startsWith('kyryk-mary-') && name !== cacheName) await caches.delete(name);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', event => {
  const request = event.request;
  const url = new URL(request.url);
  const navigation = request.mode === 'navigate' && (url.href === scope || url.href === home || url.pathname === new URL(scope).pathname);
  if (request.method !== 'GET' || (!localAssets.has(url.href) && !navigation)) return;
  event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    const cached = await cache.match(navigation ? home : request.url);
    return cached || fetch(request);
  })());
});
