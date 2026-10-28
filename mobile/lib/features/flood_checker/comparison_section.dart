import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/data.dart';
import '../../shared/widgets.dart';
import 'measurements.dart';

class ComparisonSection extends StatefulWidget {
  final double? depth;
  const ComparisonSection({super.key, required this.depth});
  @override
  State<ComparisonSection> createState() => _ComparisonSectionState();
}

class _ComparisonSectionState extends State<ComparisonSection> {
  double height = 165;
  String vehicle = 'Sedan';
  int section = 0;
  LengthUnit unit = LengthUnit.cm;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        children: [
          for (final u in LengthUnit.values)
            ChoiceChip(
              label: Text(switch (u) {
                LengthUnit.cm => 'cm',
                LengthUnit.inches => 'inches',
                LengthUnit.meters => 'meters',
              }),
              selected: unit == u,
              onSelected: (_) => setState(() => unit = u),
            ),
        ],
      ),
      const SizedBox(height: 12),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('Height comparison')),
          ButtonSegment(value: 1, label: Text('Vehicle assessment')),
        ],
        selected: {section},
        showSelectedIcon: false,
        onSelectionChanged: (value) => setState(() => section = value.first),
      ),
      const SizedBox(height: 16),
      if (section == 0)
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Human Height Comparison',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Adjust the virtual person. Demonstration only; never guidance to enter floodwater.',
              ),
              const SizedBox(height: 16),
              Semantics(
                label: widget.depth == null
                    ? 'No waterline: no recent flood data'
                    : 'Sample depth ${lengthLabel(widget.depth!, unit)} compared with person ${lengthLabel(height, unit)}',
                child: SizedBox(
                  height: 280,
                  child: CustomPaint(
                    painter: HumanWaterPainter(height, widget.depth, unit),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Person height: ${lengthLabel(height, unit)} (${feetAndInches(height)})',
              ),
              Slider(
                value: height,
                min: 120,
                max: 200,
                divisions: 80,
                label: lengthLabel(height, unit),
                onChanged: (value) => setState(() => height = value),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lengthLabel(120, unit)),
                  Text(lengthLabel(200, unit)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.depth == null
                    ? 'No Recent Flood Data. Numerical water comparison unavailable.'
                    : 'Example depth: ${lengthLabel(widget.depth!, unit)}. Approximately ${(comparisonRatio(widget.depth!, height) * 100).round()}% of the selected person height.',
              ),
              FilledButton(
                onPressed: () => setState(() => section = 1),
                child: const Text('Continue to Vehicle Assessment'),
              ),
            ],
          ),
        ),
      if (section == 1)
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vehicle Risk Assessment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Text(
                'Choose a vehicle category for general flood hazard guidance.',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in <(String, IconData)>[
                      ('Motorcycle', Icons.two_wheeler),
                      ('Sedan', Icons.directions_car),
                      ('SUV', Icons.airport_shuttle),
                      ('Truck', Icons.local_shipping),
                    ])
                      SizedBox(
                        width: (constraints.maxWidth - 8) / 2,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: vehicle == item.$1
                                ? const Color(0xFFEAF5EE)
                                : null,
                            side: BorderSide(
                              color: vehicle == item.$1
                                  ? primaryGreen
                                  : mutedText,
                            ),
                          ),
                          onPressed: () => setState(() => vehicle = item.$1),
                          child: Column(
                            children: [
                              Icon(item.$2),
                              Text(item.$1),
                              if (vehicle == item.$1)
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Selected vehicle: $vehicle'),
              Text(
                widget.depth == null
                    ? 'No Recent Flood Data'
                    : 'Sample depth: ${lengthLabel(widget.depth!, unit)}',
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.warning_amber, color: warningOrange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Flood hazard warning')),
                ],
              ),
              Text(assessment(vehicle, widget.depth)),
              Text(switch (vehicle) {
                'Motorcycle' =>
                  'Two wheels are vulnerable to loss of balance and traction.',
                'Sedan' =>
                  'Low components may be exposed to engine and electrical damage.',
                'SUV' =>
                  'Greater clearance does not establish wading capability or traction.',
                _ =>
                  'Size and weight do not protect against currents or hidden road damage.',
              }),
              const Text(
                'Hidden potholes, strong currents and electrical hazards can cause damage or loss of control. Individual vehicle limits vary. Avoid entering flooded roads.',
              ),
              OutlinedButton(
                onPressed: () => setState(() => section = 0),
                child: const Text('Back to Height Comparison'),
              ),
            ],
          ),
        ),
      const ExpansionTile(
        title: Text('Length converter'),
        children: [LengthConverter()],
      ),
    ],
  );
}

