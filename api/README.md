# ASMC API

Express + TypeScript + Prisma backend for the ASMC workforce management app.

## Stack

- Node.js (≥ 20) + Express 4
- TypeScript (strict)
- Prisma (SQLite in dev, Postgres-ready)
- JWT auth (access + refresh) with bcrypt
- Zod for input validation
- Helmet, CORS, morgan request logging

## Run locally

```bash
cp .env.example .env
npm install
npm run prisma:migrate
npm run seed
npm run dev          # http://localhost:4000
```

Smoke test:

```bash
curl http://localhost:4000/api/health
```

## Project layout

```
api/
├── prisma/
│   ├── schema.prisma   # 13 models for the full product
│   ├── migrations/
│   └── seed.ts         # 5 roles + employees + clients + deployments
└── src/
    ├── server.ts
    ├── app.ts
    ├── config/         # env + JWT + Prisma singletons
    ├── middleware/     # auth, role, error
    ├── modules/
    │   ├── auth/
    │   ├── employees/
    │   ├── clients/
    │   └── deployments/
    └── routes/index.ts
```

## API surface (current)

### Auth (`/api/auth`)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/register` | Public sign-up (becomes EMPLOYEE by default) |
| POST | `/login` | Email + password → tokens |
| POST | `/refresh` | Exchange refresh for new access token |
| POST | `/logout` | Invalidate refresh token |
| POST | `/forgot-password` | Issue OTP (logged to server console in dev) |
| POST | `/verify-otp` | Verify OTP for password-reset purpose |
| POST | `/reset-password` | Set a new password using a verified OTP |
| GET | `/me` | Current user (requires bearer) |

### Employees (`/api/employees`) — HR_ADMIN / SUPER_ADMIN

| Method | Path |
| --- | --- |
| GET | `/?q=&availability=&department=&page=&pageSize=` |
| GET | `/:id` |
| POST | `/` |
| PATCH | `/:id` |
| DELETE | `/:id` (soft delete — sets `isActive=false`) |

### Clients (`/api/clients`) — HR_ADMIN / SUPER_ADMIN / SUPERVISOR

| Method | Path |
| --- | --- |
| GET | `/?q=&industry=&page=&pageSize=` |
| GET | `/:id` |
| GET | `/:id/hiring-history` |
| POST | `/` |
| PATCH | `/:id` |
| DELETE | `/:id` (soft delete) |

### Deployments (`/api/deployments`) — admins + supervisors

| Method | Path |
| --- | --- |
| GET | `/?q=&status=&employeeId=&clientId=&page=&pageSize=` |
| GET | `/:id` |
| GET | `/availability?startDate=&endDate=` — list workers free in window |
| GET | `/stats` — counts for the dashboard |
| POST | `/` — **rejects with 409 on conflict** |
| PATCH | `/:id` |
| DELETE | `/:id` (cancels and frees the worker) |

## Conflict detection

`POST /deployments` and `PATCH /deployments/:id` will **reject** with 409 if the
employee already has a `SCHEDULED` or `ACTIVE` deployment overlapping the
requested window:

```ts
overlapping = await prisma.deployment.findFirst({
  where: {
    employeeId,
    status: { in: ['SCHEDULED', 'ACTIVE'] },
    AND: [
      { startDate: { lte: endDate ?? maxDate } },
      {
        OR: [
          { endDate: null },
          { endDate: { gte: startDate } },
        ],
      },
    ],
  },
});
```

## Environment

| Var | Example |
| --- | --- |
| `DATABASE_URL` | `file:./dev.db` (SQLite) or `postgresql://...` |
| `JWT_SECRET` | random hex |
| `JWT_REFRESH_SECRET` | random hex (different from `JWT_SECRET`) |
| `ACCESS_TOKEN_TTL` | `15m` |
| `REFRESH_TOKEN_TTL` | `30d` |
| `PORT` | `4000` |
| `CORS_ORIGIN` | `http://localhost:3000,http://10.0.2.2:3000` |

## Scripts

| Command | What it does |
| --- | --- |
| `npm run dev` | tsx watch mode |
| `npm run build` | TypeScript compile to `dist/` |
| `npm run start` | `node dist/server.js` |
| `npm run lint` | ESLint |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run prisma:migrate` | Apply migrations + regenerate Prisma client |
| `npm run prisma:studio` | Open Prisma Studio |
| `npm run seed` | Run `prisma/seed.ts` |
