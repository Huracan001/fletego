# FLETEGO — Database & Domain Model

PostgreSQL via Supabase. UUID primary keys, timestamps, FKs, RLS, soft deletes for business entities. All changes ship as migrations under `supabase/migrations/`.

---

## 1. Design principles

1. **Person ≠ vehicle ≠ company** — vehicles have no auth identity.  
2. **Normalize** core entities; avoid dumping everything into JSON (JSON only for flexible extras).  
3. **Enums as Postgres enums or check constraints** — no magic status strings in app code without shared constants.  
4. **Soft delete** (`deleted_at`) for trips, requests, offers, companies, vehicles, documents.  
5. **Audit** important mutations into `audit_logs`.  
6. **Geo**: always store lat/lng when known; city name alone is insufficient.  
7. **Extensibility**: `vehicle_types` and cargo catalogs are data, not hard-coded schema forks.

---

## 2. Entity relationship (simplified)

```
auth.users 1──1 profiles
profiles ──< company_members >── companies
companies ──< vehicles
profiles 1──0..1 driver_profiles
driver_profiles >──< vehicles (driver_vehicles)
profiles|companies ──< cargo_requests
cargo_requests ──< offers
cargo_requests 1──0..1 trips (after accept)
trips ──< trip_status_history
trips ──< location_updates
trips 1──0..1 proof_of_delivery
trips ──< messages
trips ──< ratings
trips ──< payments
```

---

## 3. Enumerations (proposed)

```sql
-- Platform
platform_role: user | admin | super_admin
onboarding_intent: need_transport | offer_transport | manage_transport
customer_profile_type: persona_natural | empresa | importador | exportador | agencia_despachante | operador_logistico

-- Company
company_role: company_admin | company_operator | company_finance | company_viewer | dispatcher
company_type: customer | transporter | both | broker

-- Verification / documents
verification_status: pending | approved | rejected | expired
document_kind: identity | license | vehicle_registration | insurance | other

-- Vehicles / cargo
body / vehicle types: seeded rows (portacontenedor, cisterna, ciguena, sider, ...)
container_type: ft20 | ft40 | ft40_hc | ft45
cargo_type: contenedor | carga_general | liquidos | vehiculos | maquinaria | refrigerada | carga_peligrosa | otra

-- Marketplace
request_status: draft | submitted | matching | offered | assigned | cancelled | expired
offer_status: pending | accepted | rejected | withdrawn | expired
trip_status: requested | matching | offer_received | assigned | driver_going_to_pickup
             | arrived_at_pickup | cargo_picked_up | in_transit | arrived_at_destination
             | delivering | delivered | completed | cancelled | disputed | failed
availability_status: offline | available | busy | on_trip
payment_status: pending | authorized | paid | failed | refunded | cancelled
schedule_mode: asap | scheduled
```

App Dart enums must mirror these values exactly.

---

## 4. Core tables

### 4.1 `profiles`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | = `auth.users.id` |
| full_name | text | |
| display_name | text | |
| phone | text | E.164-ish; BO format in UX |
| email | text | denormalized from auth |
| avatar_path | text | storage path |
| platform_role | platform_role | default `user` |
| onboarding_intent | onboarding_intent | nullable until onboarding |
| customer_type | customer_profile_type | nullable |
| ci_number | text | Bolivia CI |
| country_code | text | default `BO` |
| locale | text | default `es` |
| is_driver | boolean | capability |
| is_customer | boolean | capability |
| rating_avg | numeric | maintained by triggers/jobs |
| rating_count | int | |
| onboarding_completed_at | timestamptz | |
| created_at / updated_at / deleted_at | | |

### 4.2 `companies`

| Column | Notes |
|--------|-------|
| id, name, legal_name, nit, country_code | |
| company_type | customer / transporter / both / broker |
| phone, email, address | |
| verification_status | |
| logo_path | |
| created_by | profiles.id |
| timestamps + deleted_at | |

### 4.3 `company_members`

| Column | Notes |
|--------|-------|
| id | |
| company_id, user_id | unique (company_id, user_id) |
| role | company_role |
| permissions override | optional jsonb later; MVP uses role matrix |
| invited_by, joined_at, deleted_at | |

**Permission matrix (app + RLS helpers):** central `CompanyPermission` enum mapped from role — never per-screen hardcoding.

### 4.4 `driver_profiles`

| Column | Notes |
|--------|-------|
| id | |
| user_id | unique |
| license_number, license_expiry | |
| verification_status | |
| years_experience | |
| accepts_return_loads | bool |
| rating_avg, completed_trips | |
| timestamps | |

