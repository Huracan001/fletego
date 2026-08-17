-- Fix: unambiguous company member listing (user_id vs invited_by FKs to profiles)
-- Optional RPC used if client prefers; app also uses profiles!user_id embed.

create or replace function public.list_company_members(p_company_id uuid)
returns table (
  id uuid,
  company_id uuid,
  user_id uuid,
  role public.company_role,
  joined_at timestamptz,
  full_name text,
  display_name text,
  email text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not public.is_company_member(p_company_id) then
    raise exception 'not allowed';
  end if;

  return query
  select
    cm.id,
    cm.company_id,
    cm.user_id,
    cm.role,
    cm.joined_at,
    p.full_name,
    p.display_name,
    p.email
  from public.company_members cm
  join public.profiles p on p.id = cm.user_id
  where cm.company_id = p_company_id
    and cm.deleted_at is null
    and p.deleted_at is null
  order by cm.joined_at;
end;
$$;

revoke all on function public.list_company_members(uuid) from public;
grant execute on function public.list_company_members(uuid) to authenticated;
