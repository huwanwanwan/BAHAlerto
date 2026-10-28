-- Additional shared data, integrity, query indexes and safe mobile reads.
begin;
-- Backfill profiles for Auth accounts created before the profile trigger existed.
insert into public.profiles(id,full_name)
select id,left(coalesce(nullif(trim(raw_user_meta_data->>'full_name'),''),'User'),200)
from auth.users on conflict(id) do nothing;

create table public.notification_preferences (
 owner_id uuid primary key default auth.uid() references auth.users(id),
 personalized_alerts boolean not null default false,
 language text not null default 'en' check(language in ('en','fil')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.notification_preferences enable row level security;
revoke all on public.notification_preferences from anon,authenticated;
grant select on public.notification_preferences to authenticated;
grant insert(owner_id,personalized_alerts,language) on public.notification_preferences to authenticated;
grant update(personalized_alerts,language) on public.notification_preferences to authenticated;
create policy preferences_owner on public.notification_preferences for all to authenticated
using(owner_id=auth.uid()) with check(owner_id=auth.uid() and public.active_mobile_user());

-- Camera inventory only. Never store stream credentials or imply that a camera
-- is live without an external provider integration and recent status checks.
create table public.cctv_cameras (
 id uuid primary key default gen_random_uuid(),
 road_id uuid not null references public.road_locations(id),
 name text not null check(length(trim(name)) between 1 and 200),
 source_name text not null check(length(trim(source_name)) between 1 and 200),
 source_reference text,
 status text not null default 'not_configured' check(status in ('not_configured','unknown','online','offline')),
 checked_at timestamptz check(checked_at<=now()),
 archived boolean not null default false,
 created_by uuid references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check(status not in ('online','offline') or checked_at is not null)
);
alter table public.cctv_cameras enable row level security;
revoke all on public.cctv_cameras from anon,authenticated;
grant select on public.cctv_cameras to authenticated;
create policy cameras_admin_read on public.cctv_cameras for select to authenticated
using(public.has_admin_permission('dashboard'));
create trigger camera_audit after insert or update on public.cctv_cameras
for each row execute function public.audit_admin_change();
-- No ordinary-client camera writes or public camera reads.

alter table public.flood_reports add constraint reviewed_report_metadata check (
 (status='pending' and reviewed_by is null and reviewed_at is null and review_reason is null)
 or (status<>'pending' and reviewed_by is not null and reviewed_at is not null
 and review_reason is not null and length(trim(review_reason)) between 5 and 2000)
);
alter table public.flood_alerts add constraint published_advisory_time
check(status<>'published' or (published_at is not null and expires_at>published_at));
alter table public.evacuation_centers add constraint center_required_details
check(length(trim(address))>0 and length(trim(operational_details))>0);
alter table public.emergency_contacts add constraint contact_required_area
check(length(trim(service_area))>0);

create function public.touch_updated_at() returns trigger
language plpgsql set search_path='' as $$ begin new.updated_at:=now(); return new; end $$;
revoke all on function public.touch_updated_at() from public;
do $$ declare target_table text; begin
 foreach target_table in array array['profiles','road_locations','flood_observations','flood_reports','flood_alerts','emergency_contacts','evacuation_centers','saved_locations'] loop
  execute format('alter table public.%I add column updated_at timestamptz not null default now()',target_table);
 end loop;
 foreach target_table in array array['profiles','road_locations','flood_observations','flood_reports','flood_alerts','emergency_contacts','evacuation_centers','saved_locations','notification_preferences','cctv_cameras'] loop
  execute format('create trigger touch_updated_at before update on public.%I for each row execute function public.touch_updated_at()',target_table);
 end loop;
end $$;

create index flood_reports_road on public.flood_reports(road_id,observed_at desc);
create index flood_reports_reviewer on public.flood_reports(reviewed_by);
create index observations_supporting_report on public.flood_observations(supporting_report_id);
create index observations_public_current on public.flood_observations(road_id,observed_at desc)
where published and not archived and verification_status='verified' and evidence='observation';
create index alerts_road_expiration on public.flood_alerts(road_id,expires_at) where status='published';
create index cameras_road on public.cctv_cameras(road_id);
create index bookmarks_road on public.saved_locations(road_id);

-- Caller-scoped query: respects RLS and never substitutes historical/stale data.
create function public.latest_road_observation(selected_road uuid)
returns setof public.flood_observations language sql stable security invoker set search_path='' as $$
 select observation.* from public.flood_observations observation
 join public.road_locations road on road.id=observation.road_id
 where road.id=selected_road and road.published
 and observation.published and not observation.archived
 and observation.verification_status='verified' and observation.evidence='observation'
 and observation.depth_cm is not null and observation.observed_at<=now() and observation.valid_until>now()
 order by observation.observed_at desc,observation.created_at desc limit 1;
$$;
revoke all on function public.latest_road_observation(uuid) from public;
grant execute on function public.latest_road_observation(uuid) to anon,authenticated;
revoke all on function public.create_mobile_profile() from public;
revoke all on function public.audit_admin_change() from public;

-- Prevent client-supplied bookmark identifiers or timestamps.
revoke insert on public.saved_locations from authenticated;
grant insert(owner_id,road_id,notify) on public.saved_locations to authenticated;
commit;
