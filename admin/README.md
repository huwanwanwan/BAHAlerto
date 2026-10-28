> Database setup update: use `../backend/schema.sql` or the canonical migrations under `../backend/supabase/migrations/`. Earlier proposals below are historical; do not run both sets. See `../backend/README.md` for fresh-install and administrator bootstrap instructions. The owner has applied the schema and administrator bootstrap; the admin website now has the shared Supabase project configured in ignored `.env.local`. Public reads and anonymous private-report denial have been verified; authenticated workflows await sign-in.

# BAHAlerto administrator platform

Local Next.js App Router / TypeScript application. The original admin folder contained only a placeholder README. The Flutter app remains unchanged by this admin implementation.

## Run in VS Code

Open `C:/BAHAlerto/admin` in VS Code. In a PowerShell terminal:

```powershell
Set-Location C:/BAHAlerto/admin
npm.cmd ci
npm.cmd run dev
```

Open http://localhost:3000. `/login` is the administrator login page; `/admin/dashboard` shows an empty setup preview when Supabase configuration is absent. The setup preview never creates a session, grants permissions, displays invented numbers or permits writes. With configuration present, every admin page requires a verified Auth user and active administrator membership. Individual modules and mutations require their own permission.

## Connect the shared Supabase project

No project URL, publishable key or existing remote schema was available in this workspace. No remote database was inspected or changed. Local files contained only the earlier `001_roads_observations.sql` proposal.

1. Inspect the actual project's tables, policies, roles, storage buckets and existing data before applying SQL. Reconcile names/types with `src/lib/data.ts` and forms. Do not blindly run these proposals against an existing project.
2. Review `../backend/proposals/001_roads_observations.sql`, then `002_admin_platform.sql`. They are for a new schema and deliberately fail if tables already exist. **Neither proposal has been applied to Supabase.** Both were tested in local PostgreSQL via PGlite with mocked Supabase Auth/Storage schemas; this does not replace testing in a staging Supabase project.
3. After approval, apply reviewed migrations in staging. They define roads, observations, profiles, memberships, reports, advisories, contacts, centers, bookmarks, audit logs, private photo storage and secured review/save functions. Coordinate PostGIS geometry/index additions with the actual geographic query requirements; decimal coordinates currently work without that extension.
4. Copy `.env.example` to `.env.local`. Set the same project URL and publishable key intended for Flutter. Set `NEXT_PUBLIC_SITE_URL` to the trusted local or deployed origin. Never put a service-role key here.
5. In Supabase Auth configure the site URL and allowed redirect `http://localhost:3000/auth/callback` (and the trusted deployment equivalent). Use the PKCE recovery flow. Create the administrator Auth account through trusted Supabase tooling. New auth users receive a profile via trigger. Existing Auth users require a reviewed profile backfill.
6. Through the trusted SQL editor, insert an active `admin_memberships` row for the account with only required permissions. Permissions are `dashboard`, `reports`, `observations`, `roads`, `alerts`, `users`, `emergency`, `analytics`, `audit`, `account`. For example, a report reviewer needs `reports` and optionally `dashboard`/`account`; it does not need user management or advisory publication. There is no browser interface for granting roles.
7. Restart Next.js. Test regular-user denial, reviewer access, suspended-user denial, report moderation, publication and private photos against staging before using live data.

## Features and organization

- `src/app`: routes, server actions, login/recovery callback, protected admin layout and error/loading boundaries.
- `src/lib`: server-only Supabase client, session and permission checks, validation schemas, record repository and module definitions.
- `src/components`: responsive sidebar/header, searchable paginated tables, native accessible dialogs, record forms, charts, maps, review and account forms. The local shadcn-compatible Button uses Radix Slot/CVA; `components.json` configures additional shadcn/ui components.
- `src/proxy.ts`: refreshes server sessions with HTTP-only, SameSite cookies; production cookies are Secure. It is not the authorization boundary: route loaders, server actions and database functions independently enforce access.
- `tests`: unit tests and local PostgreSQL migration/policy tests.
- `e2e`: Edge browser tests for the nine modules, unconfigured login behavior and tablet layout.

Nine modules are implemented. Dashboard counts use exact database counts where permitted; unknown/error counts are labeled unavailable. Trends and tables use the latest 1,000 authorized rows, explicitly labeled; tables paginate the loaded subset. Analytics date/location/status filters apply to the chart and exported subset. CSV excludes private reporter details and neutralizes formula-like cells. Server-side filtering/pagination should replace this bounded subset approach for larger deployments.

