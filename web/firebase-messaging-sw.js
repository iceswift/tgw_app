/* Web Push handler for Thai Gold View.
 * Firebase Messaging registers this file at the site root. Keep it there.
 */
self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { notification: { body: event.data?.text() || '' } };
  }

  const notification = payload.notification || {};
  const data = payload.data || {};
  const showUserNotification = data.user_visible === 'true';
  const title = notification.title || 'Thai Gold View';
  const options = {
    body: notification.body || 'ราคาทองมีการอัปเดต',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: 'gold-price-update',
    renotify: true,
    data: { ...data, url: data.url || '/' },
  };

  const work = [
    self.clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clients) => clients.forEach((client) =>
        client.postMessage({ type: 'gold-price-update', data })
      )),
  ];

  // Data-only events keep open clients in sync silently. Only Backend-marked
  // price changes are allowed to create a user-facing notification.
  if (showUserNotification) {
    work.unshift(self.registration.showNotification(title, options));
  }

  event.waitUntil(Promise.all(work));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = new URL(event.notification.data?.url || '/', self.location.origin).href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clients) => {
        for (const client of clients) {
          if (client.url.startsWith(self.location.origin)) {
            client.postMessage({ type: 'gold-price-update', data: event.notification.data });
            return client.focus();
          }
        }
        return self.clients.openWindow(targetUrl);
      }),
  );
});
