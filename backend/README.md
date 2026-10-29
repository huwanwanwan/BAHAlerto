> Mobile integration update: see [shared database and migration instructions](SHARED-DATABASE.md).
> The fourth migration normalizes account ownership and removes the unused,
> empty camera inventory. The owner reported applying it on 29 October 2026;
> its cloud constraints have not been independently inspected in this session.
> The older 12-table description below describes migrations 001 through 003.

# BAHAlerto database setup

The deployable PostgreSQL schema is ready in [schema.sql](schema.sql). It is designed for the shared Supabase project used by Next.js and Flutter. **Connection update (29 October 2026):** the owner reported successfully applying the schema and administrator bootstrap in Supabase. The admin website is now configured through ignored `admin/.env.local`. Read-only checks confirmed public table access, reachable Supabase Auth and denial of anonymous private-report reads. Authenticated administrator workflows still require the owner to sign in.

## Create the Supabase database

1. Open your Supabase account and create a project for BAHAlerto, or select your existing project. Keep the database password in your password manager; do not paste it in chat.
2. For an existing project, run the read-only `scripts/preflight.sql` and review its existing schema. `schema.sql` is for a new installation and intentionally fails on conflicting tables rather than replacing them.
3. Open the project's SQL Editor, paste the contents of `backend/schema.sql`, review it and run it once. The bundle runs in one transaction. It creates tables/policies/functions and a private photo bucket; it inserts no flood reports, camera records, emergency hotlines or other demonstration data.
4. Run `scripts/check-installation.sql`. All 12 application tables should have Row Level Security enabled. The `flood-photos` bucket must be private.
5. Copy `admin/.env.example` to `admin/.env.local`, set `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, and the trusted `NEXT_PUBLIC_SITE_URL`. The URL and publishable key come from your project's API settings. Never put a service-role key in client configuration.
6. In Supabase Authentication, create your administrator account with your own email and password. Configure your site URL and recovery redirect `http://localhost:3000/auth/callback` (and the deployed equivalent when applicable).
7. Open `scripts/bootstrap-admin.sql`, replace `target_user := null` with that Auth user's UUID and review the permission list. It starts with only `dashboard` and `account`. Add the capabilities this administrator needs: `reports`, `observations`, `roads`, `alerts`, `users`, `emergency`, `analytics`, `audit`. Run it in the trusted SQL Editor. It deliberately fails rather than silently replacing an existing membership.
8. Restart the admin server and sign in. Test against staging before adding live operational information.

No SQL migration has been applied remotely by Codex. Creating a cloud project may involve account limits or billing choices that must be made in your Supabase account. The existing Flutter app still needs its Supabase Auth/data/storage adapter; creating this schema does not automatically synchronize its demonstration records.

## Tables

| Table | Purpose |
| --- | --- |
| `profiles` | Auth-linked names, optional phone/area, account status |
| `admin_memberships` | Trusted administrator capability assignments |
| `road_locations` | Supported named roads and geographic coordinates |
| `flood_reports` | Owner-scoped submissions and review decisions |
| `flood_observations` | Reviewed depth/evidence/source/observation time and expiry |
| `flood_alerts` | Sourced advisories with publication and expiry |
| `emergency_contacts` | Published and archived emergency directory |
| `evacuation_centers` | Facility details and operational verification time |
| `saved_locations` | Private account bookmarks and location notification choices |
| `notification_preferences` | Private alert opt-in and English/Filipino preference |
| `cctv_cameras` | Administrator-readable camera inventory and checked status metadata |
| `audit_logs` | Administrator action history; no client editing/deletion |

Camera streaming, push notification delivery and geographic map providers are separate integrations. Camera records contain no stream credentials. The current CCTV website screen is not yet wired to this inventory. Coordinates work without requiring PostGIS; add spatial types/indexes when the actual spatial query requirements are known.

## Security and data flow

Mobile registration uses Supabase Auth. A trigger creates profiles; the third migration backfills missing profiles for earlier Auth accounts. Passwords never enter application tables. Registered users can insert their own pending reports and view only their own private reports; they cannot set review fields. Suspension blocks new reports and administrator permissions. Public guests read only authorized published records.

`review_flood_report` checks permissions and locks the report to prevent duplicate final reviews. Audit recording is transactional. Verification does not publish an observation. An administrator separately creates an observation through `admin_save_record`; supporting community estimates retain their evidence method. `latest_road_observation` respects caller RLS and returns only valid, verified, measured current observations for a published road, never historical or expired substitutes. No returned row means no current data, not safe passage.

The private `flood-photos` bucket limits file size to 10 MB and allows JPEG, PNG and WebP. Upload paths must begin with the authenticated owner's UUID. Only the owner or an authorized reviewer can read a photo. Service-role credentials remain outside both apps.

## Files and repeatable verification

- `supabase/migrations/`: canonical ordered migration files.
- `schema.sql`: generated all-in-one fresh-install bundle, suitable for SQL Editor.
- `scripts/build-schema.py`: rebuild the bundle after changing canonical migrations.
- `scripts/bootstrap-admin.sql`: manual trusted role bootstrap; never run from Flutter/browser.
- `scripts/preflight.sql` and `check-installation.sql`: read-only inspection.
- `proposals/`: archived earlier drafts; do not run these alongside the canonical migrations.

```powershell
Set-Location C:/BAHAlerto
python backend/scripts/build-schema.py
Set-Location admin
npm.cmd test
```

Tests execute all migrations and the standalone bundle in isolated local PostgreSQL (PGlite), with mocked Supabase Auth/Storage schemas. They verify RLS, private-record isolation, moderation, publication, storage policies, suspension, all 12 secured tables and absence of seeded operational data. This does not replace integration testing against your actual Supabase Auth, Storage and PostgreSQL deployment.

Versioned deployment follows the [Supabase migration workflow](https://supabase.com/docs/guides/local-development/database-migrations); grants and policies follow [Supabase RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security).
