# Architecture & design

This document captures the high-level architecture, design decisions, and the
roadmap for modules not yet implemented end-to-end.

## Goals

- One codebase across Android, iOS, and tablets (Material 3, responsive).
- Clean separation between UI, state, domain, and data layers.
- A backend that is small enough to read in one sitting, but structured so
  every new module follows the same shape.
- Auth that "just works" — JWT + refresh + biometric — without leaking tokens
  into the UI layer.

## Backend (`api/`)

```
api/src/
├── app.ts            # Express factory (helmet, cors, rate-limit, logger, routes)
├── server.ts         # boot wrapper
├── config/           # env loader, JWT/Prisma singletons
├── middleware/       # auth, role-gate, error normalizer
├── modules/
│   ├── auth/         # auth.service.ts + auth.controller.ts + auth.routes.ts
│   ├── employees/
│   ├── clients/
│   └── deployments/  # includes conflict detection + availability + stats
└── routes/index.ts   # mounts all module routers under /api
```

### Modules follow a consistent shape

- `*.schema.ts` — Zod schemas for request validation + types
- `*.service.ts` — pure DB / business logic, returns POJOs
- `*.controller.ts` — Express handlers, parse / validate / call service / shape response
- `*.routes.ts` — wires path → middleware → controller

This makes a new module a 4-file copy/paste rather than wiring through a DI container.

### Auth flow

1. `POST /api/auth/login` returns `{ user, accessToken, refreshToken }`.
2. The Flutter app stores both via `flutter_secure_storage` (Keychain / Keystore).
3. Every request adds `Authorization: Bearer <accessToken>`.
4. On 401 the Dio interceptor calls `POST /api/auth/refresh` with the refresh
   token, swaps in a new access token, and retries the request once.
5. On refresh failure the app fires `onUnauthorized` and the auth controller
   force-logs-out the user.

### Deployment conflict detection

`deployments.service.create()` runs an overlap query before insert:

```sql
EXISTS (
  start_date <= :end AND
  (end_date IS NULL OR end_date >= :start) AND
  status IN ('SCHEDULED','ACTIVE') AND
  employeeId = :employeeId
)
```

If overlapping, the API returns 409 with a structured `code:"DEPLOYMENT_CONFLICT"`
and the Flutter form surfaces it inline. `GET /deployments/availability?startDate=&endDate=`
returns the **complement** — employees with **no** overlapping deployment in the
selected window — to power the "Available employees" picker in the form.

## Flutter app (`app/`)

```
app/lib/
├── core/
│   ├── env.dart           # API_BASE_URL via --dart-define
│   ├── theme/             # Material 3 + navy/emerald palette + dark/light
│   ├── network/           # Dio + JWT interceptor + ApiException
│   ├── storage/           # secure_storage wrapper
│   ├── routing/app_router.dart  # GoRouter w/ auth-aware redirect
│   ├── utils/             # responsive, formatters
│   └── widgets/           # AsyncValueView, RoleBadge, StatusPill, EmptyState
└── features/
    ├── auth/              # splash, login, register, forgot, OTP, biometric
    ├── employees/         # domain → repo → providers → screens
    ├── clients/
    ├── deployments/
    ├── dashboard/         # role-aware metrics + recent activity
    ├── shell/             # NavigationRail (wide) + NavigationBar/Drawer (phone)
    └── placeholder/       # 7 modules waiting for implementation
```

Every feature folder is **flat across `domain → data → application → presentation`**:

- `domain/`: plain Dart models with `fromJson`. No Flutter imports.
- `data/`: a `*Repository` that owns Dio calls.
- `application/`: Riverpod providers (state + futures).
- `presentation/`: ConsumerWidgets only — they read providers and render.

This gives every module the same "shape", so onboarding to a new feature is a
matter of opening the same four folders.

### State management

- `AuthController` (Notifier) holds session state and exposes login / logout /
  bootstrap / biometric.
- List/detail data uses `FutureProvider.autoDispose(.family)` so screens don't
  leak memory and we get free retry-on-mount.
- Filters live in dedicated `StateProvider`s so search/filter changes recompute
  the list without rebuilding the form.

### Routing

`GoRouter` with a single redirect that:

- Sends unauthenticated users to `/login`.
- Sends authenticated users away from public routes (`/login`, `/register`, ...)
  back to `/dashboard`.
- Holds them on `/splash` while the auth controller boots.

## Roadmap (post-foundation)

The placeholder routes show a friendly "Coming soon" but the database tables
already exist for each module:

| Module | DB tables | Next step |
| --- | --- | --- |
| Attendance | `Attendance` | QR + GPS punch endpoints, supervisor approve, daily report |
| Payroll | `Payroll`, `PayrollItem` | salary calc job, payslip PDF, monthly run |
| Invoices | `Invoice`, `InvoiceItem` | client invoice generation, PDF, payment tracking |
| Contracts | `Contract` | upload PDFs, expiry alerts, renewal workflow |
| Notifications | `Notification` | in-app feed + FCM fan-out from server-side events |
| Reports | (views) | dashboards on top of FL chart, CSV / PDF export |
| Settings | (preferences) | profile edit, theme, language, biometric toggle |

Because each existing feature already follows the `domain → data → application
→ presentation` layout, adding a new module is mostly mechanical.

## Decisions worth keeping

- **No code generation** for models — Dart classes with hand-written `fromJson`
  are easy to read and don't depend on `build_runner`. We can adopt `freezed`
  later if the team wants exhaustive pattern matching.
- **Flat repository layer, no use cases** — most screens just need
  "list, getById, create, update, delete". Adding a use-case layer was pure
  overhead. If a screen ever needs orchestration we'll add it then.
- **SQLite in dev, Postgres in prod** — same Prisma schema, change one line.
  Lets contributors clone + run without standing up a DB.
- **No Firebase yet** — the app boots without Firebase config. We'll wire
  Firebase Auth + FCM + Storage when the related features land.
