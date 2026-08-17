-- Sync completed_trips for drivers who already finished trips
update public.driver_profiles dp
set completed_trips = sub.cnt
from (
  select t.driver_id, count(*)::int as cnt
  from public.trips t
  where t.status = 'completed'
    and t.deleted_at is null
  group by t.driver_id
) sub
where dp.user_id = sub.driver_id
  and dp.deleted_at is null;
