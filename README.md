> Integration update (29 October 2026): mobile now uses the admin Supabase project
> for accounts, reports and published information. See [mobile setup](mobile/README.md)
> and [database migration notes](backend/SHARED-DATABASE.md). The historical prototype
> description below predates this integration.

# BAHAlerto

Flutter + Riverpod mobile interface for flood awareness in the Philippines. **All records are fixed sample data, never live conditions.**

## Current phase

Implemented: four persistent main tabs (Home, Flood Map, Report Flood, Profile), with Check Flood opening as a child of Flood Map, notification bell, Home shortcuts, sample road search and marker filtering, source/status/time details, inline adjustable human height comparison and vehicle warnings, and a guest submission gate. Existing practice-report validation and observation time selection remain available through **Save demo report**, which never submits to an administrator. Practice entries record an automatic UTC creation timestamp and disappear on restart.

All flood and advisory records remain fixed demonstration fixtures. The map is a selectable schematic, not a geographic map. GPS, map layers, photo uploads, Supabase Authentication, database access, saved-location persistence, Filipino translation and personalized notifications are not connected. Login/Register explain this limitation without simulating authentication. Emergency Contacts shows an empty verified-directory state instead of invented hotlines. A local Next.js administrator application is now implemented in `admin/`; see its README for setup and live integration limits.

Folders: `mobile/lib/features/` contains feature screens; `mobile/lib/shared/` provides reusable presentation; `mobile/lib/core/` provides sample records and Riverpod state. `admin/` contains the Next.js administrator app; `backend/proposals/` contains unapplied shared database proposals. See [implementation review](IMPLEMENTATION.md) for the reviewed baseline and remaining integration requirements.

## Windows 11 setup

Flutter is installed locally at `C:\BAHAlerto\.tools\flutter`. Use its bundled Dart, not the separately installed standalone Dart. In each new PowerShell terminal:

```powershell
Set-Location C:\BAHAlerto
$env:Path = "C:\BAHAlerto\.tools\flutter\bin;" + $env:Path
flutter --version
flutter doctor -v
flutter devices
Set-Location mobile
flutter pub get
flutter run -d edge --web-port 8686
```

Chrome alternative: `flutter run -d chrome --web-port 8686`. No Android emulator, Android SDK or Visual Studio C++ workload is required for web UI testing. Doctor warnings for unused platforms do not prevent web development.

For a fresh installation where `.tools/flutter` does not exist:

```powershell
Set-Location C:\BAHAlerto
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git .tools/flutter
code --install-extension Dart-Code.flutter
code --install-extension YashPatel-2611.flutterframe
```

## Phone preview inside VS Code

1. Open **the mobile folder**: `code C:\BAHAlerto\mobile`.
2. Restart all VS Code windows after installation to inherit the updated user PATH. FlutterFrame launches `flutter` from the extension host PATH; changing only the terminal PATH is insufficient. If the Dart extension does not detect Flutter, use **Flutter: Change SDK** and select `C:\BAHAlerto\.tools\flutter`. A workspace-local setting is supplied.
3. Run **FlutterFrame: Start Emulator** in the Command Palette (`Ctrl+Shift+P`). Despite the command name, this is a Flutter Web preview, not a native simulator.
4. Choose a phone via **FlutterFrame: Select Device**. Its documented presets include iPhone SE and iPhone 15 Pro; use a custom 375 × 812 viewport if the installed version offers one, or use browser device tools for exact iPhone X dimensions.
5. Save Dart changes to reload; use **FlutterFrame: Hot Reload** or **FlutterFrame: Hot Restart**. Stop FlutterFrame before running another process on port 8686.

FlutterFrame is third-party. It documents VS Code 1.85+ and web-enabled Flutter projects, but advertises no exact Flutter SDK compatibility matrix. Installation does not prove its WebView works on this computer. Browser APIs may behave differently within its iframe.

## Reliable browser fallback and hot reload

Open the repository root in VS Code and choose **BAHAlerto • Edge** in Run and Debug, then press F5. Save to reload, use the debug toolbar lightning button, or run **Flutter: Hot Reload**. From `flutter run`, press `r` for reload, `R` for restart, `q` to stop. Current Flutter supports web hot reload; restart if changes affect initialization.

In Edge/Chrome press F12, then Ctrl+Shift+M to toggle device emulation. Set responsive dimensions to **375 × 812** (iPhone X CSS viewport). Also check 320 × 568, 390 × 844, landscape and increased text size. Exercise all tabs, the menu, road selections, search with no results, report validation, timestamp selection and valid report saving. The centered UI caps content width on wide screens but stays fluid on phones.

## iPhone X and future native iOS

Windows can run Flutter Web. It cannot build/sign the official native iOS application: that workflow requires macOS with Xcode, signing and a compatible iOS deployment target. No Mac or Android device is assumed here. Browser device emulation does not reproduce native plugins, hardware, iOS safe areas or Safari behavior.

For optional iPhone Safari web testing on the same trusted Wi-Fi:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8686
ipconfig
```

Visit `http://<your-PC-IPv4-address>:8686` from Safari. Windows Firewall may require allowing this port on a private network. Stop the server afterward. Web-server debugging/reload differs from the supported Edge/Chrome debug workflow; this is a browser smoke test. iPhone X Safari compatibility depends on its installed iOS and the Flutter renderer support. Native push, image permissions and storage integrations need separate platform testing.

## Verification

```powershell
Set-Location C:\BAHAlerto\mobile
..\.tools\flutter\bin\flutter.bat analyze
..\.tools\flutter\bin\flutter.bat test
..\.tools\flutter\bin\flutter.bat build web
```

## Next phases

1. Review and test the mobile interface before integrations.
2. Replace the schematic with MapLibre using a web/iOS-compatible package; select a permitted tile/style provider, show attribution, add road search and handle unavailable data.
3. Create Supabase PostgreSQL/PostGIS migrations for profiles linked to auth users, road_segments, flood_observations, community_reports, vehicle_types, evacuation_centers and alerts. Add geographic indexes, foreign keys, input constraints, RLS, private image storage policies and administrator audit records. Keep service-role keys exclusively on the server.
4. Add FastAPI JWT validation, geographic queries, report submission, moderation and assessment endpoints. Use explicit source/freshness metadata and provider adapters; never assume universal government API coverage.
5. Add the Next.js administrator dashboard. Require authorized review before verification or alert publication. Add optional native Firebase messaging later.

## Setup references

- [Flutter installation](https://docs.flutter.dev/install/with-vs-code)
- [Flutter VS Code workflow](https://docs.flutter.dev/tools/vs-code)
- [Flutter hot reload](https://docs.flutter.dev/tools/hot-reload)
- [FlutterFrame publisher documentation](https://marketplace.visualstudio.com/items?itemName=YashPatel-2611.flutterframe)
- [Native iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)
