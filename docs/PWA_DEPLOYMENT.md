# Thai Gold View PWA deployment

## Firebase Web values

The Firebase Web app configuration, VAPID public key, and production subscribe
endpoint are included as public client configuration. A normal production build
is sufficient:

```powershell
flutter build web --release
```

Firebase Web configuration and the VAPID public key identify the Firebase app;
they are not server credentials. Never put a service-account private key in
the web build.

## Backend contract required for Web Push

`POST https://api.thaigoldview.com/api/push/subscribe` accepts:

```json
{
  "token": "FCM web registration token",
  "topic": "gold_price_updates",
  "platform": "web"
}
```

It validates the allowed topic, subscribes the token with Firebase Admin SDK,
and returns HTTP 202. CORS allows the production web origins.
Rate-limit the endpoint and never expose Firebase Admin credentials.

Send a data-only FCM payload. The app refreshes `/api/board` instead of
trusting a pushed price. The service worker displays a notification only when
the Backend sets `user_visible` to `true` for a real price-data change.
Market-status-only events remain silent.

```json
{
  "data": {
    "type": "gold_snapshot_updated",
    "revision": "1842",
    "updated_at": "2026-10-17T10:05:00+07:00",
    "user_visible": "true"
  }
}
```

## Hosting requirements

- Production Web origin: `https://thaigoldview.com`.
- Production API origin: `https://api.thaigoldview.com`.
- Serve the production site over HTTPS.
- Serve `firebase-messaging-sw.js` from the domain root.
- Route unknown navigation paths to `index.html`.
- Do not cache `index.html`, `flutter_bootstrap.js`, or the messaging worker
  permanently; hashed Flutter assets may use long-lived immutable caching.
- Allow API CORS from exactly `https://thaigoldview.com` (and only explicitly
  required development origins); include `POST` and `OPTIONS` for push token
  registration.
- On iPhone/iPad, install the site to the Home Screen before enabling alerts.

Without the Firebase defines, the PWA still builds and runs; its Settings page
reports that Web notifications are waiting for administrator configuration.
