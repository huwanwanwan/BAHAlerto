import 'package:flutter_test/flutter_test.dart';
import 'package:bahalerto/shared/street_view.dart';

void main() {
  test('Street View link uses the selected geographic coordinates', () {
    final uri = streetViewUri(14.7578, 120.9572);
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/@');
    expect(uri.queryParameters, {
      'api': '1',
      'map_action': 'pano',
      'viewpoint': '14.7578,120.9572',
    });
  });
  test('invalid coordinates do not generate a Street View link', () {
    expect(() => streetViewUri(double.nan, 120), throwsArgumentError);
    expect(() => streetViewUri(91, 120), throwsArgumentError);
    expect(() => streetViewUri(14, 181), throwsArgumentError);
  });
}
