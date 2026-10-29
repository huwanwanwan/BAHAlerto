import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend.dart';
import '../../shared/widgets.dart';
import '../../shared/backend_list.dart';

class EvacuationScreen extends ConsumerWidget {
  const EvacuationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageBody(
    title: 'Evacuation information',
    subtitle:
        'Confirm current availability with your local government before traveling. Latest 100 published centers.',
    children: [
      BackendList(
        value: ref.watch(directoryProvider('evacuation_centers')),
        refresh: () => ref.invalidate(directoryProvider('evacuation_centers')),
        empty: 'No published evacuation centers.',
        item: (r) => InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['name'] as String, style: const TextStyle(fontSize: 21)),
              Text(r['address'] as String),
              Text(r['operational_details'] as String),
              Text('Contact: ${r['contact'] ?? 'Not provided'}'),
              Text('Verified: ${r['verified_at']}'),
            ],
          ),
        ),
      ),
    ],
  );
}

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageBody(
    title: 'Emergency contacts',
    subtitle: 'Published local directory ? Latest 100',
    children: [
      BackendList(
        value: ref.watch(directoryProvider('emergency_contacts')),
        refresh: () => ref.invalidate(directoryProvider('emergency_contacts')),
        empty:
            'No published emergency contacts. Consult official local authority channels.',
        item: (r) => InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['organization'] as String),
              SelectableText(r['phone'] as String),
              Text(r['service_area'] as String),
              Text(r['details'] as String? ?? ''),
            ],
          ),
        ),
      ),
    ],
  );
}
