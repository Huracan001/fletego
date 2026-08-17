-- Phase 3: companies, members, roles, RLS helpers

do $$ begin
  create type public.company_type as enum (
    'customer',
    'transporter',
    'both',
    'broker'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.company_role as enum (
    'company_admin',
    'company_operator',
    'company_finance',
    'company_viewer',
    'dispatcher'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.verification_status as enum (
    'pending',
    'approved',
    'rejected',
    'expired'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  legal_name text,
  nit text,
  country_code text not null default 'BO',
  company_type public.company_type not null default 'both',
  phone text,
  email text,
  address text,
  verification_status public.verification_status not null default 'pending',
  logo_path text,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists companies_created_by_idx on public.companies (created_by);
create index if not exists companies_nit_idx on public.companies (nit);
create index if not exists companies_type_idx on public.companies (company_type);

drop trigger if exists companies_set_updated_at on public.companies;
create trigger companies_set_updated_at
  before update on public.companies
  for each row execute function public.set_updated_at();

create table if not exists public.company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id),
  user_id uuid not null references public.profiles (id),
  role public.company_role not null default 'company_viewer',
  invited_by uuid references public.profiles (id),
  joined_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (company_id, user_id)
);

create index if not exists company_members_user_idx on public.company_members (user_id);
create index if not exists company_members_company_idx on public.company_members (company_id);
create index if not exists company_members_role_idx on public.company_members (role);

drop trigger if exists company_members_set_updated_at on public.company_members;
create trigger company_members_set_updated_at
  before update on public.company_members
  for each row execute function public.set_updated_at();

-- RLS helpers
create or replace function public.is_company_member(p_company_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.company_members cm
    where cm.company_id = p_company_id
      and cm.user_id = auth.uid()
      and cm.deleted_at is null
  );
$$;

create or replace function public.has_company_role(
  p_company_id uuid,
  p_roles public.company_role[]
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.company_members cm
    where cm.company_id = p_company_id
      and cm.user_id = auth.uid()
      and cm.deleted_at is null
      and cm.role = any (p_roles)
  );
$$;

revoke all on function public.is_company_member(uuid) from public;
revoke all on function public.has_company_role(uuid, public.company_role[]) from public;
grant execute on function public.is_company_member(uuid) to authenticated;
grant execute on function public.has_company_role(uuid, public.company_role[]) to authenticated;

-- Atomic company creation: company + creator as company_admin
create or replace function public.create_company(
  p_name text,
  p_company_type public.company_type default 'both',
  p_legal_name text default null,
  p_nit text default null,
  p_phone text default null,
  p_email text default null,
  p_address text default null,
  p_country_code text default 'BO'
)
returns public.companies
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_company public.companies;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_name is null or length(trim(p_name)) < 2 then
    raise exception 'invalid company name';
  end if;

  insert into public.companies (
    name,
    legal_name,
    nit,
    country_code,
    company_type,
    phone,
    email,
    address,
    created_by
  ) values (
    trim(p_name),
    nullif(trim(coalesce(p_legal_name, '')), ''),
    nullif(trim(coalesce(p_nit, '')), ''),
    coalesce(nullif(trim(p_country_code), ''), 'BO'),
    p_company_type,
    nullif(trim(coalesce(p_phone, '')), ''),
    nullif(trim(coalesce(p_email, '')), ''),
    nullif(trim(coalesce(p_address, '')), ''),
    v_uid
  )
  returning * into v_company;

  insert into public.company_members (company_id, user_id, role, invited_by)
  values (v_company.id, v_uid, 'company_admin', v_uid);

  return v_company;
end;
$$;

revoke all on function public.create_company(
  text, public.company_type, text, text, text, text, text, text
) from public;
grant execute on function public.create_company(
  text, public.company_type, text, text, text, text, text, text
) to authenticated;

-- Invite existing FLETEGO user by email (admin only). Looks up profile server-side.
create or replace function public.add_company_member_by_email(
  p_company_id uuid,
  p_email text,
  p_role public.company_role default 'company_viewer'
)
returns public.company_members
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_target uuid;
  v_member public.company_members;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if not public.has_company_role(
    p_company_id,
    array['company_admin']::public.company_role[]
  ) then
    raise exception 'not allowed';
  end if;

  select p.id into v_target
  from public.profiles p
  where lower(p.email) = lower(trim(p_email))
    and p.deleted_at is null
  limit 1;

  if v_target is null then
    raise exception 'user_not_found';
  end if;

  insert into public.company_members (company_id, user_id, role, invited_by)
  values (p_company_id, v_target, p_role, v_uid)
  on conflict (company_id, user_id) do update
    set role = excluded.role,
        deleted_at = null,
        invited_by = v_uid,
        updated_at = now()
  returning * into v_member;

  return v_member;
end;
$$;

revoke all on function public.add_company_member_by_email(
  uuid, text, public.company_role
) from public;
grant execute on function public.add_company_member_by_email(
  uuid, text, public.company_role
) to authenticated;

alter table public.companies enable row level security;
alter table public.company_members enable row level security;

drop policy if exists "companies_select_member" on public.companies;
create policy "companies_select_member"
  on public.companies for select
  to authenticated
  using (deleted_at is null and public.is_company_member(id));

drop policy if exists "companies_update_admin" on public.companies;
create policy "companies_update_admin"
  on public.companies for update
  to authenticated
  using (
    deleted_at is null
    and public.has_company_role(id, array['company_admin']::public.company_role[])
  )
  with check (
    public.has_company_role(id, array['company_admin']::public.company_role[])
  );

drop policy if exists "company_members_select" on public.company_members;
create policy "company_members_select"
  on public.company_members for select
  to authenticated
  using (
    deleted_at is null
    and public.is_company_member(company_id)
  );

drop policy if exists "company_members_insert_admin" on public.company_members;
create policy "company_members_insert_admin"
  on public.company_members for insert
  to authenticated
  with check (
    public.has_company_role(
      company_id,
      array['company_admin']::public.company_role[]
    )
  );

drop policy if exists "company_members_update_admin" on public.company_members;
create policy "company_members_update_admin"
  on public.company_members for update
  to authenticated
  using (
    public.has_company_role(
      company_id,
      array['company_admin']::public.company_role[]
    )
  )
  with check (
    public.has_company_role(
      company_id,
      array['company_admin']::public.company_role[]
    )
  );

-- Allow reading teammate profiles within shared companies
drop policy if exists "profiles_select_company_peers" on public.profiles;
create policy "profiles_select_company_peers"
  on public.profiles for select
  to authenticated
  using (
    deleted_at is null
    and exists (
      select 1
      from public.company_members me
      join public.company_members peer
        on peer.company_id = me.company_id
       and peer.deleted_at is null
      where me.user_id = auth.uid()
        and me.deleted_at is null
        and peer.user_id = profiles.id
    )
  );
