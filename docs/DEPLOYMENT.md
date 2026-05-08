# Production deployment

This is a high-level checklist for taking ASMC into production. The app + API are
deliberately stateless / 12-factor so the only persistent state is the database.

## 1. Database

- Provision a managed Postgres (Neon, Supabase, RDS, Cloud SQL, etc.).
- Set `DATABASE_URL` in your runtime environment.
- Update `api/prisma/schema.prisma` `datasource db { provider = "postgresql" }`.
- Run `npm run prisma:migrate deploy` against the prod DB.

## 2. API service

The API is a plain Node 20 service. Any of these work:

- **Fly.io** — `flyctl launch` from `api/`, attach a Postgres, set secrets.
- **Render / Railway** — connect the repo, point root at `api/`, build `npm install && npm run build`, start `node dist/server.js`.
- **Docker** — see `api/Dockerfile` (TODO; not in this PR — `node:20-alpine`, copy app, `prisma generate`, `npm run build`, `node dist/server.js`).
- **Bare VM** — `pm2 start dist/server.js --name asmc-api`.

### Required environment variables

| Var | Purpose |
| --- | --- |
| `DATABASE_URL` | Prisma connection string |
| `JWT_SECRET` | Signs access tokens |
| `JWT_REFRESH_SECRET` | Signs refresh tokens |
| `ACCESS_TOKEN_TTL` | e.g. `15m` |
| `REFRESH_TOKEN_TTL` | e.g. `30d` |
| `PORT` | default 4000 |
| `CORS_ORIGIN` | Comma-separated list of allowed app origins |

Generate strong secrets:

```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## 3. Flutter app

Build production binaries, baking in the production API URL:

```bash
# Android
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.asmc.example.com/api

flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.asmc.example.com/api

# iOS
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.asmc.example.com/api
```

### Distribution

- **Android**: upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
- **iOS**: upload `build/ios/ipa/asmc_app.ipa` to App Store Connect / TestFlight.
- **Internal QA**: Firebase App Distribution / TestFlight internal track.

## 4. Firebase (FCM, Storage)

The app currently scaffolds for Firebase but does not require it. To wire up FCM
later:

1. Create a Firebase project and add Android + iOS apps.
2. Drop `google-services.json` into `app/android/app/` and
   `GoogleService-Info.plist` into `app/ios/Runner/`.
3. Add the `firebase_core` + `firebase_messaging` packages and call
   `Firebase.initializeApp()` in `main.dart`.
4. Implement an FCM token endpoint on the API and wire push notifications.

## 5. Observability

- **API**: ship `pino-http` logs to Datadog/Logtail. Add `/api/health` to your
  uptime monitor.
- **App**: integrate Crashlytics or Sentry-Flutter; the API client already
  normalizes errors via `ApiException` so you can `await Sentry.captureException`
  inside the Dio interceptor.

## 6. Security checklist

- [ ] HTTPS enforced (terminate TLS at the LB / reverse proxy).
- [ ] CORS allowlist set to known origins only.
- [ ] Strong, **distinct** `JWT_SECRET` and `JWT_REFRESH_SECRET`.
- [ ] Rotate secrets every 90 days.
- [ ] Database backups enabled (daily) + point-in-time recovery if available.
- [ ] Rate-limit `/api/auth/*` (the codebase scaffolds an `express-rate-limit`
      slot — wire it before exposing publicly).
- [ ] Set `helmet` strict CSP headers (already enabled, tune per app needs).
