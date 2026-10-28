# Mobile implementation review

Reviewed baseline: Flutter/Riverpod with an animated intro, reusable PageBody/InfoCard/Tag widgets, searchable sample home records, selected-road state, schematic marker map, source/status/time details, conservative vehicle warnings, validated in-memory practice reports, alerts, evacuation information and settings. Preserved those components and the intro. No live backend or Next.js application was present.

Navigation uses four main tabs: Home, Flood Map, Report Flood and Profile. Check Flood opens as a child screen from the map road information panel, using the selected road index without asking for reselection. Back retains the schematic map selection, search, filter and scroll state. There is no geographic camera/zoom yet. Home Quick Check opens the same child screen; Report Flood Here prefills the selected road. Alerts remain on the bell.

Check Flood contains segmented height and vehicle sections. Height defaults to 165 cm and adjusts from 120 to 200 in 1 cm increments. Both the cartoon person and waterline share the same ground and scale. The display extent expands for deep water rather than clipping it. cm, inches and meters are selectable; person height also shows feet and inches. The length converter accepts cm, inches or meters and never edits an observation. Vehicle cards retain selection across section switches. Unknown depth has no waterline or numerical comparison. Sample observations, including unverified fixtures, remain explicitly marked as demonstration information; they are not production measurements.

`FloodRepository` is an injectable asynchronous boundary with a demo adapter. Loading and retry/error states are implemented. No credentials, Supabase client dependency, schema or active database connection were found. Real verified-observation selection, freshness logic, authorized closure advisories and offline cache remain integration work. No offline/current claim is made for demo fixtures.

Proposed SQL: `backend/proposals/001_roads_observations.sql` creates road locations and flood observations, geographic coordinates, source/evidence/status/time metadata, review fields, indexes and public-read RLS/grants. It deliberately grants no client writes. It has not been executed or database-tested and needs schema review, admin audit history and policy tests before use. The rules follow the [Supabase RLS documentation](https://supabase.com/docs/guides/database/postgres/row-level-security). No migration will be run without approval.

To test in VS Code: run Flutter with the existing BAHAlerto Edge launch configuration or run `flutter run -d edge --web-port 8686` from `mobile`. Open Flood Map, choose a road and press Check Flood in its road panel. Switch units and sections, move the height slider, choose vehicles, return to the map, and try Report Flood Here. Historical Marikina data exercises the missing-depth state. Use browser device emulation for 320/375/390 px screens. Run `flutter test` for automated checks.

Guests can inspect sample public information and practice filling a report. Submit Report requires login. Since authentication is unavailable, Log In and Register explain the missing integration. Save demo report remains a separate local practice action. It records submission UTC time separately from the user-selected observation time and never publishes information.

## Integration contract still to implement

Use a shared Supabase PostgreSQL database and Supabase Auth for the Flutter app and Next.js admin. Configuration and credentials have not been supplied. No authentication or RLS security claim is made by this interface prototype.

- Profiles keyed by auth user UUID: name, optional phone and preferred area; passwords only in Supabase Auth.
- Roads and observations: location/geometry, depth in cm or null, road condition, evidence category, source, observed timestamp and review metadata. Historical hazards must remain distinct from current observations.
- Reports: owner UUID, pin coordinates, estimated depth, optional private photo reference, description, observation timestamp, server-generated submission timestamp and pending/verified/rejected status. Submission must default to pending; clients cannot self-verify.
- Owner-only RLS for private profiles, reports, saved locations and notification preferences; anonymous read access only to published public records. Storage policies must bind uploads to the report owner. Administrator roles must be assigned through trusted server/database operations and enforced in policies or secured database functions.
- Administrator review must atomically record reviewer, decision and audit event, and create/update a public observation only after verification. Never expose a service-role key to Flutter or browser JavaScript.
- Next.js admin sections: dashboard, report queue, observations, roads, advisories, emergency contacts, evacuation centers, users, analytics and settings. Authentication and backend authorization must precede moderation.
- Replace schematic with an attributed geographic map, location search/provider, permission-on-use GPS, road selection, filters and layers. Add real pin selection and photo handling to reporting.
- Add authenticated profile editing, durable guest bookmarks, account synchronization, English/Filipino translations and supported notification delivery.

No production database changes, real reports or external publication were made.

## Administrator platform update

The admin placeholder is now a local Next.js/TypeScript App Router app with all nine module routes, authentication and permission checks, record forms, report moderation, Recharts, MapLibre, CSV export and empty setup mode. See `admin/README.md` for exact capabilities, tests, configuration and limitations. `002_admin_platform.sql` extends the earlier schema proposal; neither SQL file was applied. Flutter is still a demonstration app and is not synchronized with Supabase. Real project credentials, schema reconciliation, migration approval and staging verification remain necessary.

## Database schema implementation - 29 October 2026

Canonical Supabase migrations and the generated transactional `backend/schema.sql` now define the shared 12-table schema, RLS, private photo storage, reviewed report workflow, audit trail and current-observation query. See `backend/README.md` for installation and administrator bootstrap. Tests run locally against an isolated PostgreSQL engine. No Supabase project connection was available; remote provisioning, actual Auth/Storage verification and Flutter integration remain outstanding. Archived proposals must not be applied in addition to canonical migrations.
