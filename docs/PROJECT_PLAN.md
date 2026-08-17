# FLETEGO — Project Plan

**Product:** FLETEGO by Pick&Truck  
**Tagline:** Move cargo. Move business.  
**Scope:** Production-minded MVP for a Bolivia-first heavy transportation marketplace  
**Stack:** Flutter (iOS/Android) + Supabase (Auth, PostgreSQL, Storage, Realtime, Edge Functions)

---

## 0. Workspace status (Phase 0 inspection)

| Item | Status |
|------|--------|
| Repository | Empty git repo (`main`, no commits, no source files) |
| Flutter SDK | **Not installed** |
| Dart SDK | **Not installed** |
| Homebrew | **Not found** in PATH |
| Node.js / npm | **Not found** |
| Supabase CLI | **Not found** |
| Docker | **Not found** |
| Xcode | Command Line Tools only (`/Library/Developer/CommandLineTools`) — full Xcode needed for iOS |
| Android SDK / Java | **Not found** |

**Implication:** Phase 1 cannot run `flutter create` / `flutter analyze` until the Flutter toolchain is installed. Documentation and repository structure proceed first; foundation code follows once Flutter is available.

---

## 1. MVP success loop (non-negotiable)

The MVP is complete only when this loop works end-to-end:

1. Customer creates a cargo request  
2. Compatible transporter sees it  
3. Transporter submits an offer  
4. Customer accepts the offer  
5. Trip is created and assigned  
6. Driver updates trip status through pickup → transit → delivery  
7. Customer can track the trip  
8. Driver uploads proof of delivery  
9. Trip completes  
10. Both parties rate each other  

Everything else is supporting infrastructure or post-MVP.

---

## 2. Repository layout (target)

```
FLETEGO/
├── apps/
│   ├── mobile/                 # Flutter app (com.fletego.app)
│   └── admin/                  # Next.js admin (Phase 13)
├── supabase/
│   ├── migrations/             # Versioned SQL migrations
│   ├── seed/                   # Dev seed data (Bolivia)
│   ├── functions/              # Edge Functions (matching, signed URLs, etc.)
│   └── config.toml
├── docs/
│   ├── PROJECT_PLAN.md
│   ├── ARCHITECTURE.md
│   ├── DATABASE.md
│   ├── DECISIONS.md
│   ├── SETUP.md
│   ├── ENVIRONMENT.md
│   └── MOBILE_RELEASE.md
├── .env.example
├── .gitignore
└── README.md
```

Monorepo keeps mobile, admin, and backend schema in one place without premature microservices.

---

## 3. Phase roadmap

### Phase 0 — Analysis ✅

- Inspect workspace  
- Architecture, decisions, database proposal  
- Identify contradictions and resolve them  

### Phase 1 — Foundation ✅

- Flutter SDK installed (`~/flutter`, stable 3.47)  
- `apps/mobile` created (`com.fletego.app`)  
- Design tokens + theme (Inter via google_fonts)  
- Design system components + brand mark  
- Feature-first folders, Riverpod, GoRouter  
- Spanish/English ARB l10n scaffold  
- Env/`AppConfig` + demo-safe Supabase init  
- Splash → Welcome → onboarding intent → login/signup shells  
- `TripStateService` + unit/widget tests  
- Verified: `flutter analyze`, `flutter test`

### Phase 2 — Authentication & onboarding ✅

- `.env` with project URL; anon key placeholder for local paste  
- `AuthRepository` + `AuthController` (session stream)  
- Login, signup, password reset (Spanish errors)  
- Onboarding intent → profile flags + home shell by role  
- Auth gate via GoRouter redirect  
- Migration: `profiles` + trigger + RLS  
- Verified: `flutter analyze`, `flutter test`

### Phase 3 — User / company model ✅

- Migration: `companies`, `company_members`, roles, RLS helpers  
- RPCs: `create_company`, `add_company_member_by_email`  
- Central `CompanyPermissionService` matrix  
- UI: create company, detail, members, invite by email, role change  
- Manager home lists companies  
- Verified: `flutter analyze`, `flutter test`

### Phase 4 — Vehicles / drivers ✅

- Migration: vehicle_types (seed), driver_profiles, vehicles, driver_vehicles, docs, availability  
- RPC `ensure_driver_profile`  
- Driver home: vehicles, profile, “Estoy disponible”  
- Independent vehicle registration + link to driver  
- Document metadata (license) — file upload later via Storage  
- Verified: `flutter analyze`, `flutter test`  

### Phase 5 — Customer request flow ✅

- Migration: `cargo_requests`, `containers`, `submit_cargo_request` RPC  
- 8-step wizard (tipo → origen → destino → detalles → camión → fecha → extras → review)  
- “No sé qué camión necesito” + `VehicleCompatibilityService` (reglas)  
- Ciudades BO preset con coordenadas (sin Maps key)  
- Mis solicitudes  
- Verified: `flutter analyze`, `flutter test`

### Phase 6 — Matching / offers ✅

