import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { PGlite } from "@electric-sql/pglite";
test("database migrations enforce role, review, publication and audit rules", async () => {
  const db = new PGlite();
  try {
    await db.exec(`create role anon;create role authenticated;create schema auth;create schema storage;
 create table auth.users(id uuid primary key,raw_user_meta_data jsonb default '{}',last_sign_in_at timestamptz);
 create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
 grant usage on schema auth,public,storage to anon,authenticated;
 grant execute on function auth.uid() to anon,authenticated;
 create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
 create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
 alter table storage.objects enable row level security;
 grant select,insert on storage.objects to authenticated;
 create function storage.foldername(text) returns text[] language sql immutable as $$select string_to_array($1,'/')$$;`);
    for (const file of readdirSync("../backend/supabase/migrations").filter(name => name.endsWith(".sql")).sort()) {
      await db.exec(readFileSync(`../backend/supabase/migrations/${file}`,"utf8"));
    }
    const admin = "10000000-0000-4000-8000-000000000001",
      user = "10000000-0000-4000-8000-000000000002",
      other = "10000000-0000-4000-8000-000000000003",
      road = "20000000-0000-4000-8000-000000000001";
    await db.exec(`insert into auth.users(id) values('${admin}'),('${user}'),('${other}');
 insert into public.admin_memberships(user_id,active,permissions) values('${admin}',true,array['reports','observations','roads','audit','users','dashboard','alerts','emergency']);
 insert into public.road_locations(id,name,latitude,longitude,published) values('${road}','Test road',14,120,true);`);
    async function as(role: string, id: string) {
      await db.exec(
        `reset role;set role ${role};select set_config('request.jwt.claim.sub','${id}',false);`,
      );
    }
    // Signup and login events originate in Auth, not a mobile write request.
    const signup = '10000000-0000-4000-8000-000000000004';
    await db.exec(`insert into auth.users(id,raw_user_meta_data) values('${signup}','{"full_name":"Mobile signup"}');
      update auth.users set last_sign_in_at=now() where id='${user}';`);
    assert.equal((await db.query(`select id from public.profiles where id='${signup}'`)).rows.length, 1);
    assert.equal((await db.query<{last_sign_in_at:string|null}>(`select last_sign_in_at from public.profiles where id='${user}'`)).rows[0].last_sign_in_at != null, true);
    await as("authenticated", admin);
    const inbox = await db.query<{id:string;kind:string}>("select id,kind from public.admin_notifications order by created_at");
    assert.equal(inbox.rows.length, 2);
    assert.deepEqual(new Set(inbox.rows.map(row=>row.kind)), new Set(['account_registered','account_login']));
    await db.exec(`update public.admin_notifications set read_at=now() where id='${inbox.rows[0].id}'`);
    assert.equal((await db.query('select id from public.admin_notifications where read_at is null')).rows.length, 1);
    await assert.rejects(db.exec(`update public.admin_notifications set title='forged'`));
    await as("authenticated", user);
    assert.equal((await db.query('select id from public.admin_notifications')).rows.length, 0);
    await assert.rejects(db.exec(`insert into public.admin_notifications(recipient_id,actor_id,kind,record_id,title) values('${admin}','${user}','account_login','${user}','Forged login')`));
    await assert.rejects(db.exec(`update public.profiles set last_sign_in_at=now() where id='${user}'`));
    await db.exec(`reset role; update auth.users set last_sign_in_at=last_sign_in_at where id='${user}';`);
    assert.equal((await db.query(`select id from public.admin_notifications where kind='account_login'`)).rows.length, 1);
    await as("authenticated", user);
    const report = (
      await db.query<{ id: string }>(
        `insert into public.flood_reports(road_id,latitude,longitude,depth_cm,description,observed_at) values('${road}',14,120,45,'Community test observation',now()) returning id`,
      )
    ).rows[0].id;
    await assert.rejects(
      db.exec(
        `select public.review_flood_report('${report}','verified','reviewed by user')`,
      ),
    );
    await assert.rejects(
      db.exec(
        `insert into public.admin_memberships(user_id,active) values('${user}',true)`,
      ),
    );
    await assert.rejects(
      db.exec(
        `update public.flood_reports set status='verified' where id='${report}'`,
      ),
    );
    await db.exec(`insert into public.notification_preferences(language) values('fil')`);
    await as("authenticated", other);
    assert.equal((await db.query('select * from public.notification_preferences')).rows.length,0);
    assert.equal(
      (await db.query(`select * from public.flood_reports`)).rows.length,
      0,
    );
    await as("authenticated", admin);
    assert.equal((await db.query(`select id from public.admin_notifications where kind='report_submitted' and record_id='${report}'`)).rows.length, 1);
    await as("authenticated", admin);
    await assert.rejects(
      db.exec(`select public.review_flood_report('${report}','rejected','')`),
    );
    await assert.rejects(
      db.exec(`select public.review_flood_report('${report}','rejected',null)`),
    );
    await db.exec(
      `select public.review_flood_report('${report}','verified','Evidence reviewed as community estimate')`,
    );
    await assert.rejects(
      db.exec(
        `select public.review_flood_report('${report}','verified','Duplicate approval must fail')`,
      ),
    );
    const payload = {
      kind: "observation",
      road_id: road,
      depth_cm: 45,
      source: "Community test fixture",
      measurement_kind: "community_estimate",
      supporting_report_id: report,
      observed_at: new Date(Date.now() - 60000).toISOString(),
      valid_until: new Date(Date.now() + 3600000).toISOString(),
      published: "true",
      archived: "false",
      notes: "Estimated depth remains estimated",
    };
    await db.query("select public.admin_save_record($1,$2::jsonb)", [
      "observation",
      JSON.stringify(payload),
    ]);
    await assert.rejects(
      db.query("select public.admin_save_record($1,$2::jsonb)", [
        "observation",
        JSON.stringify({ ...payload, measurement_kind: "instrument" }),
      ]),
    );
    const save = async (kind: string, payload: Record<string, unknown>) =>
      (
        await db.query<{ admin_save_record: string }>(
          "select public.admin_save_record($1,$2::jsonb)",
          [kind, JSON.stringify(payload)],
        )
      ).rows[0].admin_save_record;
    const newRoad = await save("road", {
      name: "New supported road",
      locality: "Test area",
      latitude: 14.1,
      longitude: 120.1,
      published: "false",
    });
    await save("road", {
      id: newRoad,
      name: "Updated supported road",
      locality: "Test area",
      latitude: 14.1,
      longitude: 120.1,
      published: "true",
    });
    const alert = await save("alert", {
      road_id: road,
      title: "Test advisory",
      message: "Test only",
      severity: "caution",
      source: "Test authority",
      status: "draft",
      expires_at: new Date(Date.now() + 3600000).toISOString(),
    });
    await save("alert", {
      id: alert,
      road_id: road,
      title: "Test advisory",
      message: "Test only",
      severity: "caution",
      source: "Test authority",
      status: "published",
      expires_at: new Date(Date.now() + 3600000).toISOString(),
    });
    const contact = await save("contact", {
      organization: "Test agency",
      phone: "test-only",
      service_area: "Test area",
      details: "Test fixture",
      published: "false",
      archived: "false",
    });
    await save("contact", {
      id: contact,
      organization: "Test agency",
      phone: "test-only",
      service_area: "Test area",
      details: "Test fixture",
      published: "false",
      archived: "true",
    });
    await save("center", {
      name: "Test facility",
      address: "Test address",
      latitude: 14,
      longitude: 120,
      contact: "Test only",
      operational_details: "Test fixture, no real availability",
      verified_at: new Date(Date.now() - 1000).toISOString(),
      published: "false",
      archived: "false",
    });
    assert.ok(
      (await db.query("select * from public.audit_logs")).rows.length >= 3,
    );
    await assert.rejects(db.exec("delete from public.audit_logs"));
    await as("anon", "");
    assert.equal((await db.query(`select * from public.latest_road_observation('${road}')`)).rows.length,1);
    await assert.rejects(db.exec('select * from public.cctv_cameras'));

    assert.equal(
      (await db.query("select * from public.flood_observations")).rows.length,
      1,
    );
    await assert.rejects(db.exec("select * from public.flood_reports"));
    await assert.rejects(db.exec("select * from public.profiles"));
    await assert.rejects(
      db.exec("update public.flood_observations set depth_cm=0"),
    );
    await as("authenticated", user);
    await assert.rejects(
      db.exec(
        `insert into storage.objects(bucket_id,name) values('flood-photos','${other}/private.jpg')`,
      ),
    );
    await db.exec(
      `insert into storage.objects(bucket_id,name) values('flood-photos','${user}/report.jpg')`,
    );
    await as("authenticated", other);
    assert.equal(
      (await db.query("select * from storage.objects")).rows.length,
      0,
    );
    await as("authenticated", admin);
    await db.query("select public.admin_save_record($1,$2::jsonb)", [
      "user",
      JSON.stringify({
        id: user,
        status: "suspended",
        reason: "Test suspension policy",
      }),
    ]);
    await as("authenticated", user);
    await assert.rejects(
      db.exec(
        `insert into public.flood_reports(road_id,latitude,longitude,depth_cm,description,observed_at) values('${road}',14,120,45,'Suspended submission test',now())`,
      ),
    );
  } finally {
    await db.close();
  }
});

