import 'data.dart';

/// Replace this adapter with Supabase queries after schema review and configuration.
abstract class FloodRepository {
  Future<FloodRecord> roadObservation(int roadId);
}

class DemoFloodRepository implements FloodRepository {
  @override
  Future<FloodRecord> roadObservation(int roadId) async {
    if (roadId < 0 || roadId >= records.length) {
      throw ArgumentError('Unknown demonstration road');
    }
    return records[roadId];
  }
}
