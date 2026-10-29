import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Evidence { verified, community, historical, estimated }

class FloodRecord {
  final String road, area, description;
  final String id;
  final double latitude, longitude;
  final DateTime? observedAt, validUntil;
  final String? sourceName;
  final double? depth;
  final Evidence evidence;
  const FloodRecord(
    this.road,
    this.area,
    this.depth,
    this.evidence,
    this.description, {
    this.id = '',
    this.latitude = 0,
    this.longitude = 0,
    this.observedAt,
    this.validUntil,
    this.sourceName,
  });
  String get source =>
      sourceName ??
      switch (evidence) {
        Evidence.verified => 'Verified observation',
        Evidence.community => 'Community report • Unverified',
        Evidence.historical => 'Historical hazard • No current depth',
        Evidence.estimated => 'Estimated level • Unverified',
      };
}

final selectedRoadProvider = NotifierProvider<SelectedRoad, int>(
  SelectedRoad.new,
);

class SelectedRoad extends Notifier<int> {
  @override
  int build() => 0;
  void select(int value) => state = value;
}

String assessment(String vehicle, double? depth) {
  if (depth == null) {
    return 'No current depth available. Risk cannot be assessed.';
  }
  return '$vehicle: ${depth >= 30 ? "High flood exposure" : "Flood exposure detected"}. Avoid entering floodwater. Depth, currents, hidden damage and vehicle limits are uncertain. Higher clearance does not establish safe passage.';
}
