import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../core/backend.dart';
import '../settings/settings_screen.dart';
import '../../shared/widgets.dart';
import 'comparison_section.dart';
import 'measurements.dart';
import '../../core/flood_repository.dart';

class RoadSelector extends ConsumerWidget {
  const RoadSelector({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(roadsProvider).asData?.value ?? [];
    final selected = ref.watch(selectedRoadProvider);
    return DropdownButtonFormField<int>(
      initialValue: selected < records.length ? selected : null,
      key: ValueKey('$selected-${records.length}'),
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Road location'),
      items: [
        for (var i = 0; i < records.length; i++)
          DropdownMenuItem(value: i, child: Text(records[i].road)),
      ],
      onChanged: (i) {
        if (i != null) ref.read(selectedRoadProvider.notifier).select(i);
      },
    );
  }
}

void openChecker(BuildContext context, {VoidCallback? onReport}) {
  final container = ProviderScope.containerOf(context);
  final records = container.read(roadsProvider).asData?.value ?? [];
  final selected = container.read(selectedRoadProvider);
  if (records.isEmpty || selected >= records.length) return;
  final roadId = records[selected].id;
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

class CheckerScreen extends ConsumerStatefulWidget {
  final String roadId;
  final VoidCallback? onReport;
  final FloodRepository? repository;
  const CheckerScreen({
    super.key,
    required this.roadId,
    this.onReport,
    this.repository,
  });
  @override
  ConsumerState<CheckerScreen> createState() => _CheckerScreenState();
}

class _CheckerScreenState extends ConsumerState<CheckerScreen> {
  late Future<FloodRecord> observation;
  Timer? expiryTimer;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    final repository =
        widget.repository ?? ref.read<FloodRepository>(floodRepositoryProvider);
    observation = repository.roadObservation(widget.roadId).then((record) {
      expiryTimer?.cancel();
      if (mounted && record.validUntil != null) {
        final delay = record.validUntil!.difference(DateTime.now().toUtc());
        expiryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
          if (mounted) setState(load);
        });
      }
      return record;
    });
  }

  @override
  void dispose() {
    expiryTimer?.cancel();
    super.dispose();
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
        subtitle:
            'Latest published verified observation. Refresh to check for updates.',
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
                      : 'Observed water depth • Flooding indicated',
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
                Text(
                  record.observedAt == null
                      ? 'No current observation time.'
                      : 'Observed: ${record.observedAt!.toLocal()}\nValid until: ${record.validUntil!.toLocal()}',
                  style: const TextStyle(fontSize: 12, color: mutedText),
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
                subtitle: Text(
                  record.observedAt == null
                      ? 'No current observation.'
                      : 'Observed: ${record.observedAt!.toLocal()}',
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
            onPressed: () => setState(load),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh observation'),
          ),
          Consumer(
            builder: (context, ref, _) => OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save location'),
              onPressed: () async {
                final user = ref.read(userProvider);
                if (user == null) {
                  await showAccount(context);
                  return;
                }
                try {
                  await ref.read(clientProvider).from('saved_locations').insert(
                    {'owner_id': user.id, 'road_id': widget.roadId},
                  );
                  ref.invalidate(savedProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location saved.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e is PostgrestException && e.code == '23505'
                              ? 'Location already saved.'
                              : backendError(e),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      );
    },
  );
}
