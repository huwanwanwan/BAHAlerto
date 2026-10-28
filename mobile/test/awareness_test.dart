import 'package:flutter_test/flutter_test.dart';
import 'package:bahalerto/core/data.dart';

void main() {
  test('Missing depth never establishes passage for any vehicle', () {
    for (final v in ['Motorcycle', 'Sedan', 'SUV', 'Truck']) {
      expect(assessment(v, null), contains('cannot be assessed'));
      expect(assessment(v, 15), contains('Avoid entering floodwater'));
      expect(assessment(v, 50), contains('does not establish safe passage'));
    }
  });
  test('Historical hazard has no fabricated current depth', () {
    expect(
      records
          .where((r) => r.evidence == Evidence.historical)
          .every((r) => r.depth == null),
      isTrue,
    );
  });
}
