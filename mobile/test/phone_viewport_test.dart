import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bahalerto/shared/phone_viewport.dart';
import 'package:bahalerto/features/settings/settings_screen.dart';

void main() {
  for (final register in [false, true]) {
    testWidgets('artwork stays stationary while fading on ${register ? 'sign-up' : 'login'}', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: AccountScreen(register: register))));
      await tester.pump(const Duration(milliseconds: 100));
      final artwork = find.byKey(const ValueKey('login-header-artwork'));
      final initial = tester.getRect(artwork);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getRect(artwork), initial);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.getRect(artwork), initial);
      expect(find.byType(AnimatedCrossFade), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('login sign-up link fits a phone without scrolling', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 54, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      builder: (_, child) => PhoneViewport(child: child!),
      home: const AccountScreen(),
    )));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration fits a phone without scrolling', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 54, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(
      builder: (_, child) => PhoneViewport(child: child!),
      home: const AccountScreen(register: true),
    )));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview status remains above pushed mobile routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            PhoneViewport(showPreviewStatus: true, child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Details')),
                ),
              ),
              child: const Text('Open details'),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('phone-preview-status')), findsOneWidget);
    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-preview-status')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Details')).dy,
      greaterThanOrEqualTo(36),
    );
  });
  testWidgets('login colors the status area while its artwork stays below it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (_, child) =>
              PhoneViewport(showPreviewStatus: true, child: child!),
          home: Builder(
            builder: (context) => AccountScreen(
              onGuest: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Home')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final status = find.byKey(const ValueKey('phone-preview-status'));
    final statusBottom = tester.getBottomLeft(status).dy;
    expect(
      tester.widget<Icon>(find.byIcon(Icons.wifi_rounded)).color,
      Colors.white,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('login-header-artwork'))).dy,
      greaterThanOrEqualTo(statusBottom),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('login-header-copy'))).dy,
      greaterThanOrEqualTo(statusBottom),
    );
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.wifi_rounded)).color,
      const Color(0xFF14261D),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('native top inset is reserved without a duplicate status bar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            PhoneViewport(showPreviewStatus: false, child: child!),
        home: const Scaffold(
          body: SizedBox.expand(key: ValueKey('screen-content')),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('phone-preview-status')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('screen-content'))).dy,
      44,
    );
  });
  testWidgets('login illustration settles right of the title on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountScreen())),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(const ValueKey('login-header-artwork'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const ValueKey('login-header-copy'))).dx,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
