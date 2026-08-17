-- Repair: create missing trips for already-accepted offers (safe to re-run)

insert into public.trips (
  request_id,
  offer_id,
  customer_id,
  driver_id,
  vehicle_id,
  company_id,
  status,
  assigned_at
)
select
  o.request_id,
  o.id,
  r.customer_id,
  coalesce(dp.user_id, o.transporter_profile_id),
  o.vehicle_id,
  o.company_id,
  'assigned'::public.trip_status,
  coalesce(o.updated_at, o.created_at, now())
from public.offers o
join public.cargo_requests r on r.id = o.request_id
left join public.driver_profiles dp on dp.id = o.driver_profile_id
where o.status = 'accepted'
  and o.deleted_at is null
  and r.deleted_at is null
  and not exists (
    select 1 from public.trips t
    where t.offer_id = o.id and t.deleted_at is null
  );

-- Keep request status aligned
update public.cargo_requests r
set status = 'assigned'
where r.deleted_at is null
  and exists (
    select 1 from public.offers o
    where o.request_id = r.id
      and o.status = 'accepted'
      and o.deleted_at is null
  )
  and r.status in ('matching', 'offered');
