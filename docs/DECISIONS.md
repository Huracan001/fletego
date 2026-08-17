# FLETEGO — Architecture Decision Records

Decisions made during planning and implementation. Prefer simplicity, security, and a working marketplace loop over premature complexity.

---

## ADR-001 — Flutter for mobile clients

**Status:** Accepted  
**Context:** Need one codebase for iOS and Android App Store / Play deployment.  
**Decision:** Flutter (stable channel) for `apps/mobile`, bundle id `com.fletego.app`.  
**Consequences:** Shared UI/business logic; native map/location plugins required; store signing still platform-specific.

---

## ADR-002 — Supabase as backend platform

**Status:** Accepted  
**Context:** Need Auth, Postgres, Storage, Realtime without early microservices.  
**Decision:** Supabase as the single backend platform; Edge Functions only when RLS/client cannot safely express a use case.  
**Consequences:** Fast MVP; must design RLS carefully; service role never in the Flutter app.

---

## ADR-003 — Vehicles are assets, not accounts

**Status:** Accepted  
**Context:** Prompt forbids login-per-truck; domain is people → companies → vehicles → drivers.  
**Decision:** `vehicles` owned by a profile (independent) or `company_id`; `drivers` are profiles with a driver record; assignment via `driver_vehicles`.  
**Consequences:** Cleaner auth; company fleet management is natural; no vehicle credentials.

---

## ADR-004 — Riverpod + GoRouter + feature-first folders

**Status:** Accepted  
**Context:** Need maintainable state, routing, and separation of concerns.  
**Decision:** Riverpod for state/DI; GoRouter for navigation; feature-first `lib/features/*` with `core/` design system.  
**Consequences:** Slight boilerplate; high testability; clear boundaries for repositories vs UI.

---

## ADR-005 — Monorepo layout

**Status:** Accepted  
**Context:** Mobile + Supabase + future admin should evolve together.  
**Decision:** `apps/mobile`, `apps/admin` (later), `supabase/`, `docs/`.  
**Consequences:** Single PR can update schema + app; admin can wait until Phase 13 without blocking mobile.

---

## ADR-006 — Roles: platform vs company vs onboarding intent

**Status:** Accepted  
**Context:** Spec lists CUSTOMER, DRIVER, COMPANY_ADMIN, COMPANY_OPERATOR, DISPATCHER, ADMIN, SUPER_ADMIN, plus company roles FINANCE/VIEWER.  
**Decision:**

1. **Onboarding intent** (product UX): `need_transport` | `offer_transport` | `manage_transport` — stored on profile, drives first-run UX and default shell.  
2. **Platform role** on profile: `user` | `admin` | `super_admin`.  
3. **Company role** on `company_members`: `company_admin` | `company_operator` | `company_finance` | `company_viewer` | `dispatcher`.  
4. **Capability flags**: `is_customer` / `is_driver` derived from intent + completed profiles (a person can be both over time).

**Consequences:** Avoids a single overloaded enum; permissions live in a central matrix, not in widgets.

---

## ADR-007 — Matching is deterministic first, AI later

**Status:** Accepted  
**Context:** “No sé qué camión necesito” and driver load matching must work without AI.  
**Decision:** `VehicleCompatibilityService` + `MatchingService` with explicit rules and scores; interface allows swapping/augmenting with AI later (Edge Function).  
**Consequences:** Transparent, testable MVP; AI is an enhancement, not a blocker.

---

## ADR-008 — Pricing and payments are abstractions

**Status:** Accepted  
**Context:** No production pricing formula or payment provider selected.  
**Decision:** Manual offers for MVP; `PricingService` stub for estimates; `payments` table with status enum; `PaymentProvider` interface with a `NoOp` / `Manual` implementation.  
**Consequences:** No fake checkout success; real provider plugs in later.

---

## ADR-009 — Maps behind `MapService`

**Status:** Accepted  
**Context:** Need geocoding, autocomplete, routes, tracking; provider may change.  
**Decision:** Abstract `MapService`; implement Google Maps / Places first when keys exist; mock implementation for UI development without keys.  
**Consequences:** App runs in demo mode without maps key; production requires configured key.

---

## ADR-010 — GPS only on active trips by default

