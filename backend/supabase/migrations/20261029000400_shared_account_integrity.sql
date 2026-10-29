-- Shared account normalization. Apply after migrations 001 through 003.
-- No operational/user/report records are deleted. A populated unused camera
-- inventory stops this transaction so its data can be reviewed separately.
begin;
do $$ begin
 if exists (select 1 from public.cctv_cameras) then
  raise exception 'Camera inventory is populated; review/export it before removing this unused table';
 end if;
end $$;
-- Neither the admin CCTV empty-state UI nor mobile reads this inventory.
-- No CASCADE: unknown external dependencies must stop the migration.
drop table public.cctv_cameras;

-- A single profile is the shared application identity for an Auth account.
-- Admin capabilities are a separate one-to-one relationship, never a second user.
alter table public.admin_memberships drop constraint admin_memberships_user_id_fkey;
alter table public.admin_memberships add constraint admin_memberships_user_id_fkey
 foreign key(user_id) references public.profiles(id);
alter table public.flood_reports drop constraint flood_reports_owner_id_fkey;
alter table public.flood_reports add constraint flood_reports_owner_id_fkey
 foreign key(owner_id) references public.profiles(id);
alter table public.saved_locations drop constraint saved_locations_owner_id_fkey;
alter table public.saved_locations add constraint saved_locations_owner_id_fkey
 foreign key(owner_id) references public.profiles(id);
alter table public.notification_preferences drop constraint notification_preferences_owner_id_fkey;
alter table public.notification_preferences add constraint notification_preferences_owner_id_fkey
 foreign key(owner_id) references public.profiles(id);

-- A regular mobile account may only report a road visible in its directory.
drop policy report_submit on public.flood_reports;
create policy report_submit on public.flood_reports for insert to authenticated
with check(owner_id=auth.uid() and public.active_mobile_user() and status='pending'
 and reviewed_by is null and reviewed_at is null and review_reason is null
 and exists(select 1 from public.road_locations r where r.id=road_id and r.published));
commit;
