import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bahalerto/main.dart';
import 'package:bahalerto/core/backend.dart';
import 'package:bahalerto/features/settings/settings_screen.dart';
import 'fixtures.dart';

const account = User(
  id: 'saved-user',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-10-29T00:00:00Z',
);

class TestSession extends Notifier<User?> {
  @override
  User? build() => null;
  void setUser(User? user) => state = user;
}

final session = NotifierProvider<TestSession, User?>(TestSession.new);

ProviderContainer container() => ProviderContainer(
  overrides: [
    userProvider.overrideWith((ref) => ref.watch(session)),
    roadsProvider.overrideWith((ref) async => fixtureRoads),
    profileProvider.overrideWith(
      (ref) async => {'full_name': 'Saved user', 'status': 'active'},
    ),
    preferencesProvider.overrideWith((ref) async => null),
    savedProvider.overrideWith((ref) async => []),
    myReportsProvider.overrideWith((ref) async => []),
  ],
);
Future<void> finishIntro(WidgetTester tester) async {
  await tester.tap(find.text('Skip intro'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'restored account enters Home after intro and sign-out returns to login',
    (tester) async {
      final state = container();
      addTearDown(state.dispose);
      state.read(session.notifier).setUser(account);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: state,
          child: const BAHAlertoApp(),
        ),
      );
      expect(find.text('Skip intro'), findsOneWidget);
      await finishIntro(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AccountScreen), findsNothing);
      state.read(session.notifier).setUser(null);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    },
  );
  testWidgets('guest browsing is not remembered across app launches', (
    tester,
  ) async {
    final first = container();
    final second = container();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: first, child: const BAHAlertoApp()),
    );
    await finishIntro(tester);
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    // Sign-in from a guest visit must not retain guest access after sign-out.
    first.read(session.notifier).setUser(account);
    await tester.pumpAndSettle();
    first.read(session.notifier).setUser(null);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      UncontrolledProviderScope(container: second, child: const BAHAlertoApp()),
    );
    await finishIntro(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });
}