**Status:** Accepted  
**Context:** Battery, privacy, store scrutiny for background location.  
**Decision:** Request location when needed; stream updates while trip is active and consented; no continuous tracking when idle. Background location deferred until justified.  
**Consequences:** Simpler permissions copy; return-load discovery uses last known / manual location until enhanced.

---

## ADR-011 — Spanish UI via localization resources

**Status:** Accepted  
**Context:** Primary language Spanish; English later.  
**Decision:** Flutter l10n ARB files; no hard-coded user-facing strings in widgets.  
**Consequences:** Slightly more setup in Phase 1; bilingual-ready.

---

## ADR-012 — Soft delete for business records

**Status:** Accepted  
**Context:** Trips, offers, payments, audits must not vanish.  
**Decision:** `deleted_at` soft delete; trips never hard-deleted; cancellation is a state + reason record.  
**Consequences:** Storage growth; queries filter `deleted_at IS NULL`.

---

## ADR-013 — Admin as separate Next.js app (Phase 13)

**Status:** Accepted  
**Context:** Spec allows web admin; mobile should stay focused on marketplace loop.  
**Decision:** Defer admin UI to `apps/admin` (Next.js); schema supports verification statuses from day one.  
**Consequences:** Dev verification via seed/SQL until admin ships.

---

## ADR-014 — Demo / development mode

**Status:** Accepted  
**Context:** Need to develop UI without production Supabase or maps.  
**Decision:** Flavor/`AppConfig.demoMode` with mock repositories or local seed; never mix demo writes into production project.  
**Consequences:** Clear env separation; documented in SETUP/ENVIRONMENT.

---

## ADR-015 — Recurring trips: schema-ready, UI later

**Status:** Accepted  
**Context:** Recurring transport is valuable but not MVP-critical.  
**Decision:** Optional `recurrence_rule` / `cargo_request_templates` table designed in DATABASE.md; no full UI in MVP.  
**Consequences:** No migration rewrite later for recurrence.

---

## ADR-016 — Toolchain bootstrap is a prerequisite for Phase 1 verification

**Status:** Accepted  
**Context:** Workspace machine currently lacks Flutter, Homebrew, Node, Docker, Xcode app, Android SDK.  
**Decision:** Complete Phase 0 docs in-repo; Phase 1 code generation proceeds after Flutter install (documented in SETUP.md).  
**Consequences:** Plan/docs can land without `flutter analyze` until toolchain exists.

---

## ADR-017 — Currency and geography

**Status:** Accepted  
**Context:** Bolivia-first MVP.  
**Decision:** Default market `BO`, currency `BOB`, display “Bs”; store `country_code` on addresses/companies; city seeds for major Bolivian cities.  
**Consequences:** Expansion = data + config, not rewrite.

---

## ADR-018 — Inter font + FLETEGO brand tokens only

**Status:** Accepted  
**Context:** Strict brand palette and Inter typography.  
**Decision:** Centralize tokens; no ad-hoc brand colors; temporary wordmark asset for logo.  
**Consequences:** Consistent UI; real logo drop-in later.

---

## Open questions (non-blocking)

| Topic | Interim decision |
|-------|------------------|
| Exact map billing account | Mock maps until key provided |
| Push vendor (FCM-only vs OneSignal) | FCM/APNs via firebase_messaging abstraction |
| Phone OTP in MVP | Schema ready; email/password ships first |
| Multi-role switcher UX | Primary shell from intent; profile can add driver/company later |

---

## ADR-019 — Riverpod without codegen in Phase 1

**Status:** Accepted  
**Context:** `riverpod_generator` / `riverpod_lint` conflicted with current Flutter/Dart analyzer stack during foundation setup.  
**Decision:** Use `flutter_riverpod` providers manually for Phase 1; revisit codegen when tooling aligns.  
**Consequences:** Slightly more boilerplate; no blocked foundation work.

---

## ADR-020 — Auth screens are shells until Phase 2

**Status:** Accepted  
**Context:** Avoid fake success without Supabase Auth.  
**Decision:** Login/signup UI exists but clearly states backend is not configured yet; no pretend sessions.  
**Consequences:** Honest UX; Phase 2 wires AuthRepository.

---

*Last updated: Phase 1 foundation — 2026-08-12*

