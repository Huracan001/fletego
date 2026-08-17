-- Phase 10: pickup evidence + proof of delivery (POD)

create table if not exists public.pickup_evidence (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null unique references public.trips (id),
  notes text,
  photo_paths text[] not null default '{}',
  lat double precision,
  lng double precision,
  captured_at timestamptz not null default now(),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists pickup_evidence_set_updated_at on public.pickup_evidence;
create trigger pickup_evidence_set_updated_at
  before update on public.pickup_evidence
  for each row execute function public.set_updated_at();

create table if not exists public.proof_of_delivery (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null unique references public.trips (id),
  recipient_name text not null,
  recipient_id_ref text,
  signature_path text,
  photo_paths text[] not null default '{}',
  notes text,
  lat double precision,
  lng double precision,
  captured_at timestamptz not null default now(),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pod_recipient_not_blank check (length(trim(recipient_name)) > 0)
);

drop trigger if exists proof_of_delivery_set_updated_at on public.proof_of_delivery;
create trigger proof_of_delivery_set_updated_at
  before update on public.proof_of_delivery
  for each row execute function public.set_updated_at();

alter table public.pickup_evidence enable row level security;
alter table public.proof_of_delivery enable row level security;

drop policy if exists "pickup_evidence_select_participants" on public.pickup_evidence;
create policy "pickup_evidence_select_participants"
  on public.pickup_evidence for select
  to authenticated
  using (public.can_access_trip(trip_id));

drop policy if exists "pod_select_participants" on public.proof_of_delivery;
create policy "pod_select_participants"
  on public.proof_of_delivery for select
  to authenticated
  using (public.can_access_trip(trip_id));

create or replace function public.submit_pickup_evidence(
  p_trip_id uuid,
  p_notes text default null,
  p_photo_paths text[] default '{}',
  p_lat double precision default null,
  p_lng double precision default null
)
returns public.pickup_evidence
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
  v_row public.pickup_evidence;
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

  if v_trip.driver_id <> v_uid then
    raise exception 'driver_only';
  end if;

  if v_trip.status not in (
    'arrived_at_pickup',
    'cargo_picked_up',
    'in_transit',
    'arrived_at_destination',
    'delivering',
    'delivered',
    'completed'
  ) then
    raise exception 'invalid_status_for_pickup';
  end if;

  insert into public.pickup_evidence (
    trip_id, notes, photo_paths, lat, lng, captured_at, created_by
  ) values (
    p_trip_id,
    nullif(trim(coalesce(p_notes, '')), ''),
    coalesce(p_photo_paths, '{}'),
    p_lat,
    p_lng,
    now(),
    v_uid
  )
  on conflict (trip_id) do update set
    notes = excluded.notes,
    photo_paths = excluded.photo_paths,
    lat = coalesce(excluded.lat, public.pickup_evidence.lat),
    lng = coalesce(excluded.lng, public.pickup_evidence.lng),
    captured_at = excluded.captured_at,
    updated_at = now()
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.submit_pickup_evidence(
  uuid, text, text[], double precision, double precision
) from public;
grant execute on function public.submit_pickup_evidence(
  uuid, text, text[], double precision, double precision
) to authenticated;

create or replace function public.submit_proof_of_delivery(
  p_trip_id uuid,
  p_recipient_name text,
  p_recipient_id_ref text default null,
  p_signature_path text default null,
  p_photo_paths text[] default '{}',
  p_notes text default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_mark_delivered boolean default true
)
returns public.proof_of_delivery
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
  v_row public.proof_of_delivery;
  v_from public.trip_status;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_recipient_name is null or length(trim(p_recipient_name)) = 0 then
    raise exception 'recipient_required';
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

  if v_trip.status not in (
    'arrived_at_destination',
    'delivering',
    'delivered',
    'completed'
  ) then
    raise exception 'invalid_status_for_pod';
  end if;

  insert into public.proof_of_delivery (
    trip_id,
    recipient_name,
    recipient_id_ref,
    signature_path,
    photo_paths,
    notes,
    lat,
    lng,
    captured_at,
    created_by
  ) values (
    p_trip_id,
    trim(p_recipient_name),
    nullif(trim(coalesce(p_recipient_id_ref, '')), ''),
    nullif(trim(coalesce(p_signature_path, '')), ''),
    coalesce(p_photo_paths, '{}'),
    nullif(trim(coalesce(p_notes, '')), ''),
    p_lat,
    p_lng,
    now(),
    v_uid
  )
  on conflict (trip_id) do update set
    recipient_name = excluded.recipient_name,
    recipient_id_ref = excluded.recipient_id_ref,
    signature_path = excluded.signature_path,
    photo_paths = excluded.photo_paths,
    notes = excluded.notes,
    lat = coalesce(excluded.lat, public.proof_of_delivery.lat),
    lng = coalesce(excluded.lng, public.proof_of_delivery.lng),
    captured_at = excluded.captured_at,
    updated_at = now()
  returning * into v_row;

  if p_mark_delivered
     and v_trip.status in ('arrived_at_destination', 'delivering')
     and public.is_valid_trip_transition(v_trip.status, 'delivered')
  then
    v_from := v_trip.status;
    update public.trips
    set status = 'delivered',
        current_lat = coalesce(p_lat, current_lat),
        current_lng = coalesce(p_lng, current_lng)
    where id = p_trip_id;

    insert into public.trip_status_history (
      trip_id, from_status, to_status, changed_by, note, lat, lng
    ) values (
      p_trip_id, v_from, 'delivered', v_uid, 'POD registrada', p_lat, p_lng
    );
  end if;

  return v_row;
end;
$$;

revoke all on function public.submit_proof_of_delivery(
  uuid, text, text, text, text[], text, double precision, double precision, boolean
) from public;
grant execute on function public.submit_proof_of_delivery(
  uuid, text, text, text, text[], text, double precision, double precision, boolean
) to authenticated;
