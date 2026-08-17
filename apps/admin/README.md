# FLETEGO Admin

Next.js panel for platform operators (`profiles.platform_role` = `admin` | `super_admin`).

## Setup

1. Apply SQL: `supabase/migrations/20260818070000_phase13_admin.sql`
2. Copy `.env.example` → `.env.local` and fill:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY` (server only)
3. Promote yourself (SQL Editor):

```sql
update public.profiles
set platform_role = 'super_admin'
where email = 'tu@correo.com';
```

4. Run:

```bash
cd apps/admin
npm install
npm run dev
```

Open http://localhost:3000 — sign in with the same Supabase email/password as the mobile app.

## Surfaces

| Route | Purpose |
|-------|---------|
| `/` | Counts: pending verification, disputes, trips, users |
| `/verification` | Approve/reject companies, drivers, vehicles, documents |
| `/users` | List profiles; promote roles; soft-delete |
| `/trips` | Recent trips + disputed highlight |
| `/disputes` | Structured `disputes` + trips in `disputed` |
| `/config` | `vehicle_types` active flag + `app_config` |

Privileged writes use the **service role** only after `requireAdmin()` checks the session user.
