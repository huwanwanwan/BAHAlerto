import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bahalerto/core/backend.dart';
import 'package:bahalerto/features/settings/settings_screen.dart';
import 'package:bahalerto/features/reports/reports_screen.dart';
import 'fixtures.dart';

Future<SupabaseClient> makeClient(
  WidgetTester tester,
  MockClient httpClient,
) async => (await tester.runAsync(() async {
  final db = SupabaseClient(
    backendUrl,
    backendKey,
    httpClient: httpClient,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return db;
}))!;
Future<void> finishRequest(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    backendUrl = 'https://test.supabase.co';
    backendKey = 'test-public';
  });
  tearDown(() {
    backendUrl = '';
    backendKey = '';
  });
  testWidgets(
    'registration sends profile metadata and waits for email confirmation',
    (tester) async {
      Map<String, dynamic>? sent;
      final db = await makeClient(
        tester,
        MockClient((request) async {
          expect(request.url.path, '/auth/v1/signup');
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'test-user',
              'aud': 'authenticated',
              'email': 'user@example.test',
              'created_at': '2026-10-29T00:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(() => tester.runAsync(db.dispose));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientProvider.overrideWithValue(db)],
          child: const MaterialApp(home: AccountScreen(register: true)),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test Person');
      await tester.enterText(fields.at(1), 'user@example.test');
      await tester.enterText(fields.at(2), 'test-password-123');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Register'));
      await tester.runAsync(
        () => tester.tap(find.widgetWithText(FilledButton, 'Register')),
      );
      await finishRequest(tester);
      await tester.pumpAndSettle();
      expect(
        sent,
        isNotNull,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join('|'),
      );
      expect(sent?['data'], {'full_name': 'Test Person'});
      expect(sent?.containsKey('permissions'), false);
      expect(find.textContaining('Check your email'), findsOneWidget);
    },
  );
  testWidgets(
    'unconfirmed email error is visible without treating user as signed in',
    (tester) async {
      final db = await makeClient(
        tester,
        MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': 'email_not_confirmed',
              'msg': 'Email not confirmed',
            }),
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(() => tester.runAsync(db.dispose));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientProvider.overrideWithValue(db)],
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test-password-123',
      );
      await tester.runAsync(
        () => tester.tap(find.widgetWithText(FilledButton, 'Log In')),
      );
      await finishRequest(tester);
      await tester.pumpAndSettle();
      expect(find.text('Email not confirmed'), findsOneWidget);
      expect(db.auth.currentUser, isNull);
    },
  );
  testWidgets(
    'startup login calls its completion action after authentication',
    (tester) async {
      final header = base64Url
          .encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'))
          .replaceAll('=', '');
      final payload = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'sub': 'test-user',
                'exp':
                    DateTime.now()
                        .add(const Duration(hours: 1))
                        .millisecondsSinceEpoch ~/
                    1000,
              }),
            ),
          )
          .replaceAll('=', '');
      final db = await makeClient(
        tester,
        MockClient(
          (request) async => http.Response(
            jsonEncode({
              'access_token': '$header.$payload.test',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': 'test-user',
                'aud': 'authenticated',
                'email': 'user@example.test',
                'created_at': '2026-10-29T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      addTearDown(() => tester.runAsync(db.dispose));
      var entered = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: AccountScreen(onAuthenticated: () => entered = true),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test-password-123',
      );
      await tester.runAsync(
        () => tester.tap(find.widgetWithText(FilledButton, 'Log In')),
      );
      await finishRequest(tester);
      expect(entered, true);
      expect(db.auth.currentUser?.id, 'test-user');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'signed-in report sends shared road and owner IDs without moderation fields',
    (tester) async {
      Map<String, dynamic>? sent;
      final db = await makeClient(
        tester,
        MockClient((request) async {
          expect(request.url.path, '/rest/v1/flood_reports');
          expect(request.method, 'POST');
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 201, request: request);
        }),
      );
      addTearDown(() => tester.runAsync(db.dispose));
      const user = User(
        id: 'test-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-10-29T00:00:00Z',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientProvider.overrideWithValue(db),
            userProvider.overrideWithValue(user),
            roadsProvider.overrideWith((ref) async => fixtureRoads),
            myReportsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: Scaffold(body: ReportsScreen())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '25');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Water covering the road surface.',
      );
      await tester.ensureVisible(find.text('Select observation date and time'));
      await tester.tap(find.text('Select observation date and time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Submit Report'));
      await tester.runAsync(() => tester.tap(find.text('Submit Report')));
      await finishRequest(tester);
      await tester.pumpAndSettle();
      expect(sent?['owner_id'], user.id);
      expect(sent?['road_id'], 'road-one');
      expect(sent?['depth_cm'], 25);
      expect(sent?.containsKey('status'), false);
      expect(sent?.containsKey('reviewed_by'), false);
      expect(sent?.containsKey('created_at'), false);
      expect(
        find.textContaining('Report submitted.'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join('|'),
      );
    },
  );
}
