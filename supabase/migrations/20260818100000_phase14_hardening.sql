-- Phase 14: hardening — bootstrap roles, notification grants, soft-delete, indexes

-- ---------------------------------------------------------------------------
-- Allow SQL Editor (postgres) + service_role to change platform_role.
-- Still blocks authenticated/anon clients.
-- ---------------------------------------------------------------------------
create or replace function public.prevent_platform_role_escalation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.platform_role is distinct from old.platform_role then
    if auth.role() = 'service_role'
       or current_user in ('postgres', 'supabase_admin') then
      return new;
    end if;
    raise exception 'platform_role cannot be changed by clients';
  end if;
  return new;
end;
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Re-assert create_notification is not client-callable
-- ---------------------------------------------------------------------------
revoke all on function public.create_notification(uuid, text, text, text, jsonb) from public;
revoke execute on function public.create_notification(uuid, text, text, text, jsonb) from authenticated, anon;

-- ---------------------------------------------------------------------------
-- Soft-deleted offers must not be updated
-- ---------------------------------------------------------------------------
drop policy if exists "offers_update_own_pending" on public.offers;
create policy "offers_update_own_pending"
  on public.offers for update
  to authenticated
  using (
    transporter_profile_id = auth.uid()
    and status = 'pending'
    and deleted_at is null
  )
  with check (
    transporter_profile_id = auth.uid()
    and deleted_at is null
  );

-- ---------------------------------------------------------------------------
-- Platform admin read access (JWT path). Writes for verification stay
-- service-role via apps/admin after requireAdmin().
-- ---------------------------------------------------------------------------
drop policy if exists "profiles_select_platform_admin" on public.profiles;
create policy "profiles_select_platform_admin"
  on public.profiles for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "companies_select_platform_admin" on public.companies;
create policy "companies_select_platform_admin"
  on public.companies for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "driver_profiles_select_platform_admin" on public.driver_profiles;
create policy "driver_profiles_select_platform_admin"
  on public.driver_profiles for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "vehicles_select_platform_admin" on public.vehicles;
create policy "vehicles_select_platform_admin"
  on public.vehicles for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "driver_documents_select_platform_admin" on public.driver_documents;
create policy "driver_documents_select_platform_admin"
  on public.driver_documents for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "vehicle_documents_select_platform_admin" on public.vehicle_documents;
create policy "vehicle_documents_select_platform_admin"
  on public.vehicle_documents for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "trips_select_platform_admin" on public.trips;
create policy "trips_select_platform_admin"
  on public.trips for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "cargo_requests_select_platform_admin" on public.cargo_requests;
create policy "cargo_requests_select_platform_admin"
  on public.cargo_requests for select
  to authenticated
  using (public.is_platform_admin());

drop policy if exists "offers_select_platform_admin" on public.offers;
create policy "offers_select_platform_admin"
  on public.offers for select
  to authenticated
  using (public.is_platform_admin());

-- ---------------------------------------------------------------------------
-- Hot-list partial indexes (deleted_at is null)
-- ---------------------------------------------------------------------------
create index if not exists trips_active_created_idx
  on public.trips (created_at desc)
  where deleted_at is null;

create index if not exists cargo_requests_open_created_idx
  on public.cargo_requests (created_at desc)
  where deleted_at is null and status in ('submitted', 'matching', 'offered');

create index if not exists offers_pending_created_idx
  on public.offers (created_at desc)
  where deleted_at is null and status = 'pending';
