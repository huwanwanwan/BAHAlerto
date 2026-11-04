import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Uri streetViewUri(double latitude, double longitude) {
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180) {
    throw ArgumentError('Invalid location');
  }
  return Uri.https('www.google.com', '/maps/@', {
    'api': '1',
    'map_action': 'pano',
    'viewpoint': '$latitude,$longitude',
  });
}

Future<void> openStreetView(
  BuildContext context,
  double latitude,
  double longitude,
) async {
  try {
    final opened = await launchUrl(
      streetViewUri(latitude, longitude),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (opened) return;
  } catch (_) {
    /* Show a recoverable message if there is no URL handler. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open Street View. Please try again.'),
      ),
    );
  }
}
