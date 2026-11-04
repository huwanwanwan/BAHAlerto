import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bahalerto/shared/road_map.dart';
import 'fixtures.dart';

void main() {
  testWidgets(
    'map switches imagery without losing its geographic camera and opens fullscreen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 500,
              child: RoadMap(
                roads: fixtureRoads,
                selected: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widgetList<TileLayer>(find.byType(TileLayer)).length, 3);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final center = map.mapController!.camera.center;
      await tester.tap(find.text('Streets'));
      await tester.pumpAndSettle();
      final tiles = tester
          .widgetList<TileLayer>(find.byType(TileLayer))
          .toList();
      expect(tiles.length, 1);
      expect(tiles.single.urlTemplate, contains('tile.openstreetmap.org'));
      expect(map.mapController!.camera.center, center);
      await tester.tap(find.byTooltip('Expand map'));
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Flood map'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
