-- Phase 11: customer ↔ driver ratings

create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips (id),
  from_user_id uuid not null references public.profiles (id),
  to_user_id uuid not null references public.profiles (id),
  overall smallint not null check (overall between 1 and 5),
  dimensions jsonb not null default '{}'::jsonb,
  comment text,
  created_at timestamptz not null default now(),
  unique (trip_id, from_user_id),
  constraint ratings_no_self check (from_user_id <> to_user_id)
);

create index if not exists ratings_to_user_idx on public.ratings (to_user_id);
create index if not exists ratings_trip_idx on public.ratings (trip_id);

alter table public.ratings enable row level security;

drop policy if exists "ratings_select_participants" on public.ratings;
create policy "ratings_select_participants"
  on public.ratings for select
  to authenticated
  using (
    from_user_id = auth.uid()
    or to_user_id = auth.uid()
    or public.can_access_trip(trip_id)
  );

create or replace function public.submit_rating(
  p_trip_id uuid,
  p_overall smallint,
  p_dimensions jsonb default '{}'::jsonb,
  p_comment text default null
)
returns public.ratings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_trip public.trips;
  v_to uuid;
  v_row public.ratings;
  v_avg numeric;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_overall is null or p_overall < 1 or p_overall > 5 then
    raise exception 'invalid_overall';
  end if;

  select * into v_trip
  from public.trips
  where id = p_trip_id and deleted_at is null;

  if not found then
    raise exception 'trip_not_found';
  end if;

  if v_trip.status not in ('delivered', 'completed') then
    raise exception 'trip_not_rateable';
  end if;

  if v_uid = v_trip.customer_id then
    v_to := v_trip.driver_id;
  elsif v_uid = v_trip.driver_id then
    v_to := v_trip.customer_id;
  else
    raise exception 'not_allowed';
  end if;

  insert into public.ratings (
    trip_id, from_user_id, to_user_id, overall, dimensions, comment
  ) values (
    p_trip_id,
    v_uid,
    v_to,
    p_overall,
    coalesce(p_dimensions, '{}'::jsonb),
    nullif(trim(coalesce(p_comment, '')), '')
  )
  on conflict (trip_id, from_user_id) do update set
    overall = excluded.overall,
    dimensions = excluded.dimensions,
    comment = excluded.comment
  returning * into v_row;

  -- Refresh driver average when the rated party is the driver
  if v_to = v_trip.driver_id then
    select round(avg(overall)::numeric, 2) into v_avg
    from public.ratings
    where to_user_id = v_to;

    update public.driver_profiles
    set rating_avg = coalesce(v_avg, 0)
    where user_id = v_to
      and deleted_at is null;
  end if;

  perform public.create_notification(
    v_to,
    'rating_received',
    'Nueva calificación',
    'Recibiste ' || p_overall::text || ' estrellas en un viaje.',
    jsonb_build_object(
      'trip_id', p_trip_id,
      'rating_id', v_row.id,
      'overall', p_overall
    )
  );

  return v_row;
end;
$$;

revoke all on function public.submit_rating(uuid, smallint, jsonb, text) from public;
grant execute on function public.submit_rating(uuid, smallint, jsonb, text) to authenticated;
