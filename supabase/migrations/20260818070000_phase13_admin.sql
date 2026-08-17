-- Phase 13: platform admin helpers, review metadata, disputes, app_config

-- ---------------------------------------------------------------------------
-- Platform admin helper
-- ---------------------------------------------------------------------------
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.deleted_at is null
      and p.platform_role in ('admin', 'super_admin')
  );
$$;

revoke all on function public.is_platform_admin() from public;
grant execute on function public.is_platform_admin() to authenticated;

-- Allow service_role (admin server) to change platform_role; still block clients.
create or replace function public.prevent_platform_role_escalation()
returns trigger
language plpgsql
as $$
begin
  if new.platform_role is distinct from old.platform_role then
    if auth.role() = 'service_role' then
      return new;
    end if;
    raise exception 'platform_role cannot be changed by clients';
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Review metadata on entities (documents already have these columns)
-- ---------------------------------------------------------------------------
alter table public.companies
  add column if not exists reviewed_by uuid references public.profiles (id),
  add column if not exists reviewed_at timestamptz,
  add column if not exists rejection_reason text;

alter table public.driver_profiles
  add column if not exists reviewed_by uuid references public.profiles (id),
  add column if not exists reviewed_at timestamptz,
  add column if not exists rejection_reason text;

alter table public.vehicles
  add column if not exists reviewed_by uuid references public.profiles (id),
  add column if not exists reviewed_at timestamptz,
  add column if not exists rejection_reason text;

-- ---------------------------------------------------------------------------
-- Disputes (structured cases; trip.status = disputed still used)
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.dispute_status as enum (
    'open',
    'under_review',
    'resolved',
    'dismissed'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.disputes (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id),
  opened_by uuid not null references public.profiles (id),
  reason text not null,
  status public.dispute_status not null default 'open',
  resolution text,
  resolved_by uuid references public.profiles (id),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists disputes_trip_idx on public.disputes (trip_id);
create index if not exists disputes_status_idx on public.disputes (status)
  where deleted_at is null;

drop trigger if exists disputes_set_updated_at on public.disputes;
create trigger disputes_set_updated_at
  before update on public.disputes
  for each row execute function public.set_updated_at();

alter table public.disputes enable row level security;

drop policy if exists "disputes_select_participants_or_admin" on public.disputes;
create policy "disputes_select_participants_or_admin"
  on public.disputes for select
  to authenticated
  using (
    deleted_at is null
    and (
      opened_by = auth.uid()
      or public.can_access_trip(trip_id)
      or public.is_platform_admin()
    )
  );

drop policy if exists "disputes_insert_participants" on public.disputes;
create policy "disputes_insert_participants"
  on public.disputes for insert
  to authenticated
  with check (
    opened_by = auth.uid()
    and public.can_access_trip(trip_id)
  );

drop policy if exists "disputes_update_admin" on public.disputes;
create policy "disputes_update_admin"
  on public.disputes for update
  to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

-- ---------------------------------------------------------------------------
-- Lightweight system config (vehicle catalog remains in vehicle_types)
-- ---------------------------------------------------------------------------
create table if not exists public.app_config (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  description text,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id)
);

alter table public.app_config enable row level security;

drop policy if exists "app_config_select_authenticated" on public.app_config;
create policy "app_config_select_authenticated"
  on public.app_config for select
  to authenticated
  using (true);

drop policy if exists "app_config_write_admin" on public.app_config;
create policy "app_config_write_admin"
  on public.app_config for all
  to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());

insert into public.app_config (key, value, description)
values
  (
    'marketplace',
    '{"matching_enabled": true, "max_offers_per_request": 20}'::jsonb,
    'Marketplace / matching toggles'
  ),
  (
    'support',
    '{"contact_email": "soporte@fletego.app", "whatsapp": null}'::jsonb,
    'Support contact shown in ops tooling'
  )
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- Audit log (admin writes via service role / trusted paths)
-- ---------------------------------------------------------------------------
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles (id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_logs_created_idx on public.audit_logs (created_at desc);

alter table public.audit_logs enable row level security;

drop policy if exists "audit_logs_select_admin" on public.audit_logs;
create policy "audit_logs_select_admin"
  on public.audit_logs for select
  to authenticated
  using (public.is_platform_admin());

-- Inserts typically via service role; allow admins too.
drop policy if exists "audit_logs_insert_admin" on public.audit_logs;
create policy "audit_logs_insert_admin"
  on public.audit_logs for insert
  to authenticated
  with check (public.is_platform_admin());
