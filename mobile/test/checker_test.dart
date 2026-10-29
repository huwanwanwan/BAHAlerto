import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bahalerto/core/data.dart';
import 'package:bahalerto/core/backend.dart';
import 'fixtures.dart';
import 'package:bahalerto/main.dart';
import 'package:bahalerto/core/flood_repository.dart';
import 'package:bahalerto/features/flood_checker/checker_screen.dart';
import 'package:bahalerto/features/flood_checker/comparison_section.dart';
import 'package:bahalerto/features/flood_checker/measurements.dart';

class FailedRepository implements FloodRepository {
  @override
  Future<FloodRecord> roadObservation(String roadId) async =>
      throw StateError('offline');
}

void main() {
  test('unit conversions round trip and height format', () {
    expect(fromCentimeters(2.54, LengthUnit.inches), closeTo(1, .00001));
    for (final unit in LengthUnit.values) {
      expect(
        toCentimeters(fromCentimeters(165, unit), unit),
        closeTo(165, .00001),
      );
    }
    expect(feetAndInches(165), '5 ft 5 in');
  });
  test('common scale includes flood depths exceeding person height', () {
    expect(comparisonExtent(450), greaterThan(450));
    expect(comparisonRatio(45, 165), closeTo(.272727, .00001));
    expect(comparisonRatio(45, 120), greaterThan(comparisonRatio(45, 200)));
  });
  testWidgets(
    'height and vehicle choices persist across sections on small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ComparisonSection(depth: 450)),
          ),
        ),
      );
      expect(find.textContaining('5 ft 5 in'), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(30, 0));
      await tester.pumpAndSettle();
      final height = tester.widget<Slider>(find.byType(Slider)).value;
      expect(height, isNot(165));
      await tester.tap(find.text('Vehicle assessment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUV'));
      await tester.pumpAndSettle();
      expect(find.text('Selected vehicle: SUV'), findsOneWidget);
      expect(
        find.textContaining('Greater clearance does not establish'),
        findsOneWidget,
      );
      await tester.tap(find.text('Height comparison'));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, height);
      await tester.tap(find.text('Vehicle assessment'));
      await tester.pumpAndSettle();
      expect(find.text('Selected vehicle: SUV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('selected road loads without duplicate selector', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roadsProvider.overrideWith((ref) async => fixtureRoads),
          floodRepositoryProvider.overrideWithValue(FixtureRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(body: CheckerScreen(roadId: 'road-two')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Taft Avenue'), findsWidgets);
    expect(find.byType(RoadSelector), findsNothing);
    expect(find.text('15 cm'), findsOneWidget);
  });
  testWidgets('historical record has no numerical water comparison', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roadsProvider.overrideWith((ref) async => fixtureRoads),
          floodRepositoryProvider.overrideWithValue(FixtureRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(body: CheckerScreen(roadId: 'road-three')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No Recent Flood Data'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Numerical water comparison unavailable'),
      findsOneWidget,
    );
  });
  testWidgets('map passes selection, back retains map, report is prefilled', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roadsProvider.overrideWith((ref) async => fixtureRoads),
          floodRepositoryProvider.overrideWithValue(FixtureRepository()),
        ],
        child: MaterialApp(home: AppShell()),
      ),
    );
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(AppShell));
    ProviderScope.containerOf(
      context,
    ).read(selectedRoadProvider.notifier).select(1);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListView).hitTestable(),
      const Offset(0, -750),
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(find.text('Check Flood')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check Flood'));
    await tester.pumpAndSettle();
    expect(find.text('Taft Avenue'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(ProviderScope.containerOf(context).read(selectedRoadProvider), 1);
    expect(find.text('Check Flood').hitTestable(), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('Check Flood')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check Flood'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListView).hitTestable(),
      const Offset(0, -1600),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Report Flood Here'));
    await tester.tap(find.text('Report Flood Here'));
    await tester.pumpAndSettle();
    expect(find.text('Community reports'), findsOneWidget);
    expect(find.text('Taft Avenue').hitTestable(), findsOneWidget);
  });
  testWidgets('repository failure offers retry without invented depth', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CheckerScreen(
              roadId: 'road-two',
              repository: FailedRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(ComparisonSection), findsNothing);
  });
}
