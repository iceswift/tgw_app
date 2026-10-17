# Thai Gold View

Flutter app for Thai gold prices, released as Android and as a Flutter Web PWA at `https://thaigoldview.com`.

## Data flow

The app reads `https://api.thaigoldview.com/api/board` through a shared repository. It caches the latest board snapshot, deduplicates concurrent requests, uses ETags for unchanged data, and refreshes when the app resumes or receives an FCM signal.

```text
Backend snapshot changes -> FCM data event -> /api/board -> local cache and shared state
```

The API is always the source of truth; FCM never contains trusted price data.

## Development and builds

```bash
flutter pub get
flutter test
flutter run -d chrome
flutter build apk --release
flutter build web --release
```

The PWA output is `build/web`.

## Web Push

The PWA registers `web/firebase-messaging-sw.js` at the domain root. A user enables notifications from Settings. iPhone and iPad users must first install the site to the Home Screen.

Web tokens are registered with `POST https://api.thaigoldview.com/api/push/subscribe`. Only Backend-marked price events with `user_visible: "true"` create a visible notification. Other data-only events keep open clients in sync silently, so midnight market-status changes cannot appear as price alerts.

Firebase Web config and the VAPID public key are public client configuration. Never include Firebase service-account credentials in this repository or in `build/web`.

## Home server PWA deployment

```text
/srv/thai-gold-view/web/
├── current -> releases/<git-short-sha>
├── releases/
└── deploy/
    ├── docker-compose.yml
    └── nginx/default.conf
```

```bash
flutter build web --release
# Upload build/web to /srv/thai-gold-view/web/releases/<git-short-sha>
ln -s releases/<git-short-sha> /srv/thai-gold-view/web/current.next
mv -Tf /srv/thai-gold-view/web/current.next /srv/thai-gold-view/web/current
cd /srv/thai-gold-view/web/deploy
docker compose up -d --force-recreate thai-gold-web
```

The Nginx bind mount resolves `current` at container startup, so recreate only `thai-gold-web` after switching release. This does not restart `gold-api`.

## Web verification and rollback

```bash
curl -I https://thaigoldview.com/
curl -I https://thaigoldview.com/manifest.json
curl -I https://thaigoldview.com/firebase-messaging-sw.js
curl -I https://api.thaigoldview.com/health
```

`index.html`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `firebase-messaging-sw.js`, and `manifest.json` must not be cached long-term. To roll back, repoint `current` to a previous `releases/<sha>` directory and recreate only `thai-gold-web`.

See [`docs/PWA_DEPLOYMENT.md`](docs/PWA_DEPLOYMENT.md) for Firebase and hosting details.
