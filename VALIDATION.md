# Supabase connection check - 29 October 2026

The owner reported successful execution of schema.sql and bootstrap-admin.sql. Configured the admin website with the supplied base project URL and publishable key in ignored admin/.env.local. No database password, service-role key or administrator password was requested or stored.

Read-only remote checks passed for public roads, observations, advisories, emergency contacts and evacuation centers. Unauthenticated reads of private flood reports returned 401. Supabase Auth settings responded successfully. Authenticated dashboard, moderation, uploads and recovery delivery still need verification after the owner signs in.

## Earlier verification

# Administrator platform validation - 28 October 2026

- Next.js production build: passed, including TypeScript compilation.
- `npm.cmd run typecheck`: passed.
- `npm.cmd test`: four passing tests. The PostgreSQL test executes both proposed migrations in isolated PGlite with mocked Supabase Auth/Storage schemas, exercising owner isolation, role escalation denial, review permissions, duplicate approvals, null/empty reasons, estimate preservation, CRUD save functions, append-only audit access, public reads, private photos and suspended submissions.
- `npm.cmd run test:browser`: four passing Edge tests covering nine modules, emergency tabs, login rejection without configuration, password visibility, collapsible sidebar, tablet and desktop overflow. Screenshots reviewed locally.
- Configured production-mode smoke check with nonfunctional test URL/key and no session: dashboard, reports and settings each returned HTTP 307 to `/login`. No live Supabase credential or request was used.
- Admin development preview: http://localhost:3000. No database connection or administrator session is simulated in setup mode.
- Not verified against live Supabase: authentication email/recovery delivery, token refresh, actual Storage, deployed policies, connected admin workflows and mobile synchronization. Map tile/network availability requires deployment testing. No live migration was applied.
- Run/setup details and remaining limitations: `admin/README.md`.

## Previous mobile validation records

# Check Flood and unit conversion update - 28 October 2026

- Flutter analysis: no issues.
- Flutter tests: 14 passed. New tests cover conversion round trips, height formatting, depth/height scale, large depths, small-phone layout, retained segment state, selected-road loading, historical missing-depth behavior, map/back/report prefilling and repository errors.
- Flutter web build: passed with Wasm dry run; existing Cupertino font warning remains.
- Map is still schematic. Real GPS/camera preservation, Supabase loading, database RLS, offline caching and live freshness/advisories cannot be verified without integrations.
- Proposed road/observation SQL is saved under backend/proposals; not executed or database-tested.

## Previous validation records

# Current navigation update validation ? 28 October 2026

- Flutter analysis: no issues.
- Flutter tests: seven passed, including guest submission login gate, five-tab navigation, report validation, reduced motion and missing-depth safeguards.
- Flutter web build: passed, including Wasm dry run. Existing unused Cupertino font warning remains.
- Browser visual review and native-device behavior were not tested in this update.
- Live Supabase, real geographic mapping, GPS, uploads, account persistence and Next.js admin remain unimplemented; see IMPLEMENTATION.md.

## Earlier environment verification

# Local verification

Validated on Windows 11 using Flutter 3.47.8 stable and bundled Dart 3.13.7.

- `flutter analyze`: no issues.
- `flutter test`: four passing tests covering unknown-depth warnings, historical data, navigation at 375 × 812 and invalid report submission.
- `flutter build web`: successful JavaScript build and Wasm dry run. Build reported an unused Cupertino font family warning from Flutter icon tooling; no Cupertino icons are used by this app.
- `flutter doctor -v`: Chrome and Edge detected. Android command-line tools/licenses are incomplete, which does not block the chosen web workflow.
- VS Code Flutter 3.144.0 and FlutterFrame 2.0.0 installed.

Not yet verified: visual appearance in a live browser, FlutterFrame WebView rendering, iPhone Safari and native iOS. The map is a schematic; no integrations or real-time flood data are active. Reports have no durable storage.

## Setup incident

The elevated shell initially ignored the tool's requested working directory and ran Flutter scaffolding under `D:\NAZATRACK - PROJECT` (including a `mobile` subfolder). Subsequent commands explicitly changed to `C:\BAHAlerto\mobile`. The unrelated directory was left in place because its original contents were not known; inspect it before removing any generated files.