test('single-file database setup creates all tables with RLS and no sample records',async()=>{
 const db=new PGlite();
 try {
  await db.exec(`create role anon;create role authenticated;create schema auth;create schema storage;
   create table auth.users(id uuid primary key,raw_user_meta_data jsonb default '{}',last_sign_in_at timestamptz);
   create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
   grant usage on schema auth,public,storage to anon,authenticated;
   create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
   create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
   alter table storage.objects enable row level security;
   create function storage.foldername(text) returns text[] language sql immutable as $$select string_to_array($1,'/')$$;`);
  await db.exec(readFileSync('../backend/schema.sql','utf8'));
  const tables=await db.query<{tablename:string;rowsecurity:boolean}>("select tablename,rowsecurity from pg_tables where schemaname='public'");
  assert.equal(tables.rows.length,12);
  assert.ok(tables.rows.every(table=>table.rowsecurity));
  for(const table of tables.rows){assert.equal((await db.query<{count:number}>(`select count(*)::int as count from public.${table.tablename}`)).rows[0].count,0);}
  assert.equal((await db.query<{public:boolean}>("select public from storage.buckets where id='flood-photos'")).rows[0].public,false);
 }finally {await db.close();}
});


test('cleanup refuses populated camera inventory without deleting its records', async () => {
 const db = new PGlite();
 try {
  await db.exec(`create role anon;create role authenticated;create schema auth;create schema storage;
   create table auth.users(id uuid primary key,raw_user_meta_data jsonb default '{}',last_sign_in_at timestamptz);
   create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
   grant usage on schema auth,public,storage to anon,authenticated;
   create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
   create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text,name text);
   alter table storage.objects enable row level security;
   create function storage.foldername(text) returns text[] language sql immutable as $$select string_to_array($1,'/')$$;`);
  const files = readdirSync('../backend/supabase/migrations').filter(f => f.endsWith('.sql')).sort();
  for (const file of files.slice(0, 3)) await db.exec(readFileSync(`../backend/supabase/migrations/${file}`, 'utf8'));
  const road = '20000000-0000-4000-8000-000000000099';
  await db.exec(`insert into public.road_locations(id,name,latitude,longitude) values('${road}','Existing road',14,120);
    insert into public.cctv_cameras(road_id,name,source_name) values('${road}','Existing camera','Existing source');`);
  await assert.rejects(db.exec(readFileSync(`../backend/supabase/migrations/${files[3]}`, 'utf8')), /Camera inventory is populated/);
  await db.exec('rollback');
  assert.equal((await db.query<{count:number}>('select count(*)::int as count from public.cctv_cameras')).rows[0].count, 1);
 } finally { await db.close(); }
});
