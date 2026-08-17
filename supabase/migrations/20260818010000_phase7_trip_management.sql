-- Phase 7: trip status transitions, cancel, soft-delete helpers

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
      and (t.customer_id = auth.uid() or t.driver_id = auth.uid())
  );
$$;

revoke all on function public.can_access_trip(uuid) from public;
grant execute on function public.can_access_trip(uuid) to authenticated;

-- Mirrors Flutter TripStateService happy-path + side transitions
create or replace function public.is_valid_trip_transition(
  p_from public.trip_status,
  p_to public.trip_status
)
returns boolean
language plpgsql
immutable
as $$
begin
  if p_from = p_to then
    return false;
  end if;

  return case p_from
    when 'requested' then p_to in ('matching', 'cancelled')
    when 'matching' then p_to in ('offer_received', 'assigned', 'cancelled')
    when 'offer_received' then p_to in ('assigned', 'matching', 'cancelled')
    when 'assigned' then p_to in ('driver_going_to_pickup', 'cancelled', 'disputed')
    when 'driver_going_to_pickup' then p_to in ('arrived_at_pickup', 'cancelled', 'failed')
    when 'arrived_at_pickup' then p_to in ('cargo_picked_up', 'cancelled', 'failed')
    when 'cargo_picked_up' then p_to in ('in_transit', 'cancelled', 'failed', 'disputed')
    when 'in_transit' then p_to in ('arrived_at_destination', 'failed', 'disputed')
    when 'arrived_at_destination' then p_to in ('delivering', 'failed', 'disputed')
    when 'delivering' then p_to in ('delivered', 'failed', 'disputed')
    when 'delivered' then p_to in ('completed', 'disputed')
    when 'disputed' then p_to in ('completed', 'cancelled')
    else false
  end;
end;
$$;

revoke all on function public.is_valid_trip_transition(public.trip_status, public.trip_status) from public;
grant execute on function public.is_valid_trip_transition(public.trip_status, public.trip_status) to authenticated;

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

  -- Driver advances operational steps; customer may complete/dispute/cancel
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

  if p_to_status = 'completed' and v_uid not in (v_trip.customer_id, v_trip.driver_id) then
    raise exception 'not_allowed';
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

  return v_trip;
end;
$$;

revoke all on function public.advance_trip_status(
  uuid, public.trip_status, text, double precision, double precision
) from public;
grant execute on function public.advance_trip_status(
  uuid, public.trip_status, text, double precision, double precision
) to authenticated;

create or replace function public.cancel_trip(
  p_trip_id uuid,
  p_reason text default null
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

  if not public.is_valid_trip_transition(v_from, 'cancelled') then
    raise exception 'cannot_cancel';
  end if;

  update public.trips
  set
    status = 'cancelled',
    cancelled_at = now(),
    cancelled_by = v_uid,
    cancel_reason = nullif(trim(coalesce(p_reason, '')), ''),
    completed_at = coalesce(completed_at, now())
  where id = p_trip_id
  returning * into v_trip;

  insert into public.trip_status_history (
    trip_id, from_status, to_status, changed_by, note
  ) values (
    p_trip_id, v_from, 'cancelled', v_uid, coalesce(p_reason, 'Cancelado')
  );

  update public.cargo_requests
  set status = 'cancelled'
  where id = v_trip.request_id and deleted_at is null;

  return v_trip;
end;
$$;

revoke all on function public.cancel_trip(uuid, text) from public;
grant execute on function public.cancel_trip(uuid, text) to authenticated;

create or replace function public.soft_delete_trip(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_trip
  from public.trips
  where id = p_trip_id and deleted_at is null;

  if not found then
    raise exception 'trip_not_found';
  end if;

  if v_trip.customer_id <> v_uid and v_trip.driver_id <> v_uid then
    raise exception 'not_allowed';
  end if;

  if v_trip.status not in ('completed', 'cancelled', 'failed') then
    raise exception 'trip_not_terminal';
  end if;

  update public.trips
  set deleted_at = now()
  where id = p_trip_id;
end;
$$;

revoke all on function public.soft_delete_trip(uuid) from public;
grant execute on function public.soft_delete_trip(uuid) to authenticated;

-- Participants can read request route details for their trip
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
        and (t.customer_id = auth.uid() or t.driver_id = auth.uid())
    )
  );
