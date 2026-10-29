-- Read-only checks; safe to run after deploying the schema.
select tablename,rowsecurity from pg_tables where schemaname='public'
 and tablename in ('profiles','admin_memberships','road_locations','flood_observations','flood_reports','flood_alerts','emergency_contacts','evacuation_centers','saved_locations','notification_preferences','audit_logs','admin_notifications') order by tablename;
select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='flood-photos';
select schemaname,tablename,policyname,roles,cmd from pg_policies where schemaname='public' order by tablename,policyname;

-- Migration 005: trusted Auth sign-in mirror and notification trigger installation.
select column_name from information_schema.columns where table_schema='public'
 and table_name='profiles' and column_name='last_sign_in_at';
select event_object_schema,event_object_table,trigger_name from information_schema.triggers
 where trigger_name in ('notify_account_created','notify_account_login','notify_report_submitted');
