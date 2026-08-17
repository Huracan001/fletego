-- Phase 9: trip chat + in-app notifications (+ push architecture hooks)

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id),
  sender_id uuid not null references public.profiles (id),
  body text not null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint messages_body_not_blank check (length(trim(body)) > 0)
);

create index if not exists messages_trip_created_idx
  on public.messages (trip_id, created_at asc);

create table if not exists public.message_attachments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages (id) on delete cascade,
  storage_path text not null,
  mime_type text,
  file_name text,
  created_at timestamptz not null default now()
);

create index if not exists message_attachments_message_idx
  on public.message_attachments (message_id);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  type text not null,
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id)
  where read_at is null;

-- Device tokens for future FCM/APNs (architecture ready)
create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id),
  token text not null,
  platform text not null default 'unknown',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

drop trigger if exists push_tokens_set_updated_at on public.push_tokens;
create trigger push_tokens_set_updated_at
  before update on public.push_tokens
  for each row execute function public.set_updated_at();

alter table public.messages enable row level security;
alter table public.message_attachments enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;

drop policy if exists "messages_select_participants" on public.messages;
create policy "messages_select_participants"
  on public.messages for select
  to authenticated
  using (
    deleted_at is null
    and public.can_access_trip(trip_id)
  );

drop policy if exists "message_attachments_select_participants" on public.message_attachments;
create policy "message_attachments_select_participants"
  on public.message_attachments for select
  to authenticated
  using (
    exists (
      select 1 from public.messages m
      where m.id = message_id
        and m.deleted_at is null
        and public.can_access_trip(m.trip_id)
    )
  );

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "push_tokens_select_own" on public.push_tokens;
create policy "push_tokens_select_own"
  on public.push_tokens for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "push_tokens_insert_own" on public.push_tokens;
create policy "push_tokens_insert_own"
  on public.push_tokens for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "push_tokens_delete_own" on public.push_tokens;
create policy "push_tokens_delete_own"
  on public.push_tokens for delete
  to authenticated
  using (user_id = auth.uid());

create or replace function public.create_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text default null,
  p_data jsonb default '{}'::jsonb
)
returns public.notifications
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.notifications;
begin
  insert into public.notifications (user_id, type, title, body, data)
  values (p_user_id, p_type, p_title, p_body, coalesce(p_data, '{}'::jsonb))
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.create_notification(uuid, text, text, text, jsonb) from public;
-- Internal helper for other SECURITY DEFINER functions only (not client-callable)
revoke execute on function public.create_notification(uuid, text, text, text, jsonb) from authenticated, anon;

create or replace function public.send_trip_message(
  p_trip_id uuid,
  p_body text
)
returns public.messages
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
  v_msg public.messages;
  v_peer uuid;
  v_preview text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_body is null or length(trim(p_body)) = 0 then
    raise exception 'empty_body';
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

  insert into public.messages (trip_id, sender_id, body)
  values (p_trip_id, v_uid, trim(p_body))
  returning * into v_msg;

  v_peer := case
    when v_trip.customer_id = v_uid then v_trip.driver_id
    else v_trip.customer_id
  end;

  v_preview := left(trim(p_body), 120);

  perform public.create_notification(
    v_peer,
    'chat_message',
    'Nuevo mensaje',
    v_preview,
    jsonb_build_object(
      'trip_id', p_trip_id,
      'message_id', v_msg.id
    )
  );

  return v_msg;
end;
$$;

revoke all on function public.send_trip_message(uuid, text) from public;
grant execute on function public.send_trip_message(uuid, text) to authenticated;

create or replace function public.mark_notification_read(p_notification_id uuid)
returns public.notifications
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.notifications;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  update public.notifications
  set read_at = coalesce(read_at, now())
  where id = p_notification_id
    and user_id = auth.uid()
  returning * into v_row;

  if not found then
    raise exception 'not_found';
  end if;

  return v_row;
end;
$$;

revoke all on function public.mark_notification_read(uuid) from public;
grant execute on function public.mark_notification_read(uuid) to authenticated;

create or replace function public.mark_all_notifications_read()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  update public.notifications
  set read_at = now()
  where user_id = auth.uid()
    and read_at is null;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.mark_all_notifications_read() from public;
grant execute on function public.mark_all_notifications_read() to authenticated;
