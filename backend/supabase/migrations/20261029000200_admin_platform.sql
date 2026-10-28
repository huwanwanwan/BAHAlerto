-- BAHAlerto versioned migration. Review the target schema before deployment.
begin;
create table public.profiles (
 id uuid primary key references auth.users(id),
 full_name text not null check(length(trim(full_name)) between 1 and 200),
 phone text, preferred_area text,
 status text not null default 'active' check(status in ('active','suspended')),
 created_at timestamptz not null default now()
);
create table public.admin_memberships (
 user_id uuid primary key references auth.users(id),
 permissions text[] not null default '{}' check(permissions <@ array['dashboard','reports','observations','roads','alerts','users','emergency','analytics','audit','account']::text[]),
 active boolean not null default false,
 created_at timestamptz not null default now()
);
create function public.has_admin_permission(capability text) returns boolean
language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.admin_memberships a join public.profiles p on p.id=a.user_id
 where a.user_id=auth.uid() and a.active and p.status='active' and capability=any(a.permissions));
$$;
revoke all on function public.has_admin_permission(text) from public;
grant execute on function public.has_admin_permission(text) to anon,authenticated;
create function public.active_mobile_user() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=auth.uid() and status='active');
$$;
revoke all on function public.active_mobile_user() from public;
grant execute on function public.active_mobile_user() to authenticated;
create function public.create_mobile_profile() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,full_name) values(new.id,left(coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),'User'),200));
 return new;
end $$;
create trigger create_mobile_profile after insert on auth.users for each row execute function public.create_mobile_profile();
-- Existing auth users require an explicit reviewed profile backfill, not an automatic rewrite.
create table public.flood_reports (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null default auth.uid() references auth.users(id),
 road_id uuid not null references public.road_locations(id),
 latitude double precision not null check(latitude between -90 and 90),
 longitude double precision not null check(longitude between -180 and 180),
 depth_cm numeric not null check(depth_cm between 0 and 10000),
 description text not null check(length(trim(description)) between 10 and 4000),
 photo_path text,
 observed_at timestamptz not null check(observed_at <= now()),
 status text not null default 'pending' check(status in ('pending','verified','rejected','clarification')),
 review_reason text, reviewed_by uuid references auth.users(id), reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 check(photo_path is null or split_part(photo_path,'/',1)=owner_id::text)
);
create index flood_reports_owner on public.flood_reports(owner_id,created_at desc);
create index flood_reports_status on public.flood_reports(status,created_at desc);
alter table public.flood_observations add column archived boolean not null default false;
alter table public.flood_observations add column notes text;
alter table public.flood_observations add column measurement_kind text not null default 'unknown' check(measurement_kind in ('community_estimate','instrument','official_observation','unknown'));
alter table public.flood_observations add column supporting_report_id uuid references public.flood_reports(id);
create table public.flood_alerts (
 id uuid primary key default gen_random_uuid(),
 road_id uuid not null references public.road_locations(id),
 title text not null check(length(trim(title)) between 1 and 200),
 message text not null check(length(trim(message)) between 1 and 4000),
 severity text not null check(severity in ('information','caution','danger')),
 source text not null check(length(trim(source)) between 1 and 4000),
 status text not null default 'draft' check(status in ('draft','published','expired')),
 published_at timestamptz, expires_at timestamptz not null,
 created_at timestamptz not null default now(),created_by uuid references auth.users(id)
);
create table public.emergency_contacts (
 id uuid primary key default gen_random_uuid(), organization text not null check(length(trim(organization))>0),
 phone text not null check(length(trim(phone))>0),service_area text not null,details text,
 published boolean not null default false,archived boolean not null default false,
 created_at timestamptz not null default now(),created_by uuid references auth.users(id)
);
create table public.evacuation_centers (
 id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name))>0),
 address text not null,latitude double precision not null check(latitude between -90 and 90),
 longitude double precision not null check(longitude between -180 and 180),contact text,
 operational_details text not null,verified_at timestamptz not null check(verified_at<=now()),
 published boolean not null default false,archived boolean not null default false,
 created_at timestamptz not null default now(),created_by uuid references auth.users(id)
);
create table public.saved_locations (
 id uuid primary key default gen_random_uuid(),owner_id uuid not null default auth.uid() references auth.users(id),
 road_id uuid not null references public.road_locations(id),notify boolean not null default false,
 created_at timestamptz not null default now(),unique(owner_id,road_id)
);
create table public.audit_logs (
 id uuid primary key default gen_random_uuid(),actor_id uuid references auth.users(id),
 action text not null,table_name text not null,record_id uuid not null,
 details jsonb not null default '{}',occurred_at timestamptz not null default now()
);
create index audit_logs_time on public.audit_logs(occurred_at desc);
-- Audit only changed field names/status metadata, never passwords or authentication tokens.
create function public.audit_admin_change() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.audit_logs(actor_id,action,table_name,record_id,details)
 values(auth.uid(),tg_op,tg_table_name,(to_jsonb(new)->>'id')::uuid,
 jsonb_build_object('status',to_jsonb(new)->>'status','published',to_jsonb(new)->>'published','review_reason',to_jsonb(new)->>'review_reason'));
 return new;
