import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../flood_checker/checker_screen.dart';

class VehicleScreen extends ConsumerStatefulWidget {
  const VehicleScreen({super.key});
  @override
  ConsumerState<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends ConsumerState<VehicleScreen> {
  String vehicle = 'Sedan';
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Understand your exposure',
    subtitle: 'An awareness guide, never clearance to cross.',
    children: [
      const RoadSelector(),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        initialValue: vehicle,
        decoration: const InputDecoration(labelText: 'Vehicle type'),
        items: [
          for (final v in ['Motorcycle', 'Sedan', 'SUV', 'Truck'])
            DropdownMenuItem(value: v, child: Text(v)),
        ],
        onChanged: (v) => setState(() => vehicle = v!),
      ),
      const SizedBox(height: 20),
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: warningOrange,
              size: 36,
            ),
            const SizedBox(height: 14),
            Text(
              assessment(
                vehicle,
                (ref.watch(roadsProvider).asData?.value ?? [])
                    .elementAtOrNull(ref.watch(selectedRoadProvider))
                    ?.depth,
              ),
              style: const TextStyle(height: 1.7),
            ),
            const SizedBox(height: 12),
            const Tag('Flood assessment • No safe-to-cross rating'),
          ],
        ),
      ),
    ],
  );
}