- Migration: `offers`, `trips` (+ history), marketplace RLS, `create_offer` / `accept_offer` / `list_marketplace_loads`  
- `MatchingService` (tipo, peso, equipo, disponibilidad, proximidad)  
- Driver marketplace: cargas rankeadas + envío de oferta  
- Cliente: listar / ordenar / aceptar oferta → viaje `assigned`  
- Verified: `flutter analyze`, `flutter test`

### Phase 7 — Trip management ✅

- Migration: `advance_trip_status`, `cancel_trip`, `soft_delete_trip`, `can_access_trip`  
- `TripStateService` + historial  
- UI conductor (pasos) + cliente (estado / completar)  
- Cancelación + soft delete (sin hard delete)  
- Verified: `flutter analyze`, `flutter test`

### Phase 8 — Maps / tracking ✅

- Migration: `location_updates`, `post_trip_location`, `get_trip_latest_location`  
- `MapService` (Mock + Google stub) + `FletegoMap` esquemático sin key  
- ETA/distancia haversine; tracking solo con consentimiento en viaje activo  
- Panel en detalle de viaje (conductor comparte ubicación demo)  
- Verified: `flutter analyze`, `flutter test`

### Phase 9 — Chat / notifications ✅

- Migration: `messages`, `message_attachments`, `notifications`, `push_tokens`  
- Chat por viaje + notificación in-app al peer  
- `PushNotificationService` (NoOp) listo para FCM/APNs  
- Centro de notificaciones + acceso desde home / detalle de viaje  
- Fix: tracking sin ubicación ya no muestra error falso  
- Verified: `flutter analyze`, `flutter test`

### Phase 10 — Delivery / POD ✅

- Migration: `pickup_evidence`, `proof_of_delivery`, RPCs submit  
- UI en detalle de viaje: recogida + POD (receptor, firma, fotos demo, GPS, timestamp)  
- Al registrar POD puede marcar viaje `delivered`  
- Verified: `flutter analyze`, `flutter test`

### Phase 11 — Ratings ✅

- Migration: `ratings`, `submit_rating` (actualiza `rating_avg` del conductor)  
- Dimensiones cliente→conductor y conductor→cliente + overall 1–5  
- UI en detalle de viaje (entregado/completado) + notificación in-app  
- Verified: `flutter analyze`, `flutter test`

### Phase 12 — Company essentials ✅

- Migration: RLS company en trips / cargo_requests / offers / driver_vehicles / driver_profiles  
- `can_access_trip` incluye miembros de `trips.company_id`  
- RPC `list_company_drivers`  
- Dashboard empresa: viajes activos, conductores, vehículos, solicitudes pendientes  
- Alta de vehículo de flota desde el panel  
- Fix: RLS recursion vehicles ↔ driver_vehicles (`20260818061000_fix_phase12_rls_recursion.sql`)  
- Verified: `flutter analyze`, `flutter test`

### Phase 13 — Admin (web) ✅

- App: `apps/admin` (Next.js App Router + Supabase SSR + service role)  
- Migration: `is_platform_admin()`, review fields, `disputes`, `app_config`, `audit_logs`  
- Pantallas: resumen, verificación, usuarios, viajes, disputas, config  
- Auth: mismo email/password Supabase; gate por `platform_role`  
- Verified: `npm run build`

### Phase 14 — Hardening ✅

- Migration: bootstrap `platform_role` (postgres/service_role), admin SELECT RLS, offers soft-delete, indexes, `create_notification` revoke  
- Mobile: no `.env` en assets; `--dart-define-from-file`; INTERNET permission; analyze cleanups; a11y tooltips  
- Admin: env validation + error UI; no demote de super_admin por admin regular  
- Docs: `MOBILE_RELEASE.md`, `ADMIN_BOOTSTRAP.md`, SETUP  
- Verified: `flutter analyze`, `flutter test`, `npm run build`

---

## 4. Priority order (if time-constrained)

1. Registration / auth  
2. Profiles  
3. Vehicles  
4. Cargo requests  
5. Matching  
6. Offers  
7. Trips  
8. Tracking architecture  
9. POD  
10. Ratings  

Defer: advanced analytics, full payment provider, AI matching, recurring trips UI, multi-country localization depth.

---

## 5. Verification loop (every phase)

1. Analyze requirements for the phase  
2. Implement  
3. Format  
4. `flutter analyze` / typecheck  
5. Tests for new domain logic  
6. Fix failures  
7. Update docs if decisions or schema changed  
8. Proceed  

---

## 6. Immediate next actions after Phase 0

1. Install Flutter SDK (stable) + Android tooling; Xcode for iOS when targeting devices  
2. Install Supabase CLI (and Docker if local Supabase is desired)  
3. Begin Phase 1: create Flutter project and design system  

---

## 7. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Toolchain missing on this machine | Document setup; install before Phase 1 verify steps |
| Map provider cost / key | Abstract behind `MapService`; Google Maps first for Bolivia MVP |
| Matching too naive | Deterministic rules + scored ranking; Edge Function later for AI |
| RLS complexity | Central helper functions (`auth.uid()`, `is_company_member`, `has_role`) |
| Overbuilding admin/company | Scaffold schemas; ship mobile loop first |
| Payment provider unknown | Status model + `PaymentProvider` interface only |

---

*Last updated: Phase 0 — 2026-08-12*