class LengthConverter extends StatefulWidget {
  const LengthConverter({super.key});
  @override
  State<LengthConverter> createState() => _LengthConverterState();
}

class _LengthConverterState extends State<LengthConverter> {
  LengthUnit inputUnit = LengthUnit.cm;
  String input = '';
  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(input);
    final valid =
        value != null && value.isFinite && value >= 0 && value <= 100000;
    final cm = valid ? toCentimeters(value, inputUnit) : null;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<LengthUnit>(
            initialValue: inputUnit,
            decoration: const InputDecoration(labelText: 'Input unit'),
            items: [
              for (final u in LengthUnit.values)
                DropdownMenuItem(value: u, child: Text(u.name)),
            ],
            onChanged: (value) => setState(() => inputUnit = value!),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Length to convert',
              errorText: input.isNotEmpty && !valid
                  ? 'Enter a finite number from 0 to 100000.'
                  : null,
            ),
            onChanged: (value) => setState(() => input = value),
          ),
          if (cm != null)
            Text(
              '${cm.toStringAsFixed(2)} cm = ${lengthLabel(cm, LengthUnit.inches)} = ${lengthLabel(cm, LengthUnit.meters)} (${feetAndInches(cm)})',
            ),
          const Text(
            'Conversion calculator only. Does not change the reported flood depth.',
          ),
        ],
      ),
    );
  }
}

class HumanWaterPainter extends CustomPainter {
  final double personHeight;
  final double? depth;
  final LengthUnit unit;
  HumanWaterPainter(this.personHeight, this.depth, this.unit);
  @override
  void paint(Canvas canvas, Size size) {
    final extent = comparisonExtent(depth);
    final ground = size.height - 24;
    final scale = (size.height - 48) / extent;
    final left = 42.0, right = size.width - 12;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = const Color(0xFFEDF5F7),
    );
    void text(String value, double x, double y, {Color color = mutedText}) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(fontSize: 10, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - x);
      painter.paint(canvas, Offset(x, y));
    }

    final step = extent > 300 ? (extent / 4 / 50).ceil() * 50.0 : 50.0;
    for (double mark = 0; mark <= extent; mark += step) {
      final y = ground - mark * scale;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()..color = const Color(0xFFBCD6E0),
      );
      text(lengthLabel(mark, unit), 3, y - 6);
    }
    final h = personHeight * scale;
    final x = (left + right) / 2;
    final top = ground - h;
    final body = Paint()
      ..color = primaryGreen
      ..strokeWidth = h * .16
      ..strokeCap = StrokeCap.round;
    final limbs = Paint()
      ..color = const Color(0xFFEBA675)
      ..strokeWidth = h * .055
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(x, top + h * .08),
      h * .08,
      Paint()..color = const Color(0xFFEBA675),
    );
    canvas.drawLine(Offset(x, top + h * .25), Offset(x, top + h * .55), body);
    for (final direction in [-1, 1]) {
      canvas.drawLine(
        Offset(x + direction * h * .065, top + h * .27),
        Offset(x + direction * h * .17, top + h * .6),
        limbs,
      );
      canvas.drawLine(
        Offset(x + direction * h * .055, top + h * .57),
        Offset(x + direction * h * .055, ground - h * .035),
        Paint()
          ..color = const Color(0xFF344A61)
          ..strokeWidth = h * .07
          ..strokeCap = StrokeCap.round,
      );
    }
    text(
      lengthLabel(personHeight, unit),
      math.max(left, x - 24),
      math.max(2, top - 16),
      color: ink,
    );
    if (depth != null) {
      final waterY = ground - depth! * scale;
      final wave = Path()..moveTo(left, waterY);
      for (double dx = left; dx <= right; dx += 2) {
        wave.lineTo(dx, waterY + math.sin((dx - left) / 12) * 2);
      }
      final fill = Path.from(wave)
        ..lineTo(right, ground)
        ..lineTo(left, ground)
        ..close();
      canvas.drawPath(fill, Paint()..color = Colors.blue.withValues(alpha: .3));
      canvas.drawPath(
        wave,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      text(
        'Water: ${lengthLabel(depth!, unit)}',
        left + 4,
        math.max(4, waterY - 17),
        color: Colors.blue.shade800,
      );
    }
    canvas.drawLine(
      Offset(left, ground),
      Offset(right, ground),
      Paint()
        ..color = mutedText
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant HumanWaterPainter oldDelegate) =>
      personHeight != oldDelegate.personHeight ||
      depth != oldDelegate.depth ||
      unit != oldDelegate.unit;
}
