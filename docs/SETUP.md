# FLETEGO — Setup

## Prerequisites

| Tool | Purpose | Notes |
|------|---------|-------|
| Flutter (stable) | Mobile app | Required for Phase 1+ |
| Xcode | iOS builds | Full Xcode app (not only CLT) |
| Android Studio / SDK | Android builds | JDK 17 recommended |
| Supabase CLI | Migrations / local stack | Optional early; needed before backend Phase 2+ |
| Docker | Local Supabase | Required if using `supabase start` |
| Node.js 20+ | Admin app (Phase 13) | Not needed for mobile MVP loop |

### Machine status (updated after Phase 1)

| Tool | Status |
|------|--------|
| Flutter stable 3.47 | Installed at `~/flutter` — add to PATH |
| `flutter analyze` / `flutter test` | Passing for `apps/mobile` |
| Xcode (full) | Still required for iOS/macOS device builds |
| Android SDK | Still required for Android builds |
| Chrome | Available for `flutter run -d chrome` |

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd apps/mobile
flutter run -d chrome
```


---

## 1. Install Flutter (macOS arm64)

```bash
# Option A — official clone
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$HOME/flutter/bin:$PATH"
flutter doctor
```

Or install via the [Flutter install guide](https://docs.flutter.dev/get-started/install/macos).

Accept Android licenses when prompted:

```bash
flutter doctor --android-licenses
```

---

## 2. Clone & project layout

```bash
cd /path/to/FLETEGO
# After Phase 1:
cd apps/mobile
flutter pub get
```

---

## Apply database migrations

In the Supabase Dashboard → **SQL Editor**, paste and run the **file contents** (not the path) of each migration in order:

1. `supabase/migrations/20260812150000_phase2_profiles.sql`
2. `supabase/migrations/20260813010000_phase3_companies.sql`
3. `supabase/migrations/20260813120000_phase4_vehicles_drivers.sql`
4. `supabase/migrations/20260817010000_fix_list_company_members.sql`
5. `supabase/migrations/20260817020000_phase5_cargo_requests.sql`
6. `supabase/migrations/20260817030000_phase6_offers_matching.sql`
7. `supabase/migrations/20260818010000_phase7_trip_management.sql`
8. `supabase/migrations/20260818011000_backfill_missing_trips.sql` (si hace falta)
9. `supabase/migrations/20260818020000_phase8_location_tracking.sql`
10. `supabase/migrations/20260818030000_phase9_chat_notifications.sql`
11. `supabase/migrations/20260818040000_phase10_pod.sql`
12. `supabase/migrations/20260818050000_phase11_ratings.sql`
13. `supabase/migrations/20260818060000_phase12_company_essentials.sql`
14. `supabase/migrations/20260818061000_fix_phase12_rls_recursion.sql` (si ya corriste phase12 antes del fix)
15. `supabase/migrations/20260818070000_phase13_admin.sql`
16. `supabase/migrations/20260818100000_phase14_hardening.sql`

Or with CLI (after `supabase login` + link):

```bash
supabase db push
```

Auth settings recommended for MVP:

- Authentication → Providers → Email enabled  
- Confirm email: optional for development (`enable_confirmations = false`)  
- Site URL / redirect: add your app deep link when ready  

### Mobile env

```bash
# Edit apps/mobile/.env
SUPABASE_URL=https://vggicqkulqmvxghjfokc.supabase.co
SUPABASE_ANON_KEY=<paste anon public key>
DEMO_MODE=false
```

Then:

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd apps/mobile
flutter pub get
# Prefer secrets via dart-define (do not bundle .env in the binary):
./scripts/run_chrome.sh
# equivalent:
# flutter run -d chrome --dart-define-from-file=.env
```

Promote first admin: see `docs/ADMIN_BOOTSTRAP.md`.

### Admin web (Phase 13)

```bash
# Apply 20260818070000_phase13_admin.sql first
cd apps/admin
cp .env.example .env.local
# Fill NEXT_PUBLIC_SUPABASE_* and SUPABASE_SERVICE_ROLE_KEY

# Promote an existing user (SQL Editor):
# update profiles set platform_role = 'super_admin' where email = '...';

npm install
npm run dev
# http://localhost:3000
```

---

## 4. Supabase (when ready)

```bash
# Install CLI: https://supabase.com/docs/guides/cli
supabase login
supabase link --project-ref <ref>
supabase db push
supabase db seed   # when seed scripts exist
```

Local:

```bash
supabase start
```

---

## 5. Run mobile app

```bash
cd apps/mobile
flutter analyze
flutter test
flutter run
```

Demo mode (no backend): use `AppConfig.demoMode` / flavor documented after Phase 1.

---

## 6. Verify checklist

- [ ] `flutter doctor` clean enough for target platform  
- [ ] `flutter analyze` no errors  
- [ ] `flutter test` passes  
- [ ] App launches to splash/welcome  

---

*Last updated: Phase 0 — 2026-08-12*
