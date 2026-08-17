-- Bump driver completed_trips when a trip is completed

create or replace function public.advance_trip_status(
  p_trip_id uuid,
  p_to_status public.trip_status,
  p_note text default null,
  p_lat double precision default null,
  p_lng double precision default null
)
returns public.trips
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
  v_from public.trip_status;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_trip
  from public.trips
  where id = p_trip_id and deleted_at is null
  for update;

  if not found then
    raise exception 'trip_not_found';
  end if;

  if v_trip.customer_id <> v_uid and v_trip.driver_id <> v_uid then
    raise exception 'not_allowed';
  end if;

  v_from := v_trip.status;

  if not public.is_valid_trip_transition(v_from, p_to_status) then
    raise exception 'invalid_transition';
  end if;

  if p_to_status in (
    'driver_going_to_pickup',
    'arrived_at_pickup',
    'cargo_picked_up',
    'in_transit',
    'arrived_at_destination',
    'delivering',
    'delivered'
  ) and v_trip.driver_id <> v_uid then
    raise exception 'driver_only_step';
  end if;

  update public.trips
  set
    status = p_to_status,
    started_at = case
      when p_to_status = 'driver_going_to_pickup' and started_at is null then now()
      else started_at
    end,
    completed_at = case
      when p_to_status in ('completed', 'cancelled', 'failed') then now()
      else completed_at
    end,
    current_lat = coalesce(p_lat, current_lat),
    current_lng = coalesce(p_lng, current_lng)
  where id = p_trip_id
  returning * into v_trip;

  insert into public.trip_status_history (
    trip_id, from_status, to_status, changed_by, note, lat, lng
  ) values (
    p_trip_id, v_from, p_to_status, v_uid, p_note, p_lat, p_lng
  );

  if p_to_status = 'cancelled' then
    update public.cargo_requests
    set status = 'cancelled'
    where id = v_trip.request_id and deleted_at is null;
  end if;

  if p_to_status = 'completed' and v_from is distinct from 'completed' then
    update public.driver_profiles
    set completed_trips = completed_trips + 1
    where user_id = v_trip.driver_id
      and deleted_at is null;
  end if;

  return v_trip;
end;
$$;
