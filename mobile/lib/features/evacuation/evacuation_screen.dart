import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

class EvacuationScreen extends StatelessWidget {
  const EvacuationScreen({super.key});
  @override
  Widget build(BuildContext context) => const PageBody(
    title: 'Evacuation information',
    subtitle:
        'Confirm destinations with your local government before traveling.',
    children: [
      InfoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tag('SAMPLE CENTER • Fictional'),
            SizedBox(height: 16),
            Text(
              'Community evacuation hall',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Illustrative record only\nAddress: Not provided\nCapacity: Not verified\nOperating status: Unknown\nContact: Not connected',
            ),
          ],
        ),
      ),
      InfoCard(
        child: Text(
          'No verified evacuation center directory or emergency contact list is connected. Consult your barangay or city disaster risk reduction office for current center and contact information.',
        ),
      ),
    ],
  );
}
