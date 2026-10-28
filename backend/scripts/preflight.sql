-- Read-only inventory before applying a fresh installation.
select tablename from pg_tables where schemaname='public' order by tablename;
select id,public from storage.buckets where id='flood-photos';
-- If BAHAlerto tables already exist, do not run schema.sql. Reconcile migrations first.
