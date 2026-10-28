import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data.dart';
import '../../shared/widgets.dart';
import '../evacuation/evacuation_screen.dart';
import '../alerts/alerts_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Be aware. Travel prepared.',
    subtitle: 'Flood awareness for your everyday journey.',
    children: [
      const Text('Welcome to BAHAlerto, Guest.'),
      Wrap(
        spacing: 8,
        children: [
          ActionChip(
            label: const Text('View Flood Map'),
            onPressed: () => widget.onNavigate(1),
          ),
          ActionChip(
            label: const Text('Evacuation Centers'),
            onPressed: () => openInfo(
              context,
              'Evacuation Centers',
              const EvacuationScreen(),
            ),
          ),
          ActionChip(
            label: const Text('Emergency Contacts'),
            onPressed: () => openInfo(
              context,
              'Emergency Contacts',
              const PageBody(
                title: 'Emergency contacts',
                subtitle: 'Verified directory not yet connected.',
                children: [
                  InfoCard(
                    child: Text(
                      'No verified local hotlines are available in this demonstration. Contact your local emergency authorities through their official channels.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          ActionChip(
            label: const Text('Flood advisories'),
            onPressed: () =>
                openInfo(context, 'Flood advisories', const AlertsScreen()),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search a road or city',
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [ink, primaryGreen]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.waves, size: 38, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Know the water.\nUnderstand the risk.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore sample flood reports and check road conditions before you go.',
              style: TextStyle(color: Colors.white, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: () => widget.onNavigate(2),
              child: const Text('Check flood conditions  →'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Sample road observations',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 14),
      for (var i = 0; i < records.length; i++)
        if ('${records[i].road} ${records[i].area}'.toLowerCase().contains(
          query.toLowerCase(),
        ))
          InfoCard(
            child: InkWell(
              onTap: () {
                ref.read(selectedRoadProvider.notifier).select(i);
                widget.onNavigate(2);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    records[i].road,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(records[i].area),
                  const SizedBox(height: 12),
                  Tag(
                    records[i].depth == null
                        ? 'Current depth unknown'
                        : '${records[i].depth!.toInt()} cm • Sample',
                  ),
                  const SizedBox(height: 8),
                  Text(records[i].source, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      if (!records.any(
        (r) =>
            '${r.road} ${r.area}'.toLowerCase().contains(query.toLowerCase()),
      ))
        const InfoCard(
          child: Text('No matching sample roads. Try Manila or Marikina.'),
        ),
    ],
  );
}

void openInfo(BuildContext context, String title, Widget body) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: body,
      ),
    ),
  );
}
