-- Fix: Phase 12 RLS recursion between vehicles ↔ driver_vehicles
-- Apply if you already ran the earlier phase12 migration.

create or replace function public.is_fleet_vehicle_for_member(p_vehicle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.vehicles v
    where v.id = p_vehicle_id
      and v.deleted_at is null
      and v.company_id is not null
      and public.is_company_member(v.company_id)
  );
$$;

revoke all on function public.is_fleet_vehicle_for_member(uuid) from public;
grant execute on function public.is_fleet_vehicle_for_member(uuid) to authenticated;

create or replace function public.is_company_fleet_driver(p_driver_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.driver_vehicles dv
    join public.vehicles v on v.id = dv.vehicle_id
    where dv.driver_profile_id = p_driver_profile_id
      and dv.deleted_at is null
      and v.deleted_at is null
      and v.company_id is not null
      and public.is_company_member(v.company_id)
  );
$$;

revoke all on function public.is_company_fleet_driver(uuid) from public;
grant execute on function public.is_company_fleet_driver(uuid) to authenticated;

create or replace function public.can_manage_fleet_vehicle(p_vehicle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.vehicles v
    where v.id = p_vehicle_id
      and v.deleted_at is null
      and v.company_id is not null
      and public.has_company_role(
        v.company_id,
        array['company_admin', 'company_operator']::public.company_role[]
      )
  );
$$;

revoke all on function public.can_manage_fleet_vehicle(uuid) from public;
grant execute on function public.can_manage_fleet_vehicle(uuid) to authenticated;

drop policy if exists "driver_vehicles_select" on public.driver_vehicles;
create policy "driver_vehicles_select"
  on public.driver_vehicles for select
  to authenticated
  using (
    deleted_at is null
    and (
      exists (
        select 1 from public.driver_profiles dp
        where dp.id = driver_profile_id and dp.user_id = auth.uid()
      )
      or public.is_fleet_vehicle_for_member(vehicle_id)
    )
  );

drop policy if exists "driver_profiles_select_own" on public.driver_profiles;
create policy "driver_profiles_select_own"
  on public.driver_profiles for select
  to authenticated
  using (
    deleted_at is null
    and (
      user_id = auth.uid()
      or public.is_company_fleet_driver(id)
    )
  );

drop policy if exists "driver_vehicles_insert_company" on public.driver_vehicles;
create policy "driver_vehicles_insert_company"
  on public.driver_vehicles for insert
  to authenticated
  with check (
    public.can_manage_fleet_vehicle(vehicle_id)
    and exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.deleted_at is null
    )
  );

drop policy if exists "driver_vehicles_update_company" on public.driver_vehicles;
create policy "driver_vehicles_update_company"
  on public.driver_vehicles for update
  to authenticated
  using (public.can_manage_fleet_vehicle(vehicle_id))
  with check (public.can_manage_fleet_vehicle(vehicle_id));
