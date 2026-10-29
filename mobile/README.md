# BAHAlerto mobile

The Flutter web app now connects to the same Supabase project as admin.
It supports email/password registration and login, private report submission and
review history, optional private report photos, saved locations, stored alert
preferences, and published roads, observations, advisories, contacts and centers.
Sample flood records are no longer used in the application.

From the repository root, run:

```powershell
python backend/scripts/configure-mobile.py
```

Then open `C:/BAHAlerto/mobile` in VS Code and run **FlutterFrame: Start Emulator**.
Stop/restart an existing FlutterFrame session after changing configuration or
adding dependencies. The ignored `assets/backend.local.json` is loaded at startup;
only a public project URL and publishable/anonymous client key are copied. You
can also supply `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as Dart defines.
For a different machine/project, use `assets/backend.example.json` as the template.
Missing configuration shows setup guidance and never falls back to sample data.

See [shared database setup and manual acceptance checks](../backend/SHARED-DATABASE.md).
Email confirmation remains controlled by Supabase. Ordinary registrations never
receive administrator access. The existing published-road directory is paged;
report history and published directories show the latest 100 records with refresh.

The map remains an explicitly illustrative road layout. GPS, a geographic map and
push delivery are not implemented. Report coordinates use the selected road.
Public data requires a refresh to show administrator changes; Check Flood reloads
on demand and when the displayed observation expires. Report photos are optional
JPEG/PNG/WebP files up to 10 MB stored privately. The current target is Flutter web;
native Android/iOS platform projects and native permissions have not been set up.

```powershell
Set-Location C:/BAHAlerto/mobile
../.tools/flutter/bin/flutter.bat analyze
../.tools/flutter/bin/flutter.bat test
../.tools/flutter/bin/flutter.bat build web
```

## Opening animation

Startup uses the layered animation supplied in `files.zip`: its Flutter source
is in `lib/features/intro/bahalerto_splash.dart` and the 17 transparent layers
are in `assets/logo/`. The 3.6-second sequence shows a soft moving map, location
pin and radar rings, arriving car and water, individual popping letters, alert
arcs, and the supplied Filipino tagline. Images are preloaded before playback.
`IntroScreen` retains the skip action, reduced-motion bypass and fade into login.
Signing in opens the app; registration and explicit guest access remain available.
The preview video is reference material and is not bundled into the application.

## Branded account screen

The intro opens a white login card behind a green header with rounded bottom
corners. The foreground header uses the owner-provided `user-login-icon.png`, preserving
its transparency and full image with right-aligned `BoxFit.contain`. The title
and tagline sit above its open left side. See [artwork notes](design/login-sticker.md). Login and registration retain Supabase authentication, autofill,
validation, password visibility, email-confirmation messages and guest access.
The scrollable layout accommodates small phones, larger text and the keyboard.

## Reliable VS Code preview workspace

Open `../BAHAlerto.code-workspace` for the Mobile, Admin and Backend folders
in one VS Code window. Mobile is first and the Flutter SDK folder is outside
these workspace folders, so FlutterFrame finds the app's `mobile/pubspec.yaml`
and `mobile/lib/main.dart` instead of an SDK/example package.

If an existing preview cached an asset that was replaced, stop it before running
`flutter clean` and `flutter pub get` from `C:/BAHAlerto/mobile`, then start
FlutterFrame again. Do not start a second preview on port 8686 simultaneously.

## Status area and entry motion

A shared `PhoneViewport` reserves the native system top inset for every route.
Desktop web phone previews up to 640 px wide additionally show a persistent
preview bar: current local time plus illustrative signal, Wi-Fi and battery.
These indicators are preview decoration, not hardware measurements. Native
phones and mobile browsers use their real OS status bar instead of a duplicate.
The login artwork appears on the left and the title/tagline on the right. The
artwork slides from right to left, then the text fades/slides in. Splash-to-login
also fades/slides gently. Reduced-motion settings bypass these movements.

The branded login header continues its green gradient through the status area
with light status indicators. Artwork, copy and controls retain a separate safe
top inset, so they cannot cover the clock, signal or battery. Leaving login
restores the normal light status background for the inner app screens.
