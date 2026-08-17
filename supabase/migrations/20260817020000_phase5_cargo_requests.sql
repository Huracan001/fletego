-- Phase 5: cargo requests + containers

do $$ begin
  create type public.cargo_type as enum (
    'contenedor',
    'carga_general',
    'liquidos',
    'vehiculos',
    'maquinaria',
    'refrigerada',
    'carga_peligrosa',
    'otra'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.request_status as enum (
    'draft',
    'submitted',
    'matching',
    'offered',
    'assigned',
    'cancelled',
    'expired'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.schedule_mode as enum ('asap', 'scheduled');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.container_type as enum (
    'ft20',
    'ft40',
    'ft40_hc',
    'ft45'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.cargo_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles (id),
  company_id uuid references public.companies (id),
  status public.request_status not null default 'draft',
  cargo_type public.cargo_type not null,
  schedule_mode public.schedule_mode not null default 'asap',
  pickup_at timestamptz,
  pickup_window_start time,
  pickup_window_end time,

  origin_country_code text not null default 'BO',
  origin_admin_area text,
  origin_city text not null,
  origin_address_line text,
  origin_label text,
  origin_lat double precision,
  origin_lng double precision,
  origin_instructions text,

  destination_country_code text not null default 'BO',
  destination_admin_area text,
  destination_city text not null,
  destination_address_line text,
  destination_label text,
  destination_lat double precision,
  destination_lng double precision,
  destination_instructions text,

  total_weight_kg numeric(12, 2),
  length_m numeric(8, 2),
  width_m numeric(8, 2),
  height_m numeric(8, 2),
  stackable boolean not null default true,
  requires_tarp boolean not null default false,
  requires_special_loading boolean not null default false,
  requires_refrigeration boolean not null default false,
  dangerous_goods boolean not null default false,
  special_requirements text[] not null default '{}',
  special_instructions text,

  requested_vehicle_type_id uuid references public.vehicle_types (id),
  recommended_vehicle_type_id uuid references public.vehicle_types (id),
  user_selected_unknown_truck boolean not null default false,

  currency text not null default 'BOB',
  cancelled_at timestamptz,
  cancel_reason text,
  cancelled_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists cargo_requests_customer_idx on public.cargo_requests (customer_id);
create index if not exists cargo_requests_status_idx on public.cargo_requests (status);
create index if not exists cargo_requests_created_idx on public.cargo_requests (created_at desc);

drop trigger if exists cargo_requests_set_updated_at on public.cargo_requests;
create trigger cargo_requests_set_updated_at
  before update on public.cargo_requests
  for each row execute function public.set_updated_at();

create table if not exists public.containers (
  id uuid primary key default gen_random_uuid(),
  cargo_request_id uuid not null unique references public.cargo_requests (id) on delete cascade,
  container_type public.container_type not null,
  container_number text,
  gross_weight_kg numeric(12, 2),
  refrigerated boolean not null default false,
  dangerous_goods boolean not null default false,
  imo text,
  un_number text,
  booking_ref text,
  bl_ref text,
  shipping_line text,
  origin_port text,
  destination_port text,
  return_deadline timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists containers_set_updated_at on public.containers;
create trigger containers_set_updated_at
  before update on public.containers
  for each row execute function public.set_updated_at();

-- Submit request atomically (request + optional container) → matching
create or replace function public.submit_cargo_request(p_payload jsonb)
returns public.cargo_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_req public.cargo_requests;
  v_container jsonb;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  insert into public.cargo_requests (
    customer_id,
    company_id,
    status,
    cargo_type,
    schedule_mode,
    pickup_at,
    pickup_window_start,
    pickup_window_end,
    origin_country_code,
    origin_admin_area,
    origin_city,
    origin_address_line,
    origin_label,
    origin_lat,
    origin_lng,
    origin_instructions,
    destination_country_code,
    destination_admin_area,
    destination_city,
    destination_address_line,
    destination_label,
    destination_lat,
    destination_lng,
    destination_instructions,
    total_weight_kg,
    length_m,
    width_m,
    height_m,
    stackable,
    requires_tarp,
    requires_special_loading,
    requires_refrigeration,
    dangerous_goods,
    special_requirements,
    special_instructions,
    requested_vehicle_type_id,
    recommended_vehicle_type_id,
    user_selected_unknown_truck,
    currency
  ) values (
    v_uid,
    nullif(p_payload ->> 'company_id', '')::uuid,
    'matching',
    (p_payload ->> 'cargo_type')::public.cargo_type,
    coalesce((p_payload ->> 'schedule_mode')::public.schedule_mode, 'asap'),
    nullif(p_payload ->> 'pickup_at', '')::timestamptz,
    nullif(p_payload ->> 'pickup_window_start', '')::time,
    nullif(p_payload ->> 'pickup_window_end', '')::time,
    coalesce(p_payload ->> 'origin_country_code', 'BO'),
    p_payload ->> 'origin_admin_area',
    p_payload ->> 'origin_city',
    p_payload ->> 'origin_address_line',
    p_payload ->> 'origin_label',
    nullif(p_payload ->> 'origin_lat', '')::double precision,
    nullif(p_payload ->> 'origin_lng', '')::double precision,
    p_payload ->> 'origin_instructions',
    coalesce(p_payload ->> 'destination_country_code', 'BO'),
    p_payload ->> 'destination_admin_area',
    p_payload ->> 'destination_city',
    p_payload ->> 'destination_address_line',
    p_payload ->> 'destination_label',
    nullif(p_payload ->> 'destination_lat', '')::double precision,
    nullif(p_payload ->> 'destination_lng', '')::double precision,
    p_payload ->> 'destination_instructions',
    nullif(p_payload ->> 'total_weight_kg', '')::numeric,
    nullif(p_payload ->> 'length_m', '')::numeric,
    nullif(p_payload ->> 'width_m', '')::numeric,
    nullif(p_payload ->> 'height_m', '')::numeric,
    coalesce((p_payload ->> 'stackable')::boolean, true),
    coalesce((p_payload ->> 'requires_tarp')::boolean, false),
    coalesce((p_payload ->> 'requires_special_loading')::boolean, false),
    coalesce((p_payload ->> 'requires_refrigeration')::boolean, false),
    coalesce((p_payload ->> 'dangerous_goods')::boolean, false),
    coalesce(
      array(select jsonb_array_elements_text(p_payload -> 'special_requirements')),
      '{}'::text[]
    ),
    p_payload ->> 'special_instructions',
    nullif(p_payload ->> 'requested_vehicle_type_id', '')::uuid,
    nullif(p_payload ->> 'recommended_vehicle_type_id', '')::uuid,
    coalesce((p_payload ->> 'user_selected_unknown_truck')::boolean, false),
    coalesce(p_payload ->> 'currency', 'BOB')
  )
  returning * into v_req;

  v_container := p_payload -> 'container';
  if v_container is not null and v_container != 'null'::jsonb then
    insert into public.containers (
      cargo_request_id,
      container_type,
      container_number,
      gross_weight_kg,
      refrigerated,
      dangerous_goods,
      imo,
      un_number,
      booking_ref,
      bl_ref,
      shipping_line,
      origin_port,
      destination_port,
      return_deadline
    ) values (
      v_req.id,
      (v_container ->> 'container_type')::public.container_type,
      v_container ->> 'container_number',
      nullif(v_container ->> 'gross_weight_kg', '')::numeric,
      coalesce((v_container ->> 'refrigerated')::boolean, false),
      coalesce((v_container ->> 'dangerous_goods')::boolean, false),
      v_container ->> 'imo',
      v_container ->> 'un_number',
      v_container ->> 'booking_ref',
      v_container ->> 'bl_ref',
      v_container ->> 'shipping_line',
      v_container ->> 'origin_port',
      v_container ->> 'destination_port',
      nullif(v_container ->> 'return_deadline', '')::timestamptz
    );
  end if;

  return v_req;
end;
$$;

revoke all on function public.submit_cargo_request(jsonb) from public;
grant execute on function public.submit_cargo_request(jsonb) to authenticated;

alter table public.cargo_requests enable row level security;
alter table public.containers enable row level security;

drop policy if exists "cargo_requests_select_own" on public.cargo_requests;
create policy "cargo_requests_select_own"
  on public.cargo_requests for select
  to authenticated
  using (customer_id = auth.uid() and deleted_at is null);

drop policy if exists "cargo_requests_insert_own" on public.cargo_requests;
create policy "cargo_requests_insert_own"
  on public.cargo_requests for insert
  to authenticated
  with check (customer_id = auth.uid());

drop policy if exists "cargo_requests_update_own" on public.cargo_requests;
create policy "cargo_requests_update_own"
  on public.cargo_requests for update
  to authenticated
  using (customer_id = auth.uid() and deleted_at is null)
  with check (customer_id = auth.uid());

drop policy if exists "containers_select_own" on public.containers;
create policy "containers_select_own"
  on public.containers for select
  to authenticated
  using (
    exists (
      select 1 from public.cargo_requests r
      where r.id = cargo_request_id
        and r.customer_id = auth.uid()
        and r.deleted_at is null
    )
  );

drop policy if exists "containers_insert_own" on public.containers;
create policy "containers_insert_own"
  on public.containers for insert
  to authenticated
  with check (
    exists (
      select 1 from public.cargo_requests r
      where r.id = cargo_request_id and r.customer_id = auth.uid()
    )
  );
