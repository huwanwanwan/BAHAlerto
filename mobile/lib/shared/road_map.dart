import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/data.dart';
import 'street_view.dart';

class RoadMap extends StatefulWidget {
  final List<FloodRecord> roads;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool fullscreen;
  const RoadMap({
    super.key,
    required this.roads,
    required this.selected,
    required this.onSelected,
    this.fullscreen = false,
  });
  @override
  State<RoadMap> createState() => _RoadMapState();
}

class _RoadMapState extends State<RoadMap> {
  final controller = MapController();
  bool satellite = true;
  bool ready = false;
  LatLng get selectedPoint => LatLng(
    widget.roads[widget.selected].latitude,
    widget.roads[widget.selected].longitude,
  );
  @override
  void didUpdateWidget(covariant RoadMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ready &&
        (oldWidget.selected != widget.selected ||
            oldWidget.roads[oldWidget.selected].id !=
                widget.roads[widget.selected].id)) {
      controller.move(selectedPoint, 16);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget tiles(String service) => TileLayer(
    key: ValueKey(service),
    urlTemplate:
        'https://services.arcgisonline.com/ArcGIS/rest/services/$service/MapServer/tile/{z}/{y}/{x}',
    userAgentPackageName: 'com.bahalerto.mobile',
    maxNativeZoom: 19,
  );
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 18),
    child: Stack(
      children: [
        FlutterMap(
          mapController: controller,
          options: MapOptions(
            initialCenter: selectedPoint,
            initialZoom: 15,
            minZoom: 5,
            maxZoom: 19,
            onMapReady: () => ready = true,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            if (satellite) ...[
              tiles('World_Imagery'),
              tiles('Reference/World_Transportation'),
              tiles('Reference/World_Boundaries_and_Places'),
            ] else
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bahalerto.mobile',
                maxNativeZoom: 19,
              ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < widget.roads.length; i++)
                  Marker(
                    point: LatLng(
                      widget.roads[i].latitude,
                      widget.roads[i].longitude,
                    ),
                    width: 44,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: IconButton(
                      tooltip: widget.roads[i].road,
                      onPressed: () => widget.onSelected(i),
                      icon: Icon(
                        Icons.location_on,
                        size: i == widget.selected ? 40 : 30,
                        color: i == widget.selected
                            ? const Color(0xFF078443)
                            : const Color(0xFFD88A20),
                        shadows: const [
                          Shadow(color: Colors.white, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: ToggleButtons(
              borderRadius: BorderRadius.circular(10),
              constraints: const BoxConstraints(minWidth: 75, minHeight: 40),
              isSelected: [satellite, !satellite],
              onPressed: (index) => setState(() => satellite = index == 0),
              children: const [Text('Satellite'), Text('Streets')],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 10,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            elevation: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: () => controller.move(
                    controller.camera.center,
                    (controller.camera.zoom + 1).clamp(5, 19),
                  ),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: () => controller.move(
                    controller.camera.center,
                    (controller.camera.zoom - 1).clamp(5, 19),
                  ),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: 'Center selected road',
                  onPressed: () => controller.move(selectedPoint, 16),
                  icon: const Icon(Icons.my_location),
                ),
                IconButton(
                  tooltip: 'Open Street View',
                  icon: const Icon(Icons.streetview),
                  onPressed: () => openStreetView(
                    context,
                    selectedPoint.latitude,
                    selectedPoint.longitude,
                  ),
                ),
                if (!widget.fullscreen)
                  IconButton(
                    tooltip: 'Expand map',
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      var selected = widget.selected;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatefulBuilder(
                            builder: (context, update) => Scaffold(
                              appBar: AppBar(title: const Text('Flood map')),
                              body: SafeArea(
                                child: RoadMap(
                                  roads: widget.roads,
                                  selected: selected,
                                  fullscreen: true,
                                  onSelected: (index) {
                                    update(() => selected = index);
                                    widget.onSelected(index);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ColoredBox(
            color: const Color(0xEFFFFFFF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                satellite
                    ? 'Imagery: Esri, Vantor, Earthstar Geographics, GIS User Community\nRoads: Esri, HERE, Garmin, © OpenStreetMap contributors'
                    : '© OpenStreetMap contributors',
                style: const TextStyle(fontSize: 9, color: Color(0xFF304D3C)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