end $$;
create trigger report_audit after update on public.flood_reports for each row execute function public.audit_admin_change();
create trigger observation_audit after insert or update on public.flood_observations for each row execute function public.audit_admin_change();
create trigger road_audit after insert or update on public.road_locations for each row execute function public.audit_admin_change();
create trigger alert_audit after insert or update on public.flood_alerts for each row execute function public.audit_admin_change();
create trigger contact_audit after insert or update on public.emergency_contacts for each row execute function public.audit_admin_change();
create trigger center_audit after insert or update on public.evacuation_centers for each row execute function public.audit_admin_change();
create trigger profile_audit after update on public.profiles for each row execute function public.audit_admin_change();
-- Session ownership can read membership; only trusted database owner manages membership.
alter table public.profiles enable row level security;
alter table public.admin_memberships enable row level security;
alter table public.flood_reports enable row level security;
alter table public.flood_alerts enable row level security;
alter table public.emergency_contacts enable row level security;
alter table public.evacuation_centers enable row level security;
alter table public.saved_locations enable row level security;
alter table public.audit_logs enable row level security;
revoke all on public.profiles,public.admin_memberships,public.flood_reports,public.flood_alerts,public.emergency_contacts,public.evacuation_centers,public.saved_locations,public.audit_logs from anon,authenticated;
grant select on public.profiles,public.admin_memberships,public.flood_reports,public.audit_logs to authenticated;
grant select on public.flood_alerts,public.emergency_contacts,public.evacuation_centers to anon,authenticated;
grant insert(owner_id,road_id,latitude,longitude,depth_cm,description,photo_path,observed_at) on public.flood_reports to authenticated;
grant select,insert,delete on public.saved_locations to authenticated;
grant update(notify) on public.saved_locations to authenticated;
grant update(full_name,phone,preferred_area) on public.profiles to authenticated;
create policy own_membership on public.admin_memberships for select to authenticated using(user_id=auth.uid());
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.has_admin_permission('users') or public.has_admin_permission('dashboard'));
create policy profile_edit on public.profiles for update to authenticated using(id=auth.uid() and public.active_mobile_user()) with check(id=auth.uid());
create policy report_read on public.flood_reports for select to authenticated using(owner_id=auth.uid() or public.has_admin_permission('reports') or public.has_admin_permission('dashboard') or public.has_admin_permission('analytics') or public.has_admin_permission('users'));
create policy report_submit on public.flood_reports for insert to authenticated with check(owner_id=auth.uid() and public.active_mobile_user() and status='pending' and reviewed_by is null and reviewed_at is null);
create policy saved_owner on public.saved_locations for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid() and public.active_mobile_user());
create policy audit_read on public.audit_logs for select to authenticated using(public.has_admin_permission('audit'));
create policy admin_roads on public.road_locations for select to authenticated using(public.has_admin_permission('roads') or public.has_admin_permission('observations') or public.has_admin_permission('reports'));
create policy admin_observations on public.flood_observations for select to authenticated using(public.has_admin_permission('observations') or public.has_admin_permission('dashboard') or public.has_admin_permission('analytics'));
drop policy published_verified_observations on public.flood_observations;
create policy published_verified_observations on public.flood_observations for select to anon,authenticated using(published and not archived and verification_status='verified' and exists(select 1 from public.road_locations r where r.id=road_id and r.published));
create policy alert_read on public.flood_alerts for select to anon,authenticated using((status='published' and published_at<=now() and expires_at>now()) or public.has_admin_permission('alerts') or public.has_admin_permission('dashboard'));
create policy contact_read on public.emergency_contacts for select to anon,authenticated using((published and not archived) or public.has_admin_permission('emergency'));
create policy center_read on public.evacuation_centers for select to anon,authenticated using((published and not archived) or public.has_admin_permission('emergency'));
create function public.review_flood_report(report_id uuid,decision text,reason text) returns void
language plpgsql security definer set search_path='' as $$
declare current_status text;
begin
 if not public.has_admin_permission('reports') then raise exception 'Not authorized'; end if;
 if decision is null or reason is null or decision not in ('verified','rejected','clarification') or length(trim(reason))<5 or length(reason)>2000 then raise exception 'Invalid review'; end if;
 select status into current_status from public.flood_reports where id=report_id for update;
 if current_status is null or current_status not in ('pending','clarification') then raise exception 'Already reviewed or missing'; end if;
 if current_status='clarification' and decision='clarification' then raise exception 'Clarification already requested'; end if;
 update public.flood_reports set status=decision,review_reason=reason,reviewed_by=auth.uid(),reviewed_at=now() where id=report_id;
