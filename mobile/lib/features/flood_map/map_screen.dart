import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../flood_checker/checker_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onReport;
  const MapScreen({super.key, this.onReport});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final records = ref.watch(roadsProvider).asData?.value ?? [];
    if (records.isEmpty) {
      return const PageBody(
        title: 'Explore locations',
        subtitle: 'No published roads available.',
        children: [],
      );
    }
    final selected = ref.watch(selectedRoadProvider);
    if (selected >= records.length) {
      return const Center(child: Text('Select a road again from Home.'));
    }
    return PageBody(
      title: 'Explore locations',
      subtitle: 'Map preview • Illustrative layout, not geographic navigation.',
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search road or location',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        for (var i = 0; i < records.length; i++)
          if (query.isNotEmpty &&
              '${records[i].road} ${records[i].area}'.toLowerCase().contains(
                query.toLowerCase(),
              ))
            ListTile(
              title: Text(records[i].road),
              subtitle: Text(records[i].area),
              onTap: () => ref.read(selectedRoadProvider.notifier).select(i),
            ),
        if (query.isNotEmpty &&
            !records.any(
              (r) => '${r.road} ${r.area}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
            ))
          const Text(
            'No matching published locations. No flood information is available for this search.',
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.my_location),
          label: const Text('My GPS Location'),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'GPS is not connected to this illustrative layout. No location permission has been requested.',
              ),
            ),
          ),
        ),
        const RoadSelector(),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: const Color(0xFFEAF5EE),
              child: Stack(
                children: [
                  const Positioned(
                    left: 80,
                    top: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: Color(0xFFBDE2C6),
                      child: SizedBox(width: 65),
                    ),
                  ),
                  const Center(
                    child: Divider(thickness: 24, color: Colors.white),
                  ),
                  const Center(
                    child: VerticalDivider(thickness: 18, color: Colors.white),
                  ),
                  for (var i = 0; i < records.length; i++)
                    Positioned(
                      left: 25 + (i % 2) * 155,
                      top: 35 + (i ~/ 2) * 145,
                      child: IconButton.filled(
                        tooltip: records[i].road,
                        onPressed: () =>
                            ref.read(selectedRoadProvider.notifier).select(i),
                        icon: Icon(
                          ref.watch(selectedRoadProvider) == i
                              ? Icons.where_to_vote
                              : Icons.location_on,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                records[selected].road,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(records[selected].source),
              Text(
                records[selected].depth == null
                    ? 'No current depth available'
                    : '${records[selected].depth!.round()} cm',
              ),
              Text(records[selected].description),
              const Text(
                'Open Check Flood to load the current observation. Missing reports do not indicate safety.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    openChecker(context, onReport: widget.onReport),
                icon: const Icon(Icons.water),
                label: const Text('Check Flood'),
              ),
              const Text(
                'Road positions in this layout are illustrative. Geographic navigation is not available.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
