import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../../shared/module_page.dart';
import '../../shared/road_map.dart';
import '../../shared/street_view.dart';
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
    final roads = ref.watch(roadsProvider);
    final records = roads.value ?? [];
    if (records.isEmpty && roads.isLoading) {
      return const ModulePage(
        title: 'Flood map',
        subtitle: 'Loading road locations...',
        children: [LinearProgressIndicator()],
      );
    }
    if (records.isEmpty && roads.hasError) {
      return ModulePage(
        title: 'Flood map',
        subtitle: backendError(roads.error!),
        children: [
          TextButton(
            onPressed: () => ref.invalidate(roadsProvider),
            child: const Text('Try again'),
          ),
        ],
      );
    }
    if (records.isEmpty) {
      return const ModulePage(
        title: 'Flood map',
        subtitle: 'No published roads available.',
        children: [],
      );
    }
    final selected = ref.watch(selectedRoadProvider);
    if (selected >= records.length) {
      return const Center(child: Text('Select a road again from Home.'));
    }
    return ModulePage(
      title: 'Flood map',
      subtitle: 'Explore roads with satellite imagery or street view.',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => ref.invalidate(roadsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh roads'),
          ),
        ),
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
              onTap: () {
                ref.read(selectedRoadProvider.notifier).select(i);
                FocusScope.of(context).unfocus();
              },
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
        const SizedBox(height: 16),
        const RoadSelector(),
        const SizedBox(height: 20),
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * 0.65).clamp(
            440.0,
            720.0,
          ),
          child: RoadMap(
            roads: records,
            selected: selected,
            onSelected: (index) =>
                ref.read(selectedRoadProvider.notifier).select(index),
          ),
        ),
        const SizedBox(height: 20),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                records[selected].road,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                records[selected].area,
                style: const TextStyle(color: mutedText),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => openStreetView(
                  context,
                  records[selected].latitude,
                  records[selected].longitude,
                ),
                icon: const Icon(Icons.streetview),
                label: const Text('Open Street View'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Satellite images show the area, not live flood conditions.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
