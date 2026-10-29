import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../../shared/backend_list.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageBody(
    title: 'Alerts & advisories',
    subtitle: 'Published, unexpired advisories ? Latest 100',
    children: [
      BackendList(
        value: ref.watch(directoryProvider('flood_alerts')),
        refresh: () => ref.invalidate(directoryProvider('flood_alerts')),
        empty:
            'No current published advisories. This does not indicate safe conditions.',
        item: (r) => InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag(r['severity'] as String),
              Text(r['title'] as String, style: const TextStyle(fontSize: 21)),
              Text(r['message'] as String),
              Text('Source: ${r['source']}'),
              Text('Published: ${r['published_at']}'),
              Text('Expires: ${r['expires_at']}'),
            ],
          ),
        ),
      ),
    ],
  );
}
