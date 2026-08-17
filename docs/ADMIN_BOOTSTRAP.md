# Promote first platform admin (SQL Editor)

After Phase 14, this works directly (postgres bypass):

```sql
update public.profiles
set platform_role = 'super_admin'
where email = 'you@example.com';
```

If an older DB still blocks the update:

```sql
alter table public.profiles disable trigger profiles_prevent_role_escalation;
update public.profiles set platform_role = 'super_admin' where email = 'you@example.com';
alter table public.profiles enable trigger profiles_prevent_role_escalation;
```
