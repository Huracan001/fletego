# FLETEGO

**FLETEGO by Pick&Truck** — Move cargo. Move business.

Marketplace for heavy transportation: cargo owners request the right truck for a route; transporters find compatible loads and reduce empty returns.

| | |
|--|--|
| Mobile | Flutter (iOS & Android) — `com.fletego.app` |
| Backend | Supabase (Auth, PostgreSQL, Storage, Realtime) |
| Admin | Next.js (`apps/admin`, Phase 13) |
| Market | Bolivia-first (BOB / Bs), multi-country ready |

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md) | Phased implementation plan |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System & app architecture |
| [docs/DATABASE.md](docs/DATABASE.md) | Domain model & schema proposal |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Architecture decision records |
| [docs/SETUP.md](docs/SETUP.md) | Local development setup |
| [docs/ENVIRONMENT.md](docs/ENVIRONMENT.md) | Environment variables |
| [docs/MOBILE_RELEASE.md](docs/MOBILE_RELEASE.md) | Store release checklist |

---

## Current status

**Phase 0 complete** — workspace inspected, plan and architecture documented.  
**Phase 1 complete** — Flutter foundation.  
**Phase 2 complete** — Auth working.  
**Phase 3 complete** — Companies, members, roles.  
**Phase 5 complete** — Customer cargo request wizard. Run Phase 5 SQL migration.

**Phase 6 next** — Matching + offers.

Repository layout:

```
apps/mobile/     Flutter application (com.fletego.app)
apps/admin/      Next.js admin (Phase 13)
supabase/        Migrations, seeds, Edge Functions (starting Phase 2+)
docs/            Architecture & plans
```

---

## Security

- Never commit secrets or `SUPABASE_SERVICE_ROLE_KEY`.
- Flutter uses only the anon key + user JWT; RLS enforces access.
- Copy `.env.example` → local env files (gitignored).

---

## Brand

| Token | Value |
|-------|-------|
| Primary | `#1769FF` |
| Navy | `#0B1220` |
| Success | `#20C77A` |
| Background | `#F6F8FC` |
| Font | Inter |
