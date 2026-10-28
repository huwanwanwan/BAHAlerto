-- Read-only checks; safe to run after deploying the schema.
select tablename,rowsecurity from pg_tables where schemaname='public'
 and tablename in ('profiles','admin_memberships','road_locations','flood_observations','flood_reports','flood_alerts','emergency_contacts','evacuation_centers','saved_locations','notification_preferences','cctv_cameras','audit_logs') order by tablename;
select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='flood-photos';
select schemaname,tablename,policyname,roles,cmd from pg_policies where schemaname='public' order by tablename,policyname;
