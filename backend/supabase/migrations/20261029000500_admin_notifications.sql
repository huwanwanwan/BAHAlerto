-- Apply after 001-004. No accounts, reports or admin permissions are removed.
begin;
alter table public.profiles add column last_sign_in_at timestamptz;
update public.profiles p set last_sign_in_at=u.last_sign_in_at from auth.users u where u.id=p.id;

create table public.admin_notifications (
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references public.profiles(id),
 actor_id uuid not null references public.profiles(id),
 kind text not null check(kind in ('account_registered','account_login','report_submitted')),
 record_id uuid not null,
 title text not null,
 created_at timestamptz not null default now(),
 read_at timestamptz
);
create index admin_notifications_recipient_time on public.admin_notifications(recipient_id,created_at desc);
create index admin_notifications_unread on public.admin_notifications(recipient_id) where read_at is null;
alter table public.admin_notifications enable row level security;
revoke all on public.admin_notifications from anon,authenticated;
grant select on public.admin_notifications to authenticated;
grant update(read_at) on public.admin_notifications to authenticated;
create policy admin_notification_read on public.admin_notifications for select to authenticated using(
 recipient_id=auth.uid() and (
 public.has_admin_permission('dashboard') or
 (kind in ('account_registered','account_login') and public.has_admin_permission('users')) or
 (kind='report_submitted' and public.has_admin_permission('reports'))
 ));
create policy admin_notification_mark_read on public.admin_notifications for update to authenticated
using(recipient_id=auth.uid() and (public.has_admin_permission('dashboard') or
 (kind in ('account_registered','account_login') and public.has_admin_permission('users')) or
 (kind='report_submitted' and public.has_admin_permission('reports'))))
with check(recipient_id=auth.uid());

-- Trusted triggers are the only writers. Clients cannot forge login events.
create function public.notify_admin_activity() returns trigger
language plpgsql security definer set search_path='' as $$
declare actor uuid; event_kind text; event_record uuid; actor_name text; required_permission text; event_title text;
begin
 if tg_table_schema='auth' then
  actor:=new.id; event_record:=new.id; required_permission:='users';
  if tg_op='INSERT' then
   event_kind:='account_registered';
  else
   if new.last_sign_in_at is null or new.last_sign_in_at is not distinct from old.last_sign_in_at then return new; end if;
   event_kind:='account_login';
  end if;
  update public.profiles set last_sign_in_at=new.last_sign_in_at where id=actor;
 else
  actor:=new.owner_id; event_record:=new.id; required_permission:='reports'; event_kind:='report_submitted';
 end if;
 select full_name into actor_name from public.profiles where id=actor;
 event_title:=coalesce(actor_name,'A user') || case event_kind
  when 'account_registered' then ' created an account'
  when 'account_login' then ' signed in'
  else ' submitted a flood report' end;
 insert into public.admin_notifications(recipient_id,actor_id,kind,record_id,title)
 select a.user_id,actor,event_kind,event_record,event_title
 from public.admin_memberships a join public.profiles p on p.id=a.user_id
 where a.active and p.status='active' and a.user_id<>actor
 and (required_permission=any(a.permissions) or 'dashboard'=any(a.permissions));
 return new;
end $$;
revoke all on function public.notify_admin_activity() from public;
-- Alphabetical order makes create_mobile_profile run before notify_account_created.
create trigger notify_account_created after insert on auth.users for each row execute function public.notify_admin_activity();
create trigger notify_account_login after update of last_sign_in_at on auth.users for each row execute function public.notify_admin_activity();
create trigger notify_report_submitted after insert on public.flood_reports for each row execute function public.notify_admin_activity();
commit;
