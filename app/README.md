# ASMC App

Cross-platform Flutter application (Android, iOS, Tablet) for the ASMC workforce
management system.

## Stack

- Flutter ≥ 3.24 + Dart ≥ 3.5
- Material 3 (light + dark)
- **Riverpod** for state management
- **GoRouter** for navigation
- **Dio** for HTTP with a JWT refresh interceptor
- `flutter_secure_storage` for tokens, `local_auth` for biometrics
- `fl_chart` for dashboards (used by the future Reports module)

## Run

```bash
flutter pub get

# default API_BASE_URL = http://10.0.2.2:4000/api (Android emulator)
flutter run

# iOS / desktop / web
flutter run --dart-define=API_BASE_URL=http://localhost:4000/api

# Real device on Wi-Fi
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:4000/api
```

## Static analysis

```bash
flutter analyze
flutter test
```

## Folder layout

```
app/lib/
├── main.dart
├── core/
│   ├── env.dart                # API_BASE_URL via --dart-define
│   ├── theme/                  # Material 3 + navy/emerald palette
│   ├── network/                # Dio + JWT interceptor + ApiException
│   ├── storage/                # secure_storage wrapper
│   ├── routing/app_router.dart # GoRouter w/ auth-aware redirect
│   ├── utils/                  # responsive, formatters
│   └── widgets/                # AsyncValueView, RoleBadge, StatusPill
└── features/
    ├── auth/        domain → data → application → presentation
    ├── employees/   "
    ├── clients/     "
    ├── deployments/ "
    ├── dashboard/
    ├── shell/
    └── placeholder/
```

Every feature follows the same shape: `domain` (POJO models), `data` (repository
that owns Dio calls), `application` (Riverpod providers), `presentation`
(ConsumerWidget screens).

## Auth flow

1. `splash_screen` boots `AuthController.bootstrap()`.
2. If a refresh token is in secure storage and not expired, the user lands on
   `/dashboard`. Otherwise on `/login`.
3. Login persists `{accessToken, refreshToken, user}` to secure storage.
4. The Dio interceptor adds `Authorization: Bearer ...` and on 401 swaps in a
   refreshed access token transparently.
5. `setBiometricEnabled(true)` lets the user unlock subsequent launches with
   fingerprint / Face ID via `local_auth`.

## Role-based UI

The shell reads the current `AppRole` and filters the side-nav. The Dashboard
swaps in a different body per role (Admin / Supervisor / Client / Employee).

## Modules implemented end-to-end

- **Employees** — list (search + availability filter), detail, add, edit,
  soft-delete, status display, document fields, salary.
- **Clients** — list, detail with hiring history, add, edit, soft-delete,
  active manpower count.
- **Deployments** — list (status filter), detail, **assign with availability +
  conflict check**, edit, cancel.

## Placeholder modules

`Attendance`, `Payroll`, `Invoices`, `Contracts`, `Reports`, `Notifications`,
`Settings` render a "Coming soon" screen and reserve their navigation slot.
The DB schema for each already exists on the API.