Report moderation locks a row, checks its state, records reviewer/reason/time and writes an audit record in the same transaction. Duplicate final decisions fail. Clarification stores the request; notification delivery and reporter response UI remain future integration work. Verification does not publish an observation. Create an observation separately, retain `community_estimate` as the evidence method for a supporting verified report, and supply source, actual observation time and expiry. Historical observations are not current measurements. Public readers see only published verified non-archived observations; clients must still apply freshness rules.

Roads and emergency forms support coordinates; MapLibre displays stored markers with an attributed OpenStreetMap base layer and navigation controls. Map service availability and appropriate production tile hosting must be checked for deployment. Road creation/editing uses coordinate fields; address geocoding, drawn road geometry and click-to-fill editing are not implemented.

Advisories support draft/published/expired states, source, severity, affected road, publication and expiration timestamps. Expired published records are labeled expired on read and excluded from public current alerts. Targeted push delivery is not configured.

User management shows profile and report activity with audited suspension/reactivation. Suspension blocks database report submissions and active administrator permissions; it does not ban the Supabase Auth identity or revoke existing Auth sessions. Full identity banning requires a separately authorized trusted backend using the Auth Admin API.

Emergency records can be edited, archived and published. Operational details retain verification time; no center capacity is inferred. Audit records have no client write/update/delete permission. Account settings support password changes; additional administrator preference fields and profile editing are not implemented.

## Verification

```powershell
npm.cmd run typecheck
npm.cmd test
npm.cmd run build
# With dev server running and Microsoft Edge installed:
npm.cmd run test:browser
```

PGlite tests exercise migration syntax, owner isolation, role escalation denial, report review denial, null/empty rejection reasons, duplicate approvals, evidence preservation, road/advisory/contact/center saves, audit deletion denial, anonymous access, photo isolation and suspension. They use isolated test fixtures that never appear in the website or mobile app.

Live Supabase Auth email delivery, server session refresh, connected browser workflows, actual Storage uploads, deployed RLS behavior, cross-device responsiveness and Flutter/database synchronization still require a configured staging project. The Flutter app still uses demonstration data and does not submit to this database yet. No production readiness or mobile synchronization is claimed.

Implementation references: [Next.js authentication](https://nextjs.org/docs/app/guides/authentication), [Supabase server-side clients](https://supabase.com/docs/guides/auth/server-side/creating-a-client), and [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

## CCTV overview and concise navigation

Dashboard includes a CCTV overview card linked to `/admin/cctv`. The sidebar now includes CCTV and uses shorter labels for existing modules. Shared actions use consistent concise labels such as Edit, Save changes, Save decision, Sign in and View cameras. Nested detail routes retain their sidebar highlight.

CCTV currently displays an explicit unconfigured empty state. No camera source, stream proxy, camera database table or recording system was added. Configured access uses the existing dashboard permission; no new database migration is required for this interface change.

## Branded login and dashboard layout

Recent Flood Reports and CCTV now share equal-width dashboard cards on desktop and stack on smaller screens; the dedicated CCTV page remains unchanged. The login uses a centered two-panel green portal card, the supplied `admin-logo.png`, password visibility controls and the existing authentication flow. Sidebar branding uses `admin-logo.png` expanded and `admin-logo-collapse.png` collapsed or on narrow screens. Assets are copied unchanged into `public/`. Text uses a consistent Segoe UI/Arial system font stack. Sidebar and focus transitions respect reduced-motion preferences.

Audit Logs now live under Reports & Analytics at `/admin/analytics?tab=audit`. The audit tab requires the existing `audit` permission independently of `analytics`. Settings only contains account settings and connection configuration guidance; it no longer loads audit records. Sidebar module labels use the requested Manage prefix. No database policy changes were required.

## Simplified management tables

Tables emphasize location, depth, relevant timestamps and status. Raw UUIDs and coordinates are omitted from primary management columns; existing review/edit forms retain full records. Flood levels combine verification, freshness and publication into one Data status column. The overview shows only location, depth and status. User lists use Joined for account creation. Audit tables show action, module and date with administrator/record identifiers in an expandable details cell. Status filters are module-specific, analytics uses one shared filter set, and depth is shown in centimeters with inch conversion available on hover. No records, columns or policies were removed from the database.
