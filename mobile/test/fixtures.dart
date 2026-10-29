import 'package:bahalerto/core/data.dart';
import 'package:bahalerto/core/flood_repository.dart';

const fixtureRoads = [
  FloodRecord(
    'Test Road One',
    'Test City',
    30,
    Evidence.community,
    'Test observation',
    id: 'road-one',
  ),
  FloodRecord(
    'Taft Avenue',
    'Test City',
    15,
    Evidence.verified,
    'Test observation',
    id: 'road-two',
  ),
  FloodRecord(
    'Historical test road',
    'Test City',
    null,
    Evidence.historical,
    'No current depth',
    id: 'road-three',
  ),
];

class FixtureRepository implements FloodRepository {
  @override
  Future<FloodRecord> roadObservation(String roadId) async =>
      fixtureRoads.firstWhere((r) => r.id == roadId);
}
