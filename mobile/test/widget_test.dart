import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bahalerto/main.dart';

void main() {
  testWidgets('Intro automatically opens home on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: BAHAlertoApp()));
    expect(find.text('Skip intro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Visit the car, particle morph, and emblem stages before the deadline.
    for (final milliseconds in [1200, 1200, 1200, 1100]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      expect(find.text('Skip intro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('Skip intro'), findsNothing);
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reduced motion goes straight to the dashboard', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ProviderScope(child: BAHAlertoApp()));
    await tester.pumpAndSettle();
    expect(find.text('Skip intro'), findsNothing);
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Phone navigation preserves demo disclosure', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: BAHAlertoApp()));
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
    for (final icon in [
      Icons.map_outlined,
      Icons.edit_note,
      Icons.person_outline,
      Icons.home_outlined,
    ]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('DEMO MODE'), findsOneWidget);
    }
  });
  testWidgets('Guest submission requires login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BAHAlertoApp()));
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListView).hitTestable(),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();
    expect(find.text('Login Required'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });
  testWidgets('Invalid report cannot be saved', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BAHAlertoApp()));
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListView).hitTestable(),
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save demo report'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a depth from 0 to 1000 cm.'), findsOneWidget);
    expect(find.text('Add at least 10 characters.'), findsOneWidget);
  });
}
