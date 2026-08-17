# FLETEGO — Architecture

**FLETEGO by Pick&Truck** — heavy transportation marketplace connecting cargo owners with transporters who have suitable vehicles.

---

## 1. System overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Clients (untrusted)                      │
│  ┌─────────────────────┐     ┌────────────────────────────┐ │
│  │  Flutter Mobile App │     │  Next.js Admin (Phase 13)  │ │
│  │  com.fletego.app    │     │  service role via server   │ │
│  └──────────┬──────────┘     └─────────────┬──────────────┘ │
└─────────────┼──────────────────────────────┼────────────────┘
              │ anon key + JWT               │ server-only secrets
              ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         Supabase                             │
│  Auth │ PostgreSQL + RLS │ Storage │ Realtime │ Edge Fn     │
└─────────────────────────────────────────────────────────────┘
```

**Rules:**

- Flutter never receives `SUPABASE_SERVICE_ROLE_KEY`.
- Authorization is enforced with PostgreSQL RLS (not UI alone).
- Privileged operations (admin verification, complex matching writes, signed URL minting) go through Edge Functions or the admin server with service role.

---

## 2. Domain model (conceptual)

```
auth.users
    └── profiles (1:1)
            ├── optional company membership(s) via company_members
            ├── driver_profile (0..1) for people who drive
            └── roles / platform roles (ADMIN, SUPER_ADMIN)

companies
    ├── company_members (user + company role)
    ├── vehicles (assets owned by company or independent owner)
    └── drivers linked via driver_vehicles / assignments

vehicles  ← assets, NOT accounts
drivers   ← people authorized to operate vehicles

cargo_requests → offers → trips → POD → ratings
                     ↑
              matching / availability
```

**Core principle:** A truck is an asset. A user is a person. A company is an organization. Vehicles never have credentials.

---

## 3. Flutter app architecture

### 3.1 Organization (feature-first)

```
apps/mobile/lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/           # env, flavors
│   ├── theme/            # tokens + ThemeData
│   ├── router/           # GoRouter
│   ├── network/          # Supabase client, errors
│   ├── l10n/
│   ├── analytics/
│   ├── monitoring/
│   └── widgets/          # design system (Fletego*)
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── home/
│   ├── customer/
│   ├── driver/
│   ├── company/
│   ├── trips/
│   ├── cargo/
│   ├── vehicles/
│   ├── maps/
│   ├── chat/
│   ├── notifications/
│   ├── profile/
│   ├── documents/
│   └── offers/
└── shared/
    ├── models/
    ├── enums/
    └── utils/
```

### 3.2 Layers

| Layer | Responsibility |
|-------|----------------|
| **UI** | Widgets, Riverpod `ConsumerWidget`s, presentation state |
| **Application / Notifiers** | Orchestrate use cases, loading/error/empty |
| **Domain services** | Matching, compatibility, trip state machine, pricing |
| **Repositories** | Supabase/Storage/Realtime access |
| **DTOs / Models** | Typed domain entities |

**Forbidden:** Supabase queries inside widgets; business rules inside view-only widgets.

### 3.3 State management

**Riverpod** (codegen optional later) for DI, async state, and testability.

### 3.4 Navigation

**GoRouter** with auth redirect, role-based shell routes:

| Role shell | Tabs |
|------------|------|
| Customer | Inicio · Viajes · Solicitar · Mensajes · Perfil |
| Driver | Inicio · Cargas · Viajes · Ganancias · Perfil |
| Company | Dashboard · Viajes · Transportistas · Reportes · Perfil |

Onboarding intent maps users into a primary shell; multi-role users can switch when applicable.

---

## 4. Backend architecture (Supabase)

### 4.1 PostgreSQL

- UUID PKs, `created_at` / `updated_at`, soft deletes (`deleted_at`) for business records  
- Enums / check constraints for statuses  
- Indexes on FKs, status, geo lookups  
- Migrations under `supabase/migrations/` only  

### 4.2 Auth

- Email/password first  
- Phone auth prepared (schema + profile phone fields)  
- Social login later (same `profiles` table)  
- Trigger: create `profiles` row on `auth.users` insert  

### 4.3 RLS strategy

Central SQL helpers, e.g.:

- `current_profile_id()`
- `is_platform_admin()`
- `is_company_member(company_id)`
- `has_company_permission(company_id, permission)`
- `can_access_trip(trip_id)`

Policies by table; marketplace visibility for open requests uses narrow, explicit rules (e.g. verified drivers with compatible availability).

### 4.4 Storage (private buckets)

| Bucket | Purpose |
|--------|---------|
| `avatars` | Profile images |
| `vehicle-documents` | Registration, insurance |
| `driver-documents` | License, ID |
| `cargo-documents` | BL, packing lists |
| `trip-photos` | Pickup/transit photos |
| `pod-documents` | Proof of delivery |
| `chat-attachments` | Trip chat media |

Access via RLS policies + signed URLs. No public identity documents.

### 4.5 Realtime

Subscribe to:

- Trip status changes  
- New offers on a request  
- Chat messages for a trip  
- Location updates for active trip (customer)  

### 4.6 Edge Functions (when needed)

- Privileged matching refresh / notifications fan-out  
- Document verification transitions (admin-assisted)  
- Push dispatch  
- Sensitive signed URL issuance if client policies are insufficient  

MVP may start with RLS + client repositories; add Edge Functions when a write path cannot be safely expressed in RLS alone.

---

## 5. Domain services (mobile + shared logic)

| Service | Role |
|---------|------|
| `VehicleCompatibilityService` | Cargo ↔ vehicle type/weight/dims/equipment |
| `MatchingService` | Score & filter compatible loads/vehicles |
| `TripStateService` | Valid transitions only |
| `PricingService` | Abstraction; MVP = manual offers |
| `AvailabilityService` | Driver/vehicle availability windows |
| `DocumentVerificationService` | Expiry & status helpers |
| `MapService` | Provider-agnostic maps/geocoding/routing |
| `PaymentProvider` | Status model only until provider chosen |
| `AnalyticsService` | Vendor-agnostic events |
| `CrashReportingService` | Vendor-agnostic errors |

Recommendation engine (“No sé qué camión necesito”) starts as deterministic rules inside `VehicleCompatibilityService`, with a seam for future AI.

---

## 6. Trip state machine

```
REQUESTED → MATCHING → OFFER_RECEIVED → ASSIGNED
  → DRIVER_GOING_TO_PICKUP → ARRIVED_AT_PICKUP → CARGO_PICKED_UP
  → IN_TRANSIT → ARRIVED_AT_DESTINATION → DELIVERING
  → DELIVERED → COMPLETED

