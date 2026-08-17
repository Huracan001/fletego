-- Phase 6: offers, marketplace visibility, trip bootstrap on accept

do $$ begin
  create type public.offer_status as enum (
    'pending',
    'accepted',
    'rejected',
    'withdrawn',
    'expired'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.trip_status as enum (
    'requested',
    'matching',
    'offer_received',
    'assigned',
    'driver_going_to_pickup',
    'arrived_at_pickup',
    'cargo_picked_up',
    'in_transit',
    'arrived_at_destination',
    'delivering',
    'delivered',
    'completed',
    'cancelled',
    'disputed',
    'failed'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.cargo_requests (id),
  transporter_profile_id uuid not null references public.profiles (id),
  company_id uuid references public.companies (id),
  driver_profile_id uuid references public.driver_profiles (id),
  vehicle_id uuid not null references public.vehicles (id),
  price_amount numeric(14, 2) not null,
  currency text not null default 'BOB',
  eta_pickup_at timestamptz,
  message text,
  status public.offer_status not null default 'pending',
  distance_km_estimate numeric(10, 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists offers_request_idx on public.offers (request_id);
create index if not exists offers_transporter_idx on public.offers (transporter_profile_id);
create index if not exists offers_status_idx on public.offers (status);

drop trigger if exists offers_set_updated_at on public.offers;
create trigger offers_set_updated_at
  before update on public.offers
  for each row execute function public.set_updated_at();

create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.cargo_requests (id),
  offer_id uuid not null references public.offers (id),
  customer_id uuid not null references public.profiles (id),
  driver_id uuid not null references public.profiles (id),
  vehicle_id uuid not null references public.vehicles (id),
  company_id uuid references public.companies (id),
  status public.trip_status not null default 'assigned',
  assigned_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancel_reason text,
  cancelled_by uuid references public.profiles (id),
  current_lat double precision,
  current_lng double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists trips_customer_idx on public.trips (customer_id);
create index if not exists trips_driver_idx on public.trips (driver_id);
create index if not exists trips_status_idx on public.trips (status);

drop trigger if exists trips_set_updated_at on public.trips;
create trigger trips_set_updated_at
  before update on public.trips
  for each row execute function public.set_updated_at();

create table if not exists public.trip_status_history (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id) on delete cascade,
  from_status public.trip_status,
  to_status public.trip_status not null,
  changed_by uuid references public.profiles (id),
  note text,
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);

create index if not exists trip_status_history_trip_idx
  on public.trip_status_history (trip_id, created_at desc);

-- Marketplace: drivers with a driver_profile can see open matching requests
drop policy if exists "cargo_requests_select_marketplace" on public.cargo_requests;
create policy "cargo_requests_select_marketplace"
  on public.cargo_requests for select
  to authenticated
  using (
    deleted_at is null
    and status in ('matching', 'offered')
    and exists (
      select 1 from public.driver_profiles dp
      where dp.user_id = auth.uid() and dp.deleted_at is null
    )
  );

-- List open loads for marketplace (server-side filter)
create or replace function public.list_marketplace_loads()
returns setof public.cargo_requests
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not exists (
    select 1 from public.driver_profiles dp
    where dp.user_id = auth.uid() and dp.deleted_at is null
  ) then
    raise exception 'not a driver';
  end if;

  return query
  select r.*
  from public.cargo_requests r
  where r.deleted_at is null
    and r.status in ('matching', 'offered')
    and r.customer_id <> auth.uid()
  order by r.created_at desc
  limit 100;
end;
$$;

revoke all on function public.list_marketplace_loads() from public;
grant execute on function public.list_marketplace_loads() to authenticated;

-- Create offer
create or replace function public.create_offer(
  p_request_id uuid,
  p_vehicle_id uuid,
  p_price_amount numeric,
  p_message text default null,
  p_eta_pickup_at timestamptz default null,
  p_distance_km_estimate numeric default null
)
returns public.offers
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_driver public.driver_profiles;
  v_request public.cargo_requests;
  v_vehicle public.vehicles;
  v_offer public.offers;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_driver
  from public.driver_profiles
  where user_id = v_uid and deleted_at is null;

  if not found then
    raise exception 'driver_profile_required';
  end if;

  select * into v_request
  from public.cargo_requests
  where id = p_request_id and deleted_at is null;

  if not found then
    raise exception 'request_not_found';
  end if;

  if v_request.status not in ('matching', 'offered') then
    raise exception 'request_not_open';
  end if;

  if v_request.customer_id = v_uid then
    raise exception 'cannot_offer_own_request';
  end if;

  select * into v_vehicle
  from public.vehicles
  where id = p_vehicle_id and deleted_at is null;

  if not found then
    raise exception 'vehicle_not_found';
  end if;

  if v_vehicle.owner_profile_id is distinct from v_uid
     and not (
       v_vehicle.company_id is not null
       and public.is_company_member(v_vehicle.company_id)
     )
     and not exists (
       select 1 from public.driver_vehicles dv
       where dv.vehicle_id = v_vehicle.id
         and dv.driver_profile_id = v_driver.id
         and dv.deleted_at is null
     )
  then
    raise exception 'vehicle_not_allowed';
  end if;

  if p_price_amount is null or p_price_amount <= 0 then
    raise exception 'invalid_price';
  end if;

  insert into public.offers (
    request_id,
    transporter_profile_id,
    company_id,
    driver_profile_id,
    vehicle_id,
    price_amount,
    currency,
    eta_pickup_at,
    message,
    status,
    distance_km_estimate
  ) values (
    p_request_id,
    v_uid,
    v_vehicle.company_id,
    v_driver.id,
    p_vehicle_id,
    p_price_amount,
    'BOB',
    p_eta_pickup_at,
    p_message,
    'pending',
    p_distance_km_estimate
  )
  returning * into v_offer;

  update public.cargo_requests
  set status = 'offered'
  where id = p_request_id
    and status = 'matching';

  return v_offer;
end;
$$;

revoke all on function public.create_offer(
  uuid, uuid, numeric, text, timestamptz, numeric
) from public;
grant execute on function public.create_offer(
  uuid, uuid, numeric, text, timestamptz, numeric
) to authenticated;

-- Accept offer → create trip
create or replace function public.accept_offer(p_offer_id uuid)
returns public.trips
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_offer public.offers;
  v_request public.cargo_requests;
  v_driver_user uuid;
  v_trip public.trips;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_offer
  from public.offers
  where id = p_offer_id and deleted_at is null;

  if not found then
    raise exception 'offer_not_found';
  end if;

  if v_offer.status <> 'pending' then
    raise exception 'offer_not_pending';
  end if;

  select * into v_request
  from public.cargo_requests
  where id = v_offer.request_id and deleted_at is null;

  if not found or v_request.customer_id <> v_uid then
    raise exception 'not_allowed';
  end if;

  if v_request.status not in ('matching', 'offered') then
    raise exception 'request_not_open';
  end if;

  select user_id into v_driver_user
  from public.driver_profiles
  where id = v_offer.driver_profile_id;

  if v_driver_user is null then
    v_driver_user := v_offer.transporter_profile_id;
  end if;

  update public.offers
  set status = 'accepted'
  where id = v_offer.id;

  update public.offers
  set status = 'rejected'
  where request_id = v_offer.request_id
    and id <> v_offer.id
    and status = 'pending'
    and deleted_at is null;

  update public.cargo_requests
  set status = 'assigned'
  where id = v_offer.request_id;

  insert into public.trips (
    request_id,
    offer_id,
    customer_id,
    driver_id,
    vehicle_id,
    company_id,
    status,
    assigned_at
  ) values (
    v_offer.request_id,
    v_offer.id,
    v_request.customer_id,
    v_driver_user,
    v_offer.vehicle_id,
    v_offer.company_id,
    'assigned',
    now()
  )
  returning * into v_trip;

  insert into public.trip_status_history (trip_id, from_status, to_status, changed_by, note)
  values (v_trip.id, null, 'assigned', v_uid, 'Oferta aceptada');

  return v_trip;
end;
$$;

revoke all on function public.accept_offer(uuid) from public;
grant execute on function public.accept_offer(uuid) to authenticated;

alter table public.offers enable row level security;
alter table public.trips enable row level security;
alter table public.trip_status_history enable row level security;

drop policy if exists "offers_select_participants" on public.offers;
create policy "offers_select_participants"
  on public.offers for select
  to authenticated
  using (
    deleted_at is null
    and (
      transporter_profile_id = auth.uid()
      or exists (
        select 1 from public.cargo_requests r
        where r.id = request_id and r.customer_id = auth.uid()
      )
    )
  );

drop policy if exists "offers_update_own_pending" on public.offers;
create policy "offers_update_own_pending"
  on public.offers for update
  to authenticated
  using (transporter_profile_id = auth.uid() and status = 'pending')
  with check (transporter_profile_id = auth.uid());

drop policy if exists "trips_select_participants" on public.trips;
create policy "trips_select_participants"
  on public.trips for select
  to authenticated
  using (
    deleted_at is null
    and (customer_id = auth.uid() or driver_id = auth.uid())
  );

drop policy if exists "trip_history_select_participants" on public.trip_status_history;
create policy "trip_history_select_participants"
  on public.trip_status_history for select
  to authenticated
  using (
    exists (
      select 1 from public.trips t
      where t.id = trip_id
        and (t.customer_id = auth.uid() or t.driver_id = auth.uid())
    )
  );
