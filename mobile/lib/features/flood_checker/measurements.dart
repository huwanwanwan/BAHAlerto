enum LengthUnit { cm, inches, meters }

double fromCentimeters(double cm, LengthUnit unit) => switch (unit) {
  LengthUnit.cm => cm,
  LengthUnit.inches => cm / 2.54,
  LengthUnit.meters => cm / 100,
};
double toCentimeters(double value, LengthUnit unit) => switch (unit) {
  LengthUnit.cm => value,
  LengthUnit.inches => value * 2.54,
  LengthUnit.meters => value * 100,
};
String lengthLabel(double cm, LengthUnit unit) => switch (unit) {
  LengthUnit.cm => '${cm.toStringAsFixed(0)} cm',
  LengthUnit.inches => '${(cm / 2.54).toStringAsFixed(1)} in',
  LengthUnit.meters => '${(cm / 100).toStringAsFixed(2)} m',
};
String feetAndInches(double cm) {
  final inches = (cm / 2.54).round();
  return '${inches ~/ 12} ft ${inches % 12} in';
}

double comparisonExtent(double? depth) =>
    depth == null || depth < 200 ? 220 : depth * 1.1;
double comparisonRatio(double depth, double personHeight) =>
    depth / personHeight;
