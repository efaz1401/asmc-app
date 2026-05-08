# Local development setup

This guide walks through setting up the ASMC backend + Flutter app on a fresh machine.

## Prerequisites

| Tool | Version |
| --- | --- |
| Node.js | ≥ 20 (tested on v22.12.0) |
| npm | bundled with Node |
| Flutter | ≥ 3.24 (stable channel) |
| Dart | ≥ 3.5 (bundled with Flutter) |
| Android Studio / Xcode | platform SDKs for iOS / Android emulators |

## 1. Clone the repo

```bash
git clone https://github.com/dennisstraw30-lab/asmc-management-software.git
cd asmc-management-software
```

## 2. Backend — `api/`

```bash
cd api
cp .env.example .env
npm install
npm run prisma:migrate     # creates ./prisma/dev.db (SQLite)
npm run seed               # inserts 5 roles + employees + clients + deployments
npm run dev                # → http://localhost:4000
```

The server logs `🚀 ASMC API listening on http://localhost:4000` once ready.

Smoke check:

```bash
curl http://localhost:4000/api/health
# {"status":"ok","time":"...","version":"0.1.0"}

curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"superadmin@asmc.test","password":"Password123!"}' | jq .user
```

### Switching to Postgres

Update `DATABASE_URL` in `.env` and the `provider` in `api/prisma/schema.prisma`:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

Then `npm run prisma:migrate` will spin up Postgres migrations.

## 3. Flutter app — `app/`

```bash
cd ../app
flutter pub get
```

### Pointing the app at the API

By default the app uses `http://10.0.2.2:4000/api` (Android emulator's loopback to host).
Override at run time:

```bash
# iOS simulator / desktop
flutter run --dart-define=API_BASE_URL=http://localhost:4000/api

# Real device on Wi-Fi
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:4000/api
```

### Run on an emulator

```bash
flutter emulators --launch <id>
flutter run
```

### Hot reload tips

- `r` reload, `R` full restart, `q` quit
- `flutter analyze` runs static analysis
- `flutter test` runs the (currently scaffolded) test suite

## 4. Logging in

Log in with any of the seeded accounts (password `Password123!`):

| Role | Email |
| --- | --- |
| Super Admin | superadmin@asmc.test |
| HR / Admin | hr@asmc.test |
| Supervisor | supervisor@asmc.test |
| Employee | alice@asmc.test |
| Client | client1@acme.test |

Each role gets a different dashboard and side-nav entries.

## 5. Useful npm scripts (`api/`)

| Command | What it does |
| --- | --- |
| `npm run dev` | Start API in watch mode |
| `npm run build` | TypeScript compile |
| `npm run lint` | ESLint |
| `npm run typecheck` | tsc --noEmit |
| `npm run prisma:migrate` | Run Prisma migrations |
| `npm run seed` | (Re-)populate dummy data |

## Troubleshooting

- **"Connection refused" from Flutter**: confirm the API is on port 4000 and the
  `--dart-define=API_BASE_URL=` matches your platform (10.0.2.2 vs localhost vs LAN IP).
- **"Token expired" loops**: clear app storage from the device's app info; the JWT
  refresh interceptor will get a fresh pair on next login.
- **Biometric login fails**: enroll a fingerprint/face on the emulator first
  (Android Studio → Extended Controls → Fingerprint).
