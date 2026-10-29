import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data.dart';
import 'flood_repository.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

String backendUrl = const String.fromEnvironment('SUPABASE_URL');
String backendKey = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
bool get backendConfigured => backendUrl.isNotEmpty && backendKey.isNotEmpty;
Future<void> loadBackendConfiguration() async {
  if (backendConfigured) return;
  try {
    final config =
        jsonDecode(await rootBundle.loadString('assets/backend.local.json'))
            as Map;
    backendUrl = config['SUPABASE_URL'] as String;
    backendKey = config['SUPABASE_PUBLISHABLE_KEY'] as String;
  } on Exception {
    /* Launch without credentials shows setup guidance. */
  }
}

void refreshPeriodically(Ref ref) {
  final timer = Timer.periodic(
    const Duration(seconds: 60),
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(timer.cancel);
}

final clientProvider = Provider<SupabaseClient>((ref) {
  if (!backendConfigured) throw StateError('Backend configuration is missing.');
  return Supabase.instance.client;
});
final floodRepositoryProvider = Provider<FloodRepository>(
  (ref) => SupabaseFloodRepository(ref.watch(clientProvider)),
);
final authProvider = StreamProvider<AuthState>((ref) {
  if (!backendConfigured) return const Stream.empty();
  return ref.watch(clientProvider).auth.onAuthStateChange;
});
final userProvider = Provider<User?>((ref) {
  ref.watch(authProvider);
  return backendConfigured ? ref.watch(clientProvider).auth.currentUser : null;
});
final roadsProvider = FutureProvider<List<FloodRecord>>((ref) async {
  final db = ref.watch(clientProvider);
  final roads = <Map<String, dynamic>>[];
  // Page the public road directory rather than silently stopping at 1,000 rows.
  for (var start = 0; ; start += 500) {
    final page = await db
        .from('road_locations')
        .select()
        .eq('published', true)
        .order('id')
        .range(start, start + 499);
    roads.addAll(page);
    if (page.length < 500) break;
  }
  return [
    for (final r in roads)
      FloodRecord(
        r['name'] as String,
        r['locality'] as String? ?? '',
        null,
        Evidence.estimated,
        'Open Check Flood for the latest published observation.',
        id: r['id'] as String,
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        sourceName: 'Current depth not loaded',
      ),
  ];
});
final myReportsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  refreshPeriodically(ref);
  return ref
      .watch(clientProvider)
      .from('flood_reports')
      .select(
        'id,road_id,depth_cm,description,status,review_reason,observed_at,created_at',
      )
      .eq('owner_id', user.id)
      .order('created_at', ascending: false)
      .limit(100);
});
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref
      .watch(clientProvider)
      .from('profiles')
      .select('full_name,status')
      .eq('id', user.id)
      .single();
});
final savedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ref
      .watch(clientProvider)
      .from('saved_locations')
      .select('id,road_id,notify')
      .eq('owner_id', user.id)
      .order('created_at', ascending: false);
});
final preferencesProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref
      .watch(clientProvider)
      .from('notification_preferences')
      .select('personalized_alerts,language')
      .eq('owner_id', user.id)
      .maybeSingle();
});
final directoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      table,
    ) async {
      final db = ref.watch(clientProvider);
      if (table == 'flood_alerts') {
        final now = DateTime.now().toUtc();
        final rows = await db
            .from(table)
            .select()
            .eq('status', 'published')
            .lte('published_at', now.toIso8601String())
            .gt('expires_at', now.toIso8601String())
            .order('published_at', ascending: false)
            .limit(100);
        if (rows.isNotEmpty) {
          final expiry = rows
              .map((r) => DateTime.parse(r['expires_at'] as String))
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final delay = expiry.difference(DateTime.now().toUtc());
          final timer = Timer(
            delay.isNegative ? Duration.zero : delay,
            ref.invalidateSelf,
          );
          ref.onDispose(timer.cancel);
        }
        return rows;
      }
      if (!['emergency_contacts', 'evacuation_centers'].contains(table)) {
        throw ArgumentError('Unknown directory');
      }
      return db
          .from(table)
          .select()
          .eq('published', true)
          .eq('archived', false)
          .order('created_at', ascending: false)
          .limit(100);
    });
String backendError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException && error.code == '42501') {
    return 'Access denied. Your account may be suspended or lack permission.';
  }
  return 'Could not connect or save. Check your connection and try again.';
}
