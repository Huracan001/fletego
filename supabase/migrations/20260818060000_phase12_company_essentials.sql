-- Phase 12: company essentials — trips, fleet drivers, pending requests visibility

-- ---------------------------------------------------------------------------
-- Trip access: participants OR company members on trip.company_id
-- ---------------------------------------------------------------------------
create or replace function public.can_access_trip(p_trip_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trips t
    where t.id = p_trip_id
      and t.deleted_at is null
      and (
        t.customer_id = auth.uid()
        or t.driver_id = auth.uid()
        or (
          t.company_id is not null
          and public.is_company_member(t.company_id)
        )
      )
  );
$$;

revoke all on function public.can_access_trip(uuid) from public;
grant execute on function public.can_access_trip(uuid) to authenticated;

drop policy if exists "trips_select_participants" on public.trips;
create policy "trips_select_participants"
  on public.trips for select
  to authenticated
  using (
    deleted_at is null
    and (
      customer_id = auth.uid()
      or driver_id = auth.uid()
      or (
        company_id is not null
        and public.is_company_member(company_id)
      )
    )
  );

drop policy if exists "trip_history_select_participants" on public.trip_status_history;
create policy "trip_history_select_participants"
  on public.trip_status_history for select
  to authenticated
  using (public.can_access_trip(trip_id));

-- ---------------------------------------------------------------------------
-- Cargo requests: own + company membership + trip participants (via can_access)
-- ---------------------------------------------------------------------------
drop policy if exists "cargo_requests_select_own" on public.cargo_requests;
create policy "cargo_requests_select_own"
  on public.cargo_requests for select
  to authenticated
  using (
    deleted_at is null
    and (
      customer_id = auth.uid()
      or (
        company_id is not null
        and public.is_company_member(company_id)
      )
    )
  );

drop policy if exists "cargo_requests_select_trip_participants" on public.cargo_requests;
create policy "cargo_requests_select_trip_participants"
  on public.cargo_requests for select
  to authenticated
  using (
    deleted_at is null
    and exists (
      select 1 from public.trips t
      where t.request_id = cargo_requests.id
        and t.deleted_at is null
        and public.can_access_trip(t.id)
    )
  );

drop policy if exists "offers_select_participants" on public.offers;
create policy "offers_select_participants"
  on public.offers for select
  to authenticated
  using (
    deleted_at is null
    and (
      transporter_profile_id = auth.uid()
      or (
        company_id is not null
        and public.is_company_member(company_id)
      )
      or exists (
        select 1 from public.cargo_requests r
        where r.id = request_id
          and r.deleted_at is null
          and (
            r.customer_id = auth.uid()
            or (
              r.company_id is not null
              and public.is_company_member(r.company_id)
            )
          )
      )
    )
  );

-- ---------------------------------------------------------------------------
-- Fleet drivers: company members can see assignments on company vehicles
-- Use SECURITY DEFINER helpers to avoid RLS recursion with vehicles policies.
-- ---------------------------------------------------------------------------
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

-- Company admins/operators can assign a driver to a company vehicle
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

-- ---------------------------------------------------------------------------
-- Enriched fleet driver list for company dashboard
-- ---------------------------------------------------------------------------
create or replace function public.list_company_drivers(p_company_id uuid)
returns table (
  driver_profile_id uuid,
  user_id uuid,
  full_name text,
  email text,
  license_number text,
  verification_status public.verification_status,
  rating_avg numeric,
  completed_trips integer,
  vehicle_id uuid,
  vehicle_plate text,
  is_primary boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not public.is_company_member(p_company_id) then
    raise exception 'not a company member';
  end if;

  return query
  select distinct on (dp.id)
    dp.id as driver_profile_id,
    dp.user_id,
    coalesce(
      nullif(trim(p.display_name), ''),
      nullif(trim(p.full_name), ''),
      p.email,
      'Conductor'
    ) as full_name,
    p.email,
    dp.license_number,
    dp.verification_status,
    dp.rating_avg,
    dp.completed_trips,
    v.id as vehicle_id,
    v.plate as vehicle_plate,
    coalesce(dv.is_primary, false) as is_primary
  from public.driver_vehicles dv
  join public.driver_profiles dp on dp.id = dv.driver_profile_id
  join public.vehicles v on v.id = dv.vehicle_id
  join public.profiles p on p.id = dp.user_id
  where dv.deleted_at is null
    and dp.deleted_at is null
    and v.deleted_at is null
    and v.company_id = p_company_id
  order by dp.id, dv.is_primary desc, v.plate;
end;
$$;

revoke all on function public.list_company_drivers(uuid) from public;
grant execute on function public.list_company_drivers(uuid) to authenticated;