Terminal / side: CANCELLED | DISPUTED | FAILED
```

Invalid transitions are rejected in `TripStateService` and preferably also via DB trigger/constraint.

Every transition appends `trip_status_history`.

---

## 7. Matching (MVP)

Deterministic scoring inputs:

1. Vehicle type compatibility  
2. Weight capacity  
3. Dimensions / container fit  
4. Special equipment (tarp, refrigeration, DG, etc.)  
5. Driver + vehicle availability  
6. Geographic proximity / deadhead  
7. Route / return-load preference  
8. Verification status  

Output: ranked candidates → driver marketplace + optional notify.

---

## 8. GPS / tracking

- Foreground updates during active trip only (default)  
- Sensible interval (e.g. 15–30s moving, less when stationary) — tune empirically  
- Background location only if product later requires continuous tracking with consent & store justification  
- Persist `location_updates` linked to `trip_id`  
- Customer map reads latest point + route polyline  

---

## 9. Notifications

Abstraction over FCM/APNs:

- Trip lifecycle events  
- Offer received / accepted  
- Compatible load (driver)  
- Chat message  
- Document expiry reminders (later)  

In-app `notifications` table + push when tokens registered.

---

## 10. Design system

Tokens centralized:

- Primary `#1769FF` · Navy `#0B1220` · Success `#20C77A` · BG `#F6F8FC` · White `#FFFFFF`  
- Typography: Inter (400–800)  
- Components: `FletegoButton`, `FletegoCard`, `FletegoTripCard`, `FletegoOfferCard`, `FletegoMap`, empty/loading/error states, etc.  

Brand treatment: wordmark **FLETEGO** + secondary **by Pick&Truck**; temporary vector/text asset replaceable later.

---

## 11. Environments

| Env | Purpose |
|-----|---------|
| development | Local / Supabase project (dev) + seed data |
| staging | Pre-prod validation |
| production | App Store / Play |

Public client config only: URL, anon key, maps key. Secrets stay server-side.

---

## 12. Admin

Phase 13: Next.js app with server-side Supabase service role for:

- User/company/driver/vehicle verification  
- Trips, offers, disputes, reports, system config  

Until then, verification statuses exist in schema and can be updated via SQL/seed for development.

---

## 13. Testing strategy

- Unit: compatibility, matching scores, trip transitions, permissions helpers  
- Widget: critical flows (login, request step, offer accept)  
- Repository: mocked Supabase client where practical  
- Manual QA checklist for the MVP loop on device  

---

## 14. Bolivia-first, multi-country ready

- Currency display BOB / Bs  
- Cities seed: Santa Cruz, Cochabamba, La Paz, Oruro, Sucre, Tarija, Potosí, Trinidad  
- CI / NIT fields on profiles/companies  
- `country_code` on locations and companies — not hard-coded into every rule  

---

*Last updated: Phase 0 — 2026-08-12*
