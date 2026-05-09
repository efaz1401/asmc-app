# Production deployment

The app + API are 12-factor and stateless; the only persistent state is Postgres.
The recommended path is **Render Blueprint** (one click) for the API + DB and a
**release Flutter build** for the mobile app.

## TL;DR

```bash
# 1. Deploy API + DB on Render via Blueprint
#    UI:  Render → New > Blueprint > pick this repo > Apply
#    Files used: render.yaml, api/Dockerfile

# 2. Build a release APK pointed at the deployed API
cd app
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-render-app>.onrender.com/api
```

---

## 1. API + database on Render (Blueprint, recommended)

The repo ships with everything Render needs:

- `render.yaml` — Blueprint spec (web service + managed Postgres).
- `api/Dockerfile` — multi-stage Node 20 build; runs `prisma migrate deploy` on
  every boot and (optionally) seeds on first boot.
- `docker-compose.yml` — local Postgres for dev (mirrors the prod setup).

### One-time setup

1. Sign in at <https://render.com> with the GitHub account that owns the repo.
2. **New → Blueprint**.
3. Pick the repo (`asmc-app` or wherever this lives) and the branch you want to
   deploy (`main` or your feature branch).
4. Render reads `render.yaml` and proposes:
   - **Web service** `asmc-api` — Docker, free plan, region `oregon`.
   - **Postgres database** `asmc-db` — free plan, region `oregon`.
5. Click **Apply**.

That's it for the first deploy. Render will:

- Provision Postgres and inject `DATABASE_URL` into the web service.
- Generate `JWT_SECRET` (random, persistent).
- Build the Docker image from `api/Dockerfile`.
- On boot, run `prisma migrate deploy` then start `node dist/server.js`.
- With `SEED_ON_BOOT=true` (default in `render.yaml` for the first deploy), the
  container also runs the seed script and creates the test users below.

When the service is green, hit `https://<service>.onrender.com/api/health` — you
should see `{"status":"ok",...}`.

### After the first deploy

Open the `asmc-api` service in Render → **Environment**:

- Flip `SEED_ON_BOOT` to `false` so future deploys don't touch user data.
- Tighten `CORS_ORIGIN` from `*` to the actual app/web origin once known
  (comma-separated list is supported).

### Required env vars (managed by Render automatically)

| Var | Source | Purpose |
| --- | --- | --- |
| `DATABASE_URL` | Render Postgres | Prisma connection string |
| `JWT_SECRET` | `generateValue: true` | Signs access + refresh tokens |
| `JWT_ACCESS_EXPIRES_IN` | `15m` | Access token TTL |
| `JWT_REFRESH_EXPIRES_IN` | `7d` | Refresh token TTL |
| `NODE_ENV` | `production` | Standard |
| `PORT` | `4000` | Render maps the public 443 → 4000 |
| `CORS_ORIGIN` | `*` (tighten later) | App/web origins |
| `SEED_ON_BOOT` | `true` first time, then `false` | Runs seed script on boot |

### Seeded test accounts

All seeded users share the password `Password123!`:

- `superadmin@asmc.test`
- `hr@asmc.test`
- `supervisor@asmc.test`
- 5 employee accounts (see `api/prisma/seed.ts`)

---

## 2. Alternative API hosts

The same `api/Dockerfile` works on any platform that runs OCI images and gives
you `DATABASE_URL` + `JWT_SECRET`:

- **Fly.io** — `flyctl launch --dockerfile api/Dockerfile`, attach a Postgres,
  `flyctl secrets set JWT_SECRET=...`.
- **Railway / Koyeb / Northflank** — point at `api/Dockerfile`, attach managed
  Postgres, set the env vars from the table above.
- **Bare VM** — `docker build -t asmc-api -f api/Dockerfile api && docker run -p
  4000:4000 -e DATABASE_URL=... -e JWT_SECRET=... asmc-api`.

Generate strong secrets:

```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

## 3. Local "production-ish" run (Docker Compose)

To verify the prod setup locally before pushing:

```bash
# Start Postgres only (recommended for dev)
docker compose up -d db

# Run the API against it
cd api
cp .env.example .env
npm install
npx prisma migrate deploy
npm run seed          # one-shot
npm run build && npm start
```

`http://localhost:4000/api/health` should return ok.

---

## 4. Flutter app — release builds

Bake the production API URL in at build time via `--dart-define`. The default
when none is provided is `http://10.0.2.2:4000/api` (Android emulator → host
machine), which is only useful for local dev.

### Android (APK + AAB)

```bash
cd app

# APK for sideloading / internal QA
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-render-app>.onrender.com/api
# → build/app/outputs/flutter-apk/app-release.apk

# AAB for Play Store
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<your-render-app>.onrender.com/api
# → build/app/outputs/bundle/release/app-release.aab
```

#### Android signing (one-time, for Play Store)

The repo ships with debug signing only. For Play Store you need a release
keystore. The standard Flutter recipe:

1. Generate a keystore (keep it OUT of git):
   ```bash
   keytool -genkey -v -keystore ~/asmc-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `app/android/key.properties` (gitignored — see `.gitignore`):
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=/absolute/path/to/asmc-upload.jks
   ```
3. In `app/android/app/build.gradle.kts` add a `signingConfigs.release` block
   that reads `key.properties` and reference it from `buildTypes.release`. See
   the Flutter docs: <https://docs.flutter.dev/deployment/android#signing-the-app>.

### iOS

```bash
cd app
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://<your-render-app>.onrender.com/api
# → build/ios/ipa/asmc_app.ipa
```

iOS signing requires an Apple Developer account, a distribution cert and a
provisioning profile — configure via Xcode (`Runner.xcworkspace`) or an
`ExportOptions.plist` for CI.

### Distribution

- **Android**: upload the `.aab` to Play Console (or distribute the APK via
  Firebase App Distribution for internal testers).
- **iOS**: upload the `.ipa` to App Store Connect / TestFlight.

---

## 5. Firebase (FCM, Storage) — optional

The app currently scaffolds for Firebase but does not require it.

1. Create a Firebase project; add Android + iOS apps.
2. Drop `google-services.json` into `app/android/app/` and
   `GoogleService-Info.plist` into `app/ios/Runner/`.
3. Add `firebase_core` + `firebase_messaging` to `pubspec.yaml` and call
   `Firebase.initializeApp()` in `main.dart`.
4. Add an FCM token endpoint on the API and wire push notifications.

---

## 6. Observability

- **API**: ship `pino-http` logs to Datadog/Logtail. Add `/api/health` to your
  uptime monitor (Render has a built-in health check pointed at this path).
- **App**: integrate Crashlytics or Sentry-Flutter; the API client already
  normalizes errors via `ApiException` so you can `await Sentry.captureException`
  inside the Dio interceptor.

---

## 7. Security checklist

- [ ] HTTPS enforced (Render does this automatically).
- [ ] `CORS_ORIGIN` set to known origins only (not `*`).
- [ ] Strong `JWT_SECRET` (Render generates one — don't replace by hand).
- [ ] Rotate secrets every 90 days.
- [ ] Database backups enabled (Render Postgres ships with daily snapshots).
- [ ] Rate-limit `/api/auth/*` (`express-rate-limit` is already installed —
      wire it before exposing publicly).
- [ ] `SEED_ON_BOOT=false` after the very first deploy.
- [ ] `helmet` strict CSP headers (already enabled, tune per app needs).
