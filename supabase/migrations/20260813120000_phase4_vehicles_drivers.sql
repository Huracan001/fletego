-- Phase 4: drivers, vehicles, documents metadata, availability

do $$ begin
  create type public.availability_status as enum (
    'offline',
    'available',
    'busy',
    'on_trip'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.document_kind as enum (
    'identity',
    'license',
    'vehicle_registration',
    'insurance',
    'other'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.vehicle_types (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_es text not null,
  name_en text not null,
  typical_max_weight_kg numeric(12, 2),
  supports_container boolean not null default false,
  supports_refrigeration boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.vehicle_types (code, name_es, name_en, typical_max_weight_kg, supports_container, supports_refrigeration)
values
  ('portacontenedor', 'Portacontenedor', 'Container chassis', 30000, true, false),
  ('cisterna', 'Cisterna', 'Tanker', 28000, false, false),
  ('ciguena', 'Cigüeña', 'Car carrier', 20000, false, false),
  ('sider', 'Sider', 'Curtain sider', 25000, false, false),
  ('acoplado', 'Acoplado', 'Trailer', 25000, false, false),
  ('camion_rigido', 'Camión rígido', 'Rigid truck', 15000, false, false),
  ('semirremolque', 'Semirremolque', 'Semi-trailer', 28000, false, false),
  ('plataforma', 'Plataforma', 'Flatbed', 25000, false, false),
  ('refrigerado', 'Refrigerado', 'Reefer', 22000, false, true),
  ('furgon', 'Furgón', 'Box truck', 12000, false, false),
  ('cama_baja', 'Cama baja', 'Lowboy', 40000, false, false),
  ('otro', 'Otro', 'Other', null, false, false)
on conflict (code) do nothing;

create table if not exists public.driver_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete cascade,
  license_number text,
  license_expiry date,
  verification_status public.verification_status not null default 'pending',
  years_experience integer,
  accepts_return_loads boolean not null default true,
  rating_avg numeric(3, 2) not null default 0,
  completed_trips integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

drop trigger if exists driver_profiles_set_updated_at on public.driver_profiles;
create trigger driver_profiles_set_updated_at
  before update on public.driver_profiles
  for each row execute function public.set_updated_at();

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid references public.profiles (id),
  company_id uuid references public.companies (id),
  vehicle_type_id uuid not null references public.vehicle_types (id),
  plate text not null,
  country_code text not null default 'BO',
  brand text,
  model text,
  year integer,
  capacity_kg numeric(12, 2),
  tare_kg numeric(12, 2),
  max_cargo_kg numeric(12, 2),
  length_m numeric(8, 2),
  width_m numeric(8, 2),
  height_m numeric(8, 2),
  body_type text,
  has_refrigeration boolean not null default false,
  has_tarp boolean not null default false,
  accepts_dangerous_goods boolean not null default false,
  insurance_provider text,
  insurance_policy text,
  insurance_expiry date,
  verification_status public.verification_status not null default 'pending',
  availability_status public.availability_status not null default 'offline',
  photo_paths text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint vehicles_owner_xor_company check (
    (owner_profile_id is not null and company_id is null)
    or (owner_profile_id is null and company_id is not null)
  ),
  constraint vehicles_plate_country_unique unique (country_code, plate)
);

create index if not exists vehicles_owner_idx on public.vehicles (owner_profile_id);
create index if not exists vehicles_company_idx on public.vehicles (company_id);
create index if not exists vehicles_type_idx on public.vehicles (vehicle_type_id);
create index if not exists vehicles_availability_idx on public.vehicles (availability_status);

drop trigger if exists vehicles_set_updated_at on public.vehicles;
create trigger vehicles_set_updated_at
  before update on public.vehicles
  for each row execute function public.set_updated_at();

create table if not exists public.driver_vehicles (
  id uuid primary key default gen_random_uuid(),
  driver_profile_id uuid not null references public.driver_profiles (id) on delete cascade,
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (driver_profile_id, vehicle_id)
);

create index if not exists driver_vehicles_vehicle_idx on public.driver_vehicles (vehicle_id);

create table if not exists public.driver_documents (
  id uuid primary key default gen_random_uuid(),
  driver_profile_id uuid not null references public.driver_profiles (id) on delete cascade,
  kind public.document_kind not null,
  storage_path text,
  issue_date date,
  expiry_date date,
  verification_status public.verification_status not null default 'pending',
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

drop trigger if exists driver_documents_set_updated_at on public.driver_documents;
create trigger driver_documents_set_updated_at
  before update on public.driver_documents
  for each row execute function public.set_updated_at();

create table if not exists public.vehicle_documents (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles (id) on delete cascade,
  kind public.document_kind not null,
  storage_path text,
  issue_date date,
  expiry_date date,
  verification_status public.verification_status not null default 'pending',
  reviewed_by uuid references public.profiles (id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

drop trigger if exists vehicle_documents_set_updated_at on public.vehicle_documents;
create trigger vehicle_documents_set_updated_at
  before update on public.vehicle_documents
  for each row execute function public.set_updated_at();

create table if not exists public.availability (
  id uuid primary key default gen_random_uuid(),
  driver_profile_id uuid not null references public.driver_profiles (id) on delete cascade,
  vehicle_id uuid not null references public.vehicles (id),
  status public.availability_status not null default 'available',
  current_lat double precision,
  current_lng double precision,
  available_from timestamptz,
  available_until timestamptz,
  preferred_destinations jsonb not null default '[]'::jsonb,
  accepts_return_cargo boolean not null default true,
  max_deadhead_km numeric(10, 2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists availability_driver_idx on public.availability (driver_profile_id);
create index if not exists availability_status_idx on public.availability (status);
create index if not exists availability_vehicle_idx on public.availability (vehicle_id);

drop trigger if exists availability_set_updated_at on public.availability;
create trigger availability_set_updated_at
  before update on public.availability
  for each row execute function public.set_updated_at();

-- Ensure driver profile exists for current user
create or replace function public.ensure_driver_profile()
returns public.driver_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.driver_profiles;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_row
  from public.driver_profiles
  where user_id = v_uid and deleted_at is null;

  if found then
    return v_row;
  end if;

  insert into public.driver_profiles (user_id)
  values (v_uid)
  returning * into v_row;

  update public.profiles
  set is_driver = true
  where id = v_uid;

  return v_row;
end;
$$;

revoke all on function public.ensure_driver_profile() from public;
grant execute on function public.ensure_driver_profile() to authenticated;

-- RLS
alter table public.vehicle_types enable row level security;
alter table public.driver_profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.driver_vehicles enable row level security;
alter table public.driver_documents enable row level security;
alter table public.vehicle_documents enable row level security;
alter table public.availability enable row level security;

drop policy if exists "vehicle_types_select_all" on public.vehicle_types;
create policy "vehicle_types_select_all"
  on public.vehicle_types for select
  to authenticated
  using (is_active = true);

drop policy if exists "driver_profiles_select_own" on public.driver_profiles;
create policy "driver_profiles_select_own"
  on public.driver_profiles for select
  to authenticated
  using (user_id = auth.uid() and deleted_at is null);

drop policy if exists "driver_profiles_insert_own" on public.driver_profiles;
create policy "driver_profiles_insert_own"
  on public.driver_profiles for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "driver_profiles_update_own" on public.driver_profiles;
create policy "driver_profiles_update_own"
  on public.driver_profiles for update
  to authenticated
  using (user_id = auth.uid() and deleted_at is null)
  with check (user_id = auth.uid());

drop policy if exists "vehicles_select_own_or_company" on public.vehicles;
create policy "vehicles_select_own_or_company"
  on public.vehicles for select
  to authenticated
  using (
    deleted_at is null
    and (
      owner_profile_id = auth.uid()
      or (company_id is not null and public.is_company_member(company_id))
      or exists (
        select 1
        from public.driver_vehicles dv
        join public.driver_profiles dp on dp.id = dv.driver_profile_id
        where dv.vehicle_id = vehicles.id
          and dv.deleted_at is null
          and dp.user_id = auth.uid()
          and dp.deleted_at is null
      )
    )
  );

drop policy if exists "vehicles_insert_own_or_company" on public.vehicles;
create policy "vehicles_insert_own_or_company"
  on public.vehicles for insert
  to authenticated
  with check (
    (owner_profile_id = auth.uid() and company_id is null)
    or (
      company_id is not null
      and owner_profile_id is null
      and public.has_company_role(
        company_id,
        array['company_admin', 'company_operator']::public.company_role[]
      )
    )
  );

drop policy if exists "vehicles_update_own_or_company" on public.vehicles;
create policy "vehicles_update_own_or_company"
  on public.vehicles for update
  to authenticated
  using (
    deleted_at is null
    and (
      owner_profile_id = auth.uid()
      or (
        company_id is not null
        and public.has_company_role(
          company_id,
          array['company_admin', 'company_operator']::public.company_role[]
        )
      )
    )
  )
  with check (
    owner_profile_id = auth.uid()
    or (
      company_id is not null
      and public.has_company_role(
        company_id,
        array['company_admin', 'company_operator']::public.company_role[]
      )
    )
  );

drop policy if exists "driver_vehicles_select" on public.driver_vehicles;
create policy "driver_vehicles_select"
  on public.driver_vehicles for select
  to authenticated
  using (
    deleted_at is null
    and exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.user_id = auth.uid()
    )
  );

drop policy if exists "driver_vehicles_write_own" on public.driver_vehicles;
create policy "driver_vehicles_write_own"
  on public.driver_vehicles for insert
  to authenticated
  with check (
    exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.user_id = auth.uid()
    )
  );

drop policy if exists "driver_vehicles_update_own" on public.driver_vehicles;
create policy "driver_vehicles_update_own"
  on public.driver_vehicles for update
  to authenticated
  using (
    exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.user_id = auth.uid()
    )
  );

drop policy if exists "driver_documents_own" on public.driver_documents;
create policy "driver_documents_own"
  on public.driver_documents for all
  to authenticated
  using (
    exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id
        and dp.user_id = auth.uid()
        and dp.deleted_at is null
    )
  )
  with check (
    exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.user_id = auth.uid()
    )
  );

drop policy if exists "vehicle_documents_access" on public.vehicle_documents;
create policy "vehicle_documents_access"
  on public.vehicle_documents for all
  to authenticated
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = vehicle_id
        and v.deleted_at is null
        and (
          v.owner_profile_id = auth.uid()
          or (
            v.company_id is not null
            and public.is_company_member(v.company_id)
          )
        )
    )
  )
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = vehicle_id
        and (
          v.owner_profile_id = auth.uid()
          or (
            v.company_id is not null
            and public.has_company_role(
              v.company_id,
              array['company_admin', 'company_operator']::public.company_role[]
            )
          )
        )
    )
  );

drop policy if exists "availability_own" on public.availability;
create policy "availability_own"
  on public.availability for all
  to authenticated
  using (
    exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.driver_profiles dp
      where dp.id = driver_profile_id and dp.user_id = auth.uid()
    )
  );