end $$;
revoke all on function public.review_flood_report(uuid,text,text) from public;
grant execute on function public.review_flood_report(uuid,text,text) to authenticated;

create function public.admin_save_record(kind text,payload jsonb) returns uuid
language plpgsql security definer set search_path='' as $$
declare
 record_id uuid := coalesce(nullif(payload->>'id','')::uuid,gen_random_uuid());
 permission text;
 existing boolean;
begin
 permission:=case kind when 'road' then 'roads' when 'observation' then 'observations' when 'alert' then 'alerts' when 'contact' then 'emergency' when 'center' then 'emergency' when 'user' then 'users' else null end;
 if permission is null or not public.has_admin_permission(permission) then raise exception 'Not authorized'; end if;
 if kind='road' then
  insert into public.road_locations(id,name,locality,latitude,longitude,published,created_by)
  values(record_id,payload->>'name',payload->>'locality',(payload->>'latitude')::double precision,(payload->>'longitude')::double precision,(payload->>'published')::boolean,auth.uid())
  on conflict(id) do update set name=excluded.name,locality=excluded.locality,latitude=excluded.latitude,longitude=excluded.longitude,published=excluded.published;
 elsif kind='observation' then
  if (payload->>'observed_at')::timestamptz>now() then raise exception 'Future observation'; end if;
  if nullif(payload->>'supporting_report_id','') is not null and not exists(select 1 from public.flood_reports where id=(payload->>'supporting_report_id')::uuid and status='verified' and road_id=(payload->>'road_id')::uuid) then raise exception 'Supporting report must be verified for the same road'; end if;
  if nullif(payload->>'supporting_report_id','') is not null and payload->>'measurement_kind'<>'community_estimate' then raise exception 'Report estimates must remain estimates'; end if;
  insert into public.flood_observations(id,measurement_kind,supporting_report_id,road_id,depth_cm,source,evidence,verification_status,observed_at,valid_until,published,archived,notes,created_by,reviewed_by,reviewed_at)
  values(record_id,payload->>'measurement_kind',nullif(payload->>'supporting_report_id','')::uuid,(payload->>'road_id')::uuid,(payload->>'depth_cm')::numeric,payload->>'source','observation','verified',(payload->>'observed_at')::timestamptz,(payload->>'valid_until')::timestamptz,(payload->>'published')::boolean,(payload->>'archived')::boolean,payload->>'notes',auth.uid(),auth.uid(),now())
  on conflict(id) do update set measurement_kind=excluded.measurement_kind,supporting_report_id=excluded.supporting_report_id,road_id=excluded.road_id,depth_cm=excluded.depth_cm,source=excluded.source,evidence=excluded.evidence,verification_status=excluded.verification_status,observed_at=excluded.observed_at,valid_until=excluded.valid_until,published=excluded.published,archived=excluded.archived,notes=excluded.notes,reviewed_by=auth.uid(),reviewed_at=now();
 elsif kind='alert' then
  if payload->>'status' not in ('draft','published','expired') then raise exception 'Invalid advisory status'; end if;
  if payload->>'status'='published' and (payload->>'expires_at')::timestamptz<=now() then raise exception 'Expired publication'; end if;
  insert into public.flood_alerts(id,road_id,title,message,severity,source,status,published_at,expires_at,created_by)
  values(record_id,(payload->>'road_id')::uuid,payload->>'title',payload->>'message',payload->>'severity',payload->>'source',payload->>'status',case when payload->>'status'='published' then now() end,(payload->>'expires_at')::timestamptz,auth.uid())
  on conflict(id) do update set road_id=excluded.road_id,title=excluded.title,message=excluded.message,severity=excluded.severity,source=excluded.source,status=excluded.status,published_at=case when excluded.status='published' then coalesce(public.flood_alerts.published_at,now()) else public.flood_alerts.published_at end,expires_at=excluded.expires_at;
 elsif kind='contact' then
  insert into public.emergency_contacts(id,organization,phone,service_area,details,published,archived,created_by)
  values(record_id,payload->>'organization',payload->>'phone',payload->>'service_area',payload->>'details',(payload->>'published')::boolean,(payload->>'archived')::boolean,auth.uid())
  on conflict(id) do update set organization=excluded.organization,phone=excluded.phone,service_area=excluded.service_area,details=excluded.details,published=excluded.published,archived=excluded.archived;
 elsif kind='center' then
  insert into public.evacuation_centers(id,name,address,latitude,longitude,contact,operational_details,verified_at,published,archived,created_by)
  values(record_id,payload->>'name',payload->>'address',(payload->>'latitude')::double precision,(payload->>'longitude')::double precision,payload->>'contact',payload->>'operational_details',(payload->>'verified_at')::timestamptz,(payload->>'published')::boolean,(payload->>'archived')::boolean,auth.uid())
  on conflict(id) do update set name=excluded.name,address=excluded.address,latitude=excluded.latitude,longitude=excluded.longitude,contact=excluded.contact,operational_details=excluded.operational_details,verified_at=excluded.verified_at,published=excluded.published,archived=excluded.archived;
 elsif kind='user' then
  if payload->>'reason' is null or length(trim(payload->>'reason'))<5 or payload->>'status' not in ('active','suspended') then raise exception 'Reason and valid status required'; end if;
  if record_id=auth.uid() then raise exception 'Cannot change own account status'; end if;
  update public.profiles set status=payload->>'status' where id=record_id;
  if not found then raise exception 'User not found'; end if;
  insert into public.audit_logs(actor_id,action,table_name,record_id,details) values(auth.uid(),'ACCOUNT_STATUS','profiles',record_id,jsonb_build_object('reason',payload->>'reason','status',payload->>'status'));
 end if;
 return record_id;
end $$;
revoke all on function public.admin_save_record(text,jsonb) from public;
grant execute on function public.admin_save_record(text,jsonb) to authenticated;
-- Private photos: owner-scoped uploads, owner or authorized report reviewer reads.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('flood-photos','flood-photos',false,10485760,array['image/jpeg','image/png','image/webp']);
create policy flood_photo_upload on storage.objects for insert to authenticated
with check(bucket_id='flood-photos' and (storage.foldername(name))[1]=auth.uid()::text and public.active_mobile_user());
create policy flood_photo_read on storage.objects for select to authenticated
using(bucket_id='flood-photos' and ((storage.foldername(name))[1]=auth.uid()::text or public.has_admin_permission('reports')));
-- No client object update/delete policies; retention is a trusted maintenance task.
-- Optional PostGIS extension/geometry migration is separate: existing decimal
-- coordinates work without requiring PostGIS or changing extension schemas.
-- Bootstrap memberships only through trusted SQL after creating an Auth user.
-- Grant a reviewed subset of capabilities, not all permissions by default.
commit;
