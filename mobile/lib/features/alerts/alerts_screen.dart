import 'package:flutter/material.dart';
import '../../shared/widgets.dart';
import '../../core/data.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PageBody(
    title: 'Alerts & advisories',
    subtitle: 'No live alert feed is connected.',
    children: [
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tag('SAMPLE ADVISORY • Not an official alert', warning: true),
            SizedBox(height: 18),
            Text(
              'Plan around flooded roads',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Example only: consider postponing nonessential travel when flooding is reported. Follow current instructions from local authorities.',
            ),
            SizedBox(height: 16),
            Text(
              'Sample publication: $sampleTime',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      InfoCard(
        child: Text(
          'Authorized alerts will include the issuing authority, affected area, publication time and expiry. Community reports will not be published as official warnings.',
        ),
      ),
    ],
  );
}
