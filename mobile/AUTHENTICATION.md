# Mobile authentication setup

Mobile and admin use one Supabase project. Supabase Auth stores credentials;
`public.profiles.id = auth.users.id` is the shared user identity. The existing
002 profile trigger and 003 backfill create profiles. Apply migrations 001–004
in order if setting up a new project. No additional table or migration is needed
for Google sign-in. Never store passwords or Google secrets in profile tables.
Admin capabilities remain in `admin_memberships`; registering does not grant them.

## Google setup (required on the hosted project)

The connected project's public Auth settings were checked on 2026-10-29:
email signup is enabled, email confirmation is required, and Google is disabled.

1. Create a Google OAuth web client in Google Cloud. Add the callback URL shown
   in Supabase Authentication > Sign In / Providers > Google as its authorized
   redirect URI (`https://<project-ref>.supabase.co/auth/v1/callback`).
2. Enable Google in Supabase and save the Google client ID and secret there.
3. Under Authentication > URL Configuration, allow the exact mobile web origins
   used to launch the app, including `http://localhost:8686/` for FlutterFrame
   and the production mobile web URL. Keep admin's existing URLs allowed too.
4. Launch the web app directly in Edge to verify Google consent and the return
   to BAHAlerto. An embedded preview may restrict provider navigation.

This checkout currently has a web platform only. Before shipping Android/iOS,
generate those platform projects and configure the native redirect scheme
`com.bahalerto.app://login-callback/` in their manifests/plists and Supabase.

## Verification with real accounts

Register with an email you control, confirm the email, then log in. Confirm
that Supabase Authentication lists the user and `public.profiles` has the same
UUID. An admin with users permission should see that profile in Users. After
Google is configured, repeat with Google and check the same shared profile
relationship. If using the same email, review Supabase identity-linking settings;
do not create a separate app account table. Local automated tests mock Auth
responses; they do not create or delete hosted user accounts.

References:
- https://supabase.com/docs/reference/dart/auth-signinwithoauth
- https://supabase.com/docs/guides/auth/social-login/auth-google

## Remembered sign-in and guests

Supabase Flutter persists the authenticated session and refreshes its access
token. After the intro, a restored account opens Home directly. Users sign in
again after explicit sign-out, a revoked/invalid session, clearing browser/app
storage, or switching to another device/browser/origin. Guest browsing is only
an in-memory choice for that app visit; it does not create an Auth account.
Protected report submission and saved-location actions open login for guests.
Registration that requires email confirmation is not a signed-in session until
confirmation and successful authentication. No passwords are saved by the UI.
