# Shared mobile and administrator database

Mobile and admin use the same Supabase project. There is no second mobile-users
or admin-users table, and passwords exist only in Supabase Auth.

| Table | Purpose |
| --- | --- |
| profiles | One shared application profile per Auth user |
| admin_memberships | Optional administrator permissions for that profile |
| road_locations | One road directory shared by both applications |
| flood_reports | Private user submissions and administrator review state |
| flood_observations | Separately published, verified observations linked to roads and optional supporting reports |
| flood_alerts | Published advisories linked to roads |
| emergency_contacts | Shared published emergency directory |
| evacuation_centers | Shared published center directory |
| saved_locations | Unique profile/road bookmarks |
| notification_preferences | One preferences row per profile; push delivery is not implemented |
| audit_logs | Administrator change history |
| admin_notifications | Per-administrator activity notifications and unread state (migration 005) |

`supabase/migrations/20261029000400_shared_account_integrity.sql` is the upgrade
for an installation with migrations 001 through 003. The owner reported applying
it in Supabase SQL Editor on 29 October 2026. Do not rerun an already applied
migration or `schema.sql` against that installation. The bundle is only for a
fresh database. Cloud constraints have not been independently inspected here.

The migration redirects membership and ownership foreign keys to the shared
profile identity. It removes `cctv_cameras`, which neither app currently uses.
It refuses to remove a populated inventory and uses no CASCADE, so unexpected
dependencies stop the transaction. Review/export populated camera records rather
than bypassing this guard. The admin CCTV empty state continues to work.

Reports and observations remain separate because a submitted estimate is not a
verified published measurement. Report coordinates represent the report location;
road coordinates represent its reference road. Mobile currently uses the selected
road coordinates and explicitly does not claim a GPS fix. Audit identities and
reviewer metadata are retained. No account, report or operational data is deleted.

The migration also denies mobile submissions for unpublished roads. Existing RLS
continues to prevent mobile users from granting administrator access, reviewing
reports, changing account status or reading another user's private reports/photos.

## Connection check

1. Run `python backend/scripts/configure-mobile.py` from the repository root.
   It copies only the public URL and publishable/anonymous key from ignored
   `admin/.env.local` to ignored `mobile/assets/backend.local.json`.
2. Restart FlutterFrame (a hot reload alone does not rerun initialization).
3. Register a mobile account, confirm its email if required, then log in.
   Registration creates a profile but never grants administrator membership.
4. In admin publish a road. Refresh mobile Home. Select that road and submit a
   report with an observation time and optional JPEG/PNG/WebP photo (up to 10 MB).
5. Refresh admin Manage Reports. Review the pending report. Refresh mobile My
   Reports to see the stored decision and reason. History shows the latest 100.
6. Separately publish an observation in admin, with source, actual observation
   time, expiry, and the correct measurement method. Mobile Check Flood fetches
   the current verified observation; stale/future/historical rows yield no depth.
7. Publish advisories/contacts/centers in admin and refresh their mobile directory.
8. Verify a second ordinary mobile account cannot read the first account's
   reports/photos or access admin. Verify suspended accounts cannot submit.

Private photos use owner-prefixed paths in the existing private `flood-photos`
bucket. Files are uploaded before the report insert; a failed submission can leave
an unreferenced private object, retained for trusted maintenance. No public photo
URL or service-role key is used. Anonymous connectivity checks and local RLS tests
have passed; authenticated cloud workflows require real user sign-in to verify.

Migration 005 (`20261029000500_admin_notifications.sql`) is the next upgrade after
004. It has been tested locally, but is not yet confirmed applied to hosted
Supabase. It adds trusted Auth sign-in timestamps and the admin inbox. See the
Admin notifications section in `README.md` for deployment and verification.
