import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bahalerto/main.dart';
import 'package:bahalerto/core/backend.dart';
import 'fixtures.dart';
import 'package:bahalerto/features/intro/bahalerto_splash.dart';
import 'package:bahalerto/features/settings/settings_screen.dart';

void main() {
  testWidgets(
    'login remains usable with a small phone, larger text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: const AccountScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final password = find.byType(TextFormField).last;
      await tester.ensureVisible(password);
      await tester.enterText(password, 'example-password');
      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Hide password'), findsOneWidget);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        false,
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Log In'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Log In').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Skipping intro opens login rather than Home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BAHAlertoApp()));
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Intro automatically opens login on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roadsProvider.overrideWith((ref) async => fixtureRoads)],
        child: BAHAlertoApp(),
      ),
    );
    expect(find.text('Skip intro'), findsOneWidget);
    expect(find.byType(BahalertoSplash), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Visit the location, moving car, wordmark and alert stages.
    for (final milliseconds in [650, 650, 650, 650]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      expect(find.text('Skip intro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Skip intro'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reduced motion goes straight to login', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roadsProvider.overrideWith((ref) async => fixtureRoads)],
        child: BAHAlertoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Skip intro'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Phone navigation preserves data disclosure', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roadsProvider.overrideWith((ref) async => fixtureRoads)],
        child: BAHAlertoApp(),
      ),
    );
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Published data'), findsOneWidget);
    for (final icon in [
      Icons.map_outlined,
      Icons.edit_note,
      Icons.person_outline,
      Icons.home_outlined,
    ]) {
      await tester.tap(find.byIcon(icon));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Published data'), findsOneWidget);
    }
  });
  testWidgets('Guest submission requires login', (tester) async {
    backendUrl = 'https://test.supabase.co';
    backendKey = 'test-public-key';
    addTearDown(() {
      backendUrl = '';
      backendKey = '';
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWithValue(null),
          roadsProvider.overrideWith((ref) async => fixtureRoads),
        ],
        child: BAHAlertoApp(),
      ),
    );
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
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
  testWidgets('No local demo report path remains', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [roadsProvider.overrideWith((ref) async => fixtureRoads)],
        child: const BAHAlertoApp(),
      ),
    );
    await tester.tap(find.text('Skip intro'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();
    expect(find.text('Save demo report'), findsNothing);
    expect(find.text('Submit Report'), findsOneWidget);
  });
}
