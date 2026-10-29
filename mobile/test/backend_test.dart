import 'package:flutter_test/flutter_test.dart';
import 'package:bahalerto/core/flood_repository.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29, 5);
  final road = {
    'id': 'road-id',
    'name': 'Test road',
    'locality': 'Test area',
    'latitude': 14.0,
    'longitude': 120.0,
  };
  Map<String, dynamic> current() => {
    'depth_cm': 25,
    'published': true,
    'archived': false,
    'verification_status': 'verified',
    'evidence': 'observation',
    'measurement_kind': 'community_estimate',
    'source': 'Reviewed report',
    'observed_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
    'valid_until': now.add(const Duration(minutes: 5)).toIso8601String(),
  };
  test('a verified estimate preserves its source and measurement method', () {
    final value = parseObservation(road, current(), now);
    expect(value.id, 'road-id');
    expect(value.depth, 25);
    expect(value.source, contains('community_estimate'));
    expect(value.observedAt, isNotNull);
  });
  test(
    'expired, future, unpublished and historical rows never become current depth',
    () {
      for (final change in [
        {'valid_until': now.toIso8601String()},
        {'observed_at': now.add(const Duration(minutes: 1)).toIso8601String()},
        {'published': false},
        {'archived': true},
        {'verification_status': 'pending'},
        {'evidence': 'historical'},
      ]) {
        final value = parseObservation(road, {...current(), ...change}, now);
        expect(value.depth, isNull);
        expect(value.observedAt, isNull);
      }
      expect(parseObservation(road, null, now).depth, isNull);
    },
  );
}
