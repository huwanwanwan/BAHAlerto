import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Evidence { verified, community, historical, estimated }

class FloodRecord {
  final String road, area, description;
  final double? depth;
  final Evidence evidence;
  const FloodRecord(
    this.road,
    this.area,
    this.depth,
    this.evidence,
    this.description,
  );
  String get source => switch (evidence) {
    Evidence.verified => 'Verified observation (sample)',
    Evidence.community => 'Community report • Unverified',
    Evidence.historical => 'Historical hazard • No current depth',
    Evidence.estimated => 'Estimated level • Unverified',
  };
}

const sampleTime = '15 Jun 2026, 2:30 PM PHT';
const records = [
  FloodRecord(
    'España Boulevard',
    'Sampaloc, Manila',
    30,
    Evidence.community,
    'Sample report of water covering parts of the road.',
  ),
  FloodRecord(
    'Taft Avenue',
    'Malate, Manila',
    15,
    Evidence.verified,
    'Fictional reviewed observation for interface testing.',
  ),
  FloodRecord(
    'Marikina Riverbanks',
    'Marikina City',
    null,
    Evidence.historical,
    'Illustrative historical hazard; this is not a current flood observation.',
  ),
  FloodRecord(
    'Aurora Boulevard',
    'Quezon City',
    20,
    Evidence.estimated,
    'Illustrative estimate without a live data provider.',
  ),
];

final selectedRoadProvider = NotifierProvider<SelectedRoad, int>(
  SelectedRoad.new,
);

class SelectedRoad extends Notifier<int> {
  @override
  int build() => 0;
  void select(int value) => state = value;
}

final reportsProvider = NotifierProvider<Reports, List<String>>(Reports.new);

class Reports extends Notifier<List<String>> {
  @override
  List<String> build() => [];
  void add(String report) => state = [report, ...state];
}

String assessment(String vehicle, double? depth) {
  if (depth == null) {
    return 'No current depth available. Risk cannot be assessed.';
  }
  return '$vehicle: ${depth >= 30 ? "High flood exposure" : "Flood exposure detected"}. Avoid entering floodwater. Depth, currents, hidden damage and vehicle limits are uncertain. Higher clearance does not establish safe passage.';
}