### 4.5 `vehicle_types` (catalog)

Seeded: Portacontenedor, Cisterna, Cigüeña, Sider, Acoplado, Camión rígido, Semirremolque, Plataforma, Refrigerado, Furgón, Cama baja, Otro.

| Column | Notes |
|--------|-------|
| id, code, name_es, name_en | |
| typical_max_weight_kg | optional defaults for recommendations |
| supports_container | bool |
| supports_refrigeration | bool |
| is_active | bool |

### 4.6 `vehicles`

| Column | Notes |
|--------|-------|
| id | |
| owner_profile_id | independent owner XOR |
| company_id | company fleet XOR (check one set) |
| vehicle_type_id | |
| plate | unique per country |
| brand, model, year | |
| capacity_kg, tare_kg, max_cargo_kg | |
| length_m, width_m, height_m | |
| body_type | text/enum |
| has_refrigeration, has_tarp, accepts_dangerous_goods | |
| insurance_provider, insurance_policy, insurance_expiry | |
| verification_status, availability_status | |
| photo_paths | text[] or child table |
| timestamps + deleted_at | |

### 4.7 `driver_vehicles`

Many-to-many: which drivers may operate which vehicles (`is_primary` flag).

### 4.8 Documents

Unified `documents` table **or** split `vehicle_documents` / `driver_documents` / `company_documents`.

**Decision:** split tables for clearer RLS + expiry jobs:

- `driver_documents`  
- `vehicle_documents`  
- `company_documents`  
- `cargo_documents` (linked to request)

Common fields: kind, storage_path, issue_date, expiry_date, verification_status, reviewed_by, reviewed_at, rejection_reason.

### 4.9 Locations (embed vs table)

**Decision:** embedded columns on requests/stops for MVP simplicity, plus optional `places` cache later.

Each stop/location includes:

`country_code, admin_area, city, address_line, label, lat, lng, instructions`

### 4.10 `cargo_requests`

| Column | Notes |
|--------|-------|
| id, customer_id, company_id nullable | |
| status | request_status |
| cargo_type | |
| schedule_mode | asap / scheduled |
| pickup_at, pickup_window_start/end | |
| origin_* / destination_* location fields | |
| total_weight_kg | |
| length_m, width_m, height_m | nullable |
| stackable, requires_tarp, requires_special_loading | |
| requires_refrigeration, dangerous_goods | |
| special_requirements | text[] / jsonb |
| special_instructions | |
| requested_vehicle_type_id | nullable |
| recommended_vehicle_type_id | from rules |
| user_selected_unknown_truck | bool (“No sé…”) |
| currency | default BOB |
| recurrence_template_id | nullable (future) |
| cancelled_at, cancel_reason, cancelled_by | |
| timestamps + deleted_at | |

### 4.11 `containers` (0..1 per request when cargo_type = contenedor)

container_type, container_number, gross_weight_kg, refrigerated, dangerous_goods, imo, un_number, booking_ref, bl_ref, shipping_line, origin_port, destination_port, return_deadline.

### 4.12 `cargo_items` (optional line items for general cargo)

For multi-piece shipments later; MVP may use single totals on `cargo_requests`.

### 4.13 `offers`

| Column | Notes |
|--------|-------|
| request_id, transporter_profile_id, company_id, driver_id, vehicle_id | |
| price_amount, currency | |
| eta_pickup_at | |
| message | |
| status | |
| distance_km_estimate | |
| timestamps + deleted_at | |

Unique partial index: one pending offer per (request, driver/vehicle) as needed.

### 4.14 `trips`

| Column | Notes |
|--------|-------|
| id, request_id unique, offer_id | |
| customer_id, driver_id, vehicle_id, company_id | |
| status | trip_status |
| assigned_at, started_at, completed_at | |
| cancel_* fields | |
| current_lat/lng | denormalized latest |
| timestamps + deleted_at | |

### 4.15 `trip_status_history`

trip_id, from_status, to_status, changed_by, note, lat, lng, created_at.

### 4.16 `trip_stops`

Optional multi-stop future; MVP = origin + destination on request. Table exists for extensibility: sequence, type (pickup/delivery), location fields, status.

### 4.17 `availability`

Driver publishes availability:

driver_id, vehicle_id, status, current_lat/lng, available_from/until, preferred_destinations (jsonb), accepts_return_cargo, max_deadhead_km.

### 4.18 `location_updates`

trip_id, driver_id, lat, lng, speed, heading, recorded_at. Indexed by (trip_id, recorded_at desc).

### 4.19 `messages` + `message_attachments`

