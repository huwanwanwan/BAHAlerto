import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/backend.dart';
import 'features/intro/intro_screen.dart';
import 'features/home/home_screen.dart';
import 'features/flood_checker/checker_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/alerts/alerts_screen.dart';

import 'features/settings/settings_screen.dart';
import 'features/flood_map/map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadBackendConfiguration();
  if (backendConfigured) {
    try {
      await Supabase.initialize(url: backendUrl, publishableKey: backendKey);
    } catch (_) {
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Backend could not start. Check your connection and restart the app.',
              ),
            ),
          ),
        ),
      );
      return;
    }
  }
  runApp(const ProviderScope(child: BAHAlertoApp()));
}

class BAHAlertoApp extends StatelessWidget {
  const BAHAlertoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BAHAlerto',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen).copyWith(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: lightGreen,
        onSecondary: ink,
        primaryContainer: const Color(0xFFEAF5EE),
        onPrimaryContainer: ink,
        error: dangerRed,
        onError: Colors.black,
        surface: Colors.white,
        surfaceTint: Colors.transparent,
        onSurface: const Color(0xFF23392C),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEAF5EE),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primaryGreen
                : mutedText,
          ),
        ),
      ),
      fontFamily: 'Arial',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    home: const IntroScreen(child: _EntryScreen()),
  );
}

class _EntryScreen extends StatefulWidget {
  const _EntryScreen();
  @override
  State<_EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<_EntryScreen> {
  bool entered = false;
  void enter() => setState(() => entered = true);
  @override
  Widget build(BuildContext context) => entered
      ? const AppShell()
      : AccountScreen(onAuthenticated: enter, onGuest: enter);
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final roads = ref.watch(roadsProvider);
    final pages = [
      HomeScreen(
        onNavigate: (i) {
          setState(() => tab = 1);
          if (i == 2) {
            openChecker(context, onReport: () => setState(() => tab = 2));
          }
        },
      ),
      MapScreen(onReport: () => setState(() => tab = 2)),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.water_drop_rounded, color: primaryGreen),
            SizedBox(width: 8),
            Text(
              'BAHAlerto',
              style: TextStyle(fontWeight: FontWeight.w800, color: ink),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Flood alerts',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Flood alerts')),
                  body: const AlertsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF1D7),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: const Text(
              'Published data - Missing information does not mean safe passage.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF805300),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    if (roads.isLoading) const LinearProgressIndicator(),
                    if (roads.hasError)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text('Road directory unavailable.'),
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(roadsProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(index: tab, children: pages),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Flood Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note),
            label: 'Report Flood',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
