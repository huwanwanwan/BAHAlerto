import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../shared/widgets.dart';
import 'comparison_section.dart';
import 'measurements.dart';
import '../../core/flood_repository.dart';

class RoadSelector extends ConsumerWidget {
  const RoadSelector({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      DropdownButtonFormField<int>(
        initialValue: ref.watch(selectedRoadProvider),
        key: ValueKey(ref.watch(selectedRoadProvider)),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Sample location'),
        items: [
          for (var i = 0; i < records.length; i++)
            DropdownMenuItem(value: i, child: Text(records[i].road)),
        ],
        onChanged: (i) {
          if (i != null) ref.read(selectedRoadProvider.notifier).select(i);
        },
      );
}

void openChecker(BuildContext context, {VoidCallback? onReport}) {
  final roadId = ProviderScope.containerOf(context).read(selectedRoadProvider);
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Check Flood')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CheckerScreen(
              roadId: roadId,
              onReport: () {
                Navigator.pop(context);
                onReport?.call();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class CheckerScreen extends StatefulWidget {
  final int roadId;
  final VoidCallback? onReport;
  final FloodRepository? repository;
  const CheckerScreen({
    super.key,
    required this.roadId,
    this.onReport,
    this.repository,
  });
  @override
  State<CheckerScreen> createState() => _CheckerScreenState();
}

class _CheckerScreenState extends State<CheckerScreen> {
  late Future<FloodRecord> observation;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    observation = (widget.repository ?? DemoFloodRepository()).roadObservation(
      widget.roadId,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FloodRecord>(
    future: observation,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Flood information could not be loaded. No assessment is available.',
              ),
              TextButton(
                onPressed: () => setState(load),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      final record = snapshot.data!;
      return PageBody(
        title: record.road,
        subtitle: 'DEMO MODE - Sample data only. Not live flood information.',
        children: [
          const SizedBox(height: 20),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(record.source),
                const SizedBox(height: 24),
                Text(
                  record.depth == null
                      ? 'No Recent Flood Data'
                      : '${record.depth!.toInt()} cm',
                  style: TextStyle(
                    fontSize: record.depth == null ? 24 : 42,
                    fontWeight: FontWeight.w800,
                    color: primaryGreen,
                  ),
                ),
                if (record.depth != null)
                  Text(
                    '${lengthLabel(record.depth!, LengthUnit.inches)} / ${lengthLabel(record.depth!, LengthUnit.meters)}',
                  ),
                Text(
                  record.depth == null
                      ? 'No current observation'
                      : 'Sample water depth • Flooding indicated',
                ),
                const SizedBox(height: 20),
                Text(
                  record.road,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(record.area),
                const Divider(height: 32),
                Text(record.description),
                const SizedBox(height: 14),
                const Text(
                  'Sample observation time: $sampleTime\nStale fixture — not current conditions.',
                  style: TextStyle(fontSize: 12, color: mutedText),
                ),
              ],
            ),
          ),
          const InfoCard(
            child: Text(
              'Avoid flooded roads. Water depth alone cannot determine road passability. Never treat missing data as an indication of safety.',
            ),
          ),
          ComparisonSection(depth: record.depth),
          ExpansionTile(
            title: const Text('View data source'),
            children: [
              ListTile(
                title: Text(record.source),
                subtitle: const Text(
                  'Fixed demonstration fixture. No live provider connected. $sampleTime',
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: widget.onReport,
            icon: const Icon(Icons.edit_location_alt),
            label: const Text('Report Flood Here'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Report incorrect data'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Demonstration data'),
                content: const Text(
                  'These fixtures are not live observations. Corrections cannot be sent until the reporting backend is connected.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
