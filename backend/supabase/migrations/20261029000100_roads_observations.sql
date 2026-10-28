-- BAHAlerto versioned migration. Review the target schema before deployment.
begin;
create table public.road_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  locality text,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  published boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);
create table public.flood_observations (
  id uuid primary key default gen_random_uuid(),
  road_id uuid not null references public.road_locations(id),
  depth_cm numeric check (depth_cm >= 0 and depth_cm <= 10000),
  road_condition text,
  evidence text not null check (evidence in ('observation','historical')),
  verification_status text not null default 'pending'
    check (verification_status in ('pending','verified','rejected')),
  source text not null check (length(trim(source)) > 0),
  observed_at timestamptz not null,
  valid_until timestamptz not null,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id),
  check (valid_until > observed_at),
  check (evidence <> 'historical' or depth_cm is null),
  check (verification_status <> 'verified' or (reviewed_at is not null and reviewed_by is not null))
);
create index flood_observations_road_time on public.flood_observations (road_id, observed_at desc);
alter table public.road_locations enable row level security;
alter table public.flood_observations enable row level security;
revoke all on public.road_locations, public.flood_observations from anon, authenticated;
grant select on public.road_locations, public.flood_observations to anon, authenticated;
create policy published_roads on public.road_locations for select to anon, authenticated using (published);
create policy published_verified_observations on public.flood_observations for select to anon, authenticated
using (published and verification_status = 'verified' and exists (
  select 1 from public.road_locations r where r.id = road_id and r.published
));
-- No client writes: moderation and audit must be implemented through a trusted
-- administrator backend. service_role credentials must remain server-side.
-- Reading stale records is permitted so clients can label them; never use them
-- as current measurements. Query evidence='observation', depth_cm not null,
-- observed_at <= now(), valid_until > now(), order by observed_at desc limit 1.
-- Add append-only audit history and authorized road advisories before production.
commit;
