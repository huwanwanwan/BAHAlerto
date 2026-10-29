import 'package:supabase_flutter/supabase_flutter.dart';
import 'data.dart';

abstract class FloodRepository {
  Future<FloodRecord> roadObservation(String roadId);
}

class SupabaseFloodRepository implements FloodRepository {
  final SupabaseClient db;
  SupabaseFloodRepository(this.db);
  @override
  Future<FloodRecord> roadObservation(String roadId) async {
    final road = await db
        .from('road_locations')
        .select()
        .eq('id', roadId)
        .eq('published', true)
        .single();
    final rows = await db.rpc(
      'latest_road_observation',
      params: {'selected_road': roadId},
    );
    final observation = (rows as List).isEmpty ? null : rows.first as Map;
    return parseObservation(road, observation, DateTime.now().toUtc());
  }
}

FloodRecord parseObservation(Map road, Map? observation, DateTime now) {
  final observed = DateTime.tryParse(observation?['observed_at'] ?? '');
  final until = DateTime.tryParse(observation?['valid_until'] ?? '');
  final current =
      observation != null &&
      observation['published'] == true &&
      observation['archived'] == false &&
      observation['verification_status'] == 'verified' &&
      observation['evidence'] == 'observation' &&
      observed != null &&
      until != null &&
      !observed.isAfter(now) &&
      until.isAfter(now);
  final kind = observation?['measurement_kind'];
  return FloodRecord(
    road['name'] as String,
    road['locality'] as String? ?? '',
    current ? (observation['depth_cm'] as num?)?.toDouble() : null,
    kind == 'community_estimate' ? Evidence.community : Evidence.verified,
    current
        ? (observation['notes'] as String? ?? 'Published verified observation.')
        : 'No current verified observation is available. This does not indicate safe passage.',
    id: road['id'] as String,
    latitude: (road['latitude'] as num).toDouble(),
    longitude: (road['longitude'] as num).toDouble(),
    observedAt: current ? observed : null,
    validUntil: current ? until : null,
    sourceName: current
        ? '${observation['source']} (${kind ?? 'unknown'})'
        : 'No current verified observation',
  );
}
