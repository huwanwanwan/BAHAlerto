import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahalerto/core/backend.dart';
import 'package:bahalerto/features/flood_map/map_screen.dart';
import 'package:bahalerto/features/reports/reports_screen.dart';
import 'package:bahalerto/features/settings/settings_screen.dart';
import 'fixtures.dart';
import 'package:bahalerto/features/home/home_screen.dart';

void main() {
  for (final entry in <String, Widget>{
    'home': const HomeScreen(),
    'map': const MapScreen(),
    'reports': const ReportsScreen(),
    'profile': const SettingsScreen(),
  }.entries) {
    testWidgets('${entry.key} fits a narrow phone with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roadsProvider.overrideWith((ref) async => fixtureRoads),
            userProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(body: entry.value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (entry.key == 'home') {
        final viewport = find.byType(SingleChildScrollView).first;
        expect(tester.getBottomLeft(viewport).dy, greaterThanOrEqualTo(639));
        expect(tester.getSize(viewport).height, greaterThan(450));
      }
      final bell = find.byIcon(Icons.notifications_active_rounded);
      final bellPosition = entry.key == 'home' ? tester.getTopLeft(bell) : null;
      final list = entry.key == 'home'
          ? find.byType(SingleChildScrollView).first
          : find.byType(ListView).first;
      for (var i = 0; i < 5; i++) {
        await tester.drag(list, const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (entry.key == 'home') {
          expect(tester.getTopLeft(bell).dy, lessThan(bellPosition!.dy));
          expect(find.text('Guest'), findsOneWidget);

        }
      }
    });
  }
}
