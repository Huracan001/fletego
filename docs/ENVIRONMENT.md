# FLETEGO — Environment configuration

## Principles

1. **No secrets in git** — only `.env.example` with placeholders.  
2. **Flutter is untrusted** — only public keys (`SUPABASE_ANON_KEY`, maps browser/mobile key with restrictions).  
3. **Service role** — server/admin/CI only; never shipped in the mobile binary.  
4. **Flavors** — `development`, `staging`, `production` with distinct Supabase projects when possible.

---

## Client (Flutter) variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes (prod) | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes (prod) | Public anon key |
| `MAPS_API_KEY` | For maps | Google Maps / Places (or provider key) |
| `APP_ENV` | Yes | `development` \| `staging` \| `production` |
| `DEMO_MODE` | No | `true` enables mock repositories |

Example (see repo root `.env.example`):

```
APP_ENV=development
DEMO_MODE=true
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your_anon_key
MAPS_API_KEY=your_maps_key
```

Injection approach (Phase 1): `--dart-define` / `--dart-define-from-file` or `flutter_dotenv` with gitignored files. Prefer compile-time defines for release builds.

---

## Server / admin only (never in Flutter)

| Variable | Where |
|----------|--------|
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions, Next.js admin (`apps/admin`), CI |
| Payment provider secrets | Server only (future) |
| Push certs / FCM server key | CI / backend |

---

## Supabase dashboard checklist

- Auth: email enabled; site URL / redirect URLs for app deep links  
- RLS enabled on all user data tables  
- Storage buckets private  
- Separate projects for staging vs production  

---

*Last updated: Phase 0 — 2026-08-12*
