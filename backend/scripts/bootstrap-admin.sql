-- Run only in trusted Supabase SQL Editor after creating your Auth account.
-- Prepared for the BAHAlerto administrator UID provided by the project owner.
-- Grants access to all currently implemented management modules.
-- Passwords must be set in Supabase Auth, never in this SQL or a custom table.
begin;
do $$
declare
 target_user uuid := '2914a770-c258-4f9e-88eb-e7d15f7dd4cc';
 assigned_permissions text[] := array[
  'dashboard','reports','observations','roads','alerts',
  'users','emergency','analytics','audit','account'
 ];
begin
 if target_user is null then raise exception 'Set target_user to your Auth user UUID first'; end if;
 if not exists(select 1 from auth.users where id=target_user) then raise exception 'Create the Auth user first'; end if;
 insert into public.admin_memberships(user_id,active,permissions) values(target_user,true,assigned_permissions);
 insert into public.audit_logs(actor_id,action,table_name,record_id,details)
 values(null,'ADMIN_BOOTSTRAP','admin_memberships',target_user,jsonb_build_object('permissions',assigned_permissions,'method','trusted SQL editor'));
end $$;
commit;
-- Available permissions: dashboard, reports, observations, roads, alerts,
-- users, emergency, analytics, audit, account. Grant only the capabilities needed.