trip_id (required), sender_id, body, created_at; attachments via storage paths. Trip-scoped only.

### 4.20 `proof_of_delivery`

trip_id unique, recipient_name, recipient_id_ref, signature_path, photo_paths, lat, lng, captured_at, created_by.

### 4.21 `ratings`

trip_id, from_user_id, to_user_id, overall (1–5), dimension scores (jsonb or columns), comment, created_at.  
Unique (trip_id, from_user_id).

Customer dimensions: punctuality, vehicle_condition, driver, communication.  
Driver dimensions: cargo_readiness, info_accuracy, loading_wait, customer_behavior.

### 4.22 `notifications`

user_id, type, title, body, data jsonb, read_at, created_at.

### 4.23 `payments`

trip_id / offer_id, amount, currency, status, provider, provider_ref, timestamps. No fake provider integration.

### 4.24 `disputes`

trip_id, opened_by, reason, status, resolution, timestamps.

### 4.25 `audit_logs`

actor_id, action, entity_type, entity_id, metadata jsonb, created_at. Insert-only for clients (or Edge Function).

### 4.26 Recurrence (schema-ready)

`cargo_request_templates`: customer_id, cron/rrule, route snapshot, cargo snapshot, trucks_needed. MVP: table may be created empty; UI later.

---

## 5. Indexes (minimum)

- FKs: user/profile, company, vehicle, driver, trip, request  
- `status` on requests, offers, trips, availability  
- `created_at` desc for feeds  
- Geo: consider `postgis` later; MVP use lat/lng + bounding box queries  
- Document `expiry_date` for reminder jobs  
- Messages `(trip_id, created_at)`  

---

## 6. RLS outline

| Table | Who reads | Who writes |
|-------|-----------|------------|
| profiles | self; limited public fields for counterparties on shared trips | self; admins |
| companies | members; counterparties on shared trips | admins/operators per role |
| company_members | members | company_admin |
| vehicles | owner, company members, assigned drivers; limited on offers | owner/company roles |
| cargo_requests | owner/company; eligible drivers see open marketplace subset | owner/company |
| offers | request owner + offer creator + company | creator; owner accepts |
| trips | customer, driver, company members on trip | transitions via allowed roles + state machine |
| messages | trip participants | trip participants |
| location_updates | trip participants | assigned driver |
| documents | owner / company / admin reviewers | owner; admin verification |
| audit_logs | admin | insert via trusted paths |

Platform `admin` / `super_admin`: SELECT policies via `is_platform_admin()` on core ops tables (Phase 14). Privileged verification **writes** in `apps/admin` use the service role after `requireAdmin()` (not client JWT updates).

**Marketplace visibility:** drivers with `availability_status = available` and verified vehicle may `SELECT` requests in `matching`/`offered` within geo/type filters — exact SQL refined in migrations with security tests.

---

## 7. Storage buckets & policies

Private buckets listed in ARCHITECTURE.md. Path convention:

`{bucket}/{entity_id}/{uuid}_{filename}`

RLS: only related party can create/read; signed URLs for display.

---

## 8. Seed data (development)

- Profiles: customer in Santa Cruz, driver in Cochabamba, company admin  
- Vehicles: Sider 25T, Portacontenedor, Refrigerado  
- Open request: Santa Cruz → Cochabamba, 25t general cargo  
- Sample offer + optional in-progress trip  
- Cities list for autocomplete bootstrap  
- **No real credentials / production keys**  

---

## 9. Migration plan (first migrations)

1. Extensions (`pgcrypto`, optionally `postgis` later)  
2. Enums  
3. profiles + trigger from auth.users  
4. companies + members  
5. vehicle_types + vehicles + driver_profiles + driver_vehicles  
6. documents tables  
7. cargo_requests + containers  
8. offers + trips + history  
9. availability + location_updates  
10. messages + POD + ratings  
11. notifications + payments + disputes + audit_logs  
12. RLS policies  
13. Storage bucket SQL  
14. Seed (dev only)  

---

## 10. Contradictions resolved in modeling

| Tension | Resolution |
|---------|------------|
| Many company roles vs user types | Split platform role / company role / intent (ADR-006) |
| trip `REQUESTED` vs request lifecycle | Request has its own status; trip created at offer acceptance starting at `ASSIGNED` (request may show `ASSIGNED`); keep enum parity for shared UI labels where useful |
| Dispatcher as user type and company role | `dispatcher` is a **company_role** (and onboarding intent `manage_transport`) |
| Embed locations vs places table | Embed on MVP; add `places` cache if autocomplete volume needs it |

---

*Last updated: Phase 0 — 2026-08-12*
