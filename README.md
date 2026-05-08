# ASMC Workforce Management

A cross-platform workforce management platform for staffing / contracting companies.

| Layer | Stack |
| --- | --- |
| Mobile + Tablet | Flutter (Material 3, Riverpod, GoRouter, Dio) |
| Backend | Node.js + Express + TypeScript + Prisma |
| Database | SQLite for local dev, drop-in Postgres for production |
| Auth | JWT (access + refresh) + bcrypt + biometric unlock |

## Repository layout

```
asmc-management-software/
├── api/                  # Node.js + Express + Prisma backend
│   ├── prisma/           # Schema, migrations, seed data
│   └── src/              # Modules (auth, employees, clients, deployments, ...)
├── app/                  # Flutter app (Android, iOS, Tablet)
│   └── lib/
│       ├── core/         # Theme, routing, network, storage, utils, widgets
│       └── features/     # Auth, employees, clients, deployments, dashboard, shell, ...
└── docs/                 # PLAN.md, SETUP.md, DEPLOYMENT.md
```

## Quickstart

```bash
# 1) Backend
cd api
cp .env.example .env
npm install
npm run prisma:migrate
npm run seed
npm run dev   # → http://localhost:4000

# 2) Flutter app (in another terminal)
cd app
flutter pub get
flutter run    # pick Android emulator / iOS simulator / device
```

For Android emulator the app talks to the host via `http://10.0.2.2:4000/api`.
For iOS simulator / desktop use `http://localhost:4000/api`. You can override with:

```bash
flutter run --dart-define=API_BASE_URL=https://your.api.example.com/api
```

## Seeded login credentials

All accounts share the password `Password123!`.

| Role | Email |
| --- | --- |
| Super Admin | superadmin@asmc.test |
| HR / Admin | hr@asmc.test |
| Supervisor | supervisor@asmc.test |
| Employees | alice@asmc.test, bob@asmc.test, carla@asmc.test, derek@asmc.test, ella@asmc.test |
| Clients | client1@acme.test, client2@globex.test, client3@initech.test |

## What's in this PR

This PR delivers a **production-ready foundation** plus three modules end-to-end:

- ✅ Auth (login, register, forgot password, OTP, JWT refresh, biometric)
- ✅ Employees (list, search/filter, detail, add, edit, soft-delete)
- ✅ Clients (list, search, detail with hiring history, add, edit, soft-delete)
- ✅ Deployments (list, detail, assign with **availability + conflict checking**, edit, cancel)
- ✅ Role-aware dashboard for Super Admin / HR / Supervisor / Client / Employee
- ✅ Shell with sidebar (tablet/desktop) and bottom-nav + drawer (phone)
- ✅ Placeholder screens for Attendance, Payroll, Invoices, Contracts, Reports, Notifications, Settings

See [`docs/PLAN.md`](docs/PLAN.md) for architecture details and [`docs/SETUP.md`](docs/SETUP.md) for step-by-step setup.

## License

Internal — © ASMC.
