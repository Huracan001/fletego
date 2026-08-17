-- Phase 8: location_updates for active-trip tracking

create table if not exists public.location_updates (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id),
  driver_id uuid not null references public.profiles (id),
  lat double precision not null,
  lng double precision not null,
  speed_mps double precision,
  heading_deg double precision,
  accuracy_m double precision,
  recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists location_updates_trip_recorded_idx
  on public.location_updates (trip_id, recorded_at desc);

alter table public.location_updates enable row level security;

drop policy if exists "location_updates_select_participants" on public.location_updates;
create policy "location_updates_select_participants"
  on public.location_updates for select
  to authenticated
  using (public.can_access_trip(trip_id));

-- Driver posts location only on active (non-terminal) trips
create or replace function public.post_trip_location(
  p_trip_id uuid,
  p_lat double precision,
  p_lng double precision,
  p_speed_mps double precision default null,
  p_heading_deg double precision default null,
  p_accuracy_m double precision default null
)
returns public.location_updates
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
  v_row public.location_updates;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_lat is null or p_lng is null then
    raise exception 'invalid_coordinates';
  end if;

  if p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180 then
    raise exception 'invalid_coordinates';
  end if;

  select * into v_trip
  from public.trips
  where id = p_trip_id and deleted_at is null
  for update;

  if not found then
    raise exception 'trip_not_found';
  end if;

  if v_trip.driver_id <> v_uid then
    raise exception 'driver_only';
  end if;

  if v_trip.status in ('completed', 'cancelled', 'failed') then
    raise exception 'trip_not_active';
  end if;

  insert into public.location_updates (
    trip_id, driver_id, lat, lng, speed_mps, heading_deg, accuracy_m, recorded_at
  ) values (
    p_trip_id, v_uid, p_lat, p_lng, p_speed_mps, p_heading_deg, p_accuracy_m, now()
  )
  returning * into v_row;

  update public.trips
  set current_lat = p_lat, current_lng = p_lng
  where id = p_trip_id;

  return v_row;
end;
$$;

revoke all on function public.post_trip_location(
  uuid, double precision, double precision, double precision, double precision, double precision
) from public;
grant execute on function public.post_trip_location(
  uuid, double precision, double precision, double precision, double precision, double precision
) to authenticated;

create or replace function public.get_trip_latest_location(p_trip_id uuid)
returns public.location_updates
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_row public.location_updates;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not public.can_access_trip(p_trip_id) then
    raise exception 'not_allowed';
  end if;

  select * into v_row
  from public.location_updates
  where trip_id = p_trip_id
  order by recorded_at desc
  limit 1;

  return v_row;
end;
$$;

revoke all on function public.get_trip_latest_location(uuid) from public;
grant execute on function public.get_trip_latest_location(uuid) to authenticated;
