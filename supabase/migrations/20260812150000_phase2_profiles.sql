-- Phase 2: profiles + auth bootstrap
-- Apply via Supabase SQL Editor or: supabase db push

create extension if not exists "pgcrypto";

do $$ begin
  create type public.platform_role as enum ('user', 'admin', 'super_admin');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.onboarding_intent as enum (
    'need_transport',
    'offer_transport',
    'manage_transport'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.customer_profile_type as enum (
    'persona_natural',
    'empresa',
    'importador',
    'exportador',
    'agencia_despachante',
    'operador_logistico'
  );
exception when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  display_name text,
  phone text,
  email text,
  avatar_path text,
  platform_role public.platform_role not null default 'user',
  onboarding_intent public.onboarding_intent,
  customer_type public.customer_profile_type,
  ci_number text,
  country_code text not null default 'BO',
  locale text not null default 'es',
  is_driver boolean not null default false,
  is_customer boolean not null default false,
  rating_avg numeric(3, 2) not null default 0,
  rating_count integer not null default 0,
  onboarding_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists profiles_email_idx on public.profiles (email);
create index if not exists profiles_onboarding_intent_idx
  on public.profiles (onboarding_intent);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  intent public.onboarding_intent;
  full_name text;
begin
  full_name := nullif(new.raw_user_meta_data ->> 'full_name', '');
  begin
    intent := (new.raw_user_meta_data ->> 'onboarding_intent')::public.onboarding_intent;
  exception when others then
    intent := null;
  end;

  insert into public.profiles (
    id,
    email,
    full_name,
    display_name,
    onboarding_intent,
    is_customer,
    is_driver,
    onboarding_completed_at
  ) values (
    new.id,
    new.email,
    full_name,
    full_name,
    intent,
    coalesce(intent = 'need_transport' or intent = 'manage_transport', false),
    coalesce(intent = 'offer_transport', false),
    case when intent is not null then now() else null end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id and deleted_at is null);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id and deleted_at is null)
  with check (auth.uid() = id);

-- Users cannot escalate platform_role via client updates.
create or replace function public.prevent_platform_role_escalation()
returns trigger
language plpgsql
as $$
begin
  if new.platform_role is distinct from old.platform_role then
    raise exception 'platform_role cannot be changed by clients';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_escalation on public.profiles;
create trigger profiles_prevent_role_escalation
  before update on public.profiles
  for each row execute function public.prevent_platform_role_escalation();
