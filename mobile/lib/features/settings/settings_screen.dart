import 'package:flutter/material.dart';
import '../../shared/widgets.dart';

void showAccountUnavailable(BuildContext context, String action) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(action),
      content: const Text(
        'Supabase Authentication is not connected. Account creation and login are unavailable in this demonstration. You can continue checking sample flood information as a guest.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continue as Guest'),
        ),
      ],
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    title: 'Profile',
    subtitle: 'Guest access ? No account required to check floods.',
    children: [
      const InfoCard(
        child: Text(
          'Welcome, Guest. Public flood information remains accessible without registration.',
        ),
      ),
      FilledButton.icon(
        onPressed: () => showAccountUnavailable(context, 'Log In'),
        icon: const Icon(Icons.login),
        label: const Text('Log In'),
      ),
      OutlinedButton(
        onPressed: () => showAccountUnavailable(context, 'Register'),
        child: const Text('Register'),
      ),
      const ListTile(
        leading: Icon(Icons.language),
        title: Text('Language settings'),
        subtitle: Text('English ? Filipino translation is not yet available'),
      ),
      const ListTile(
        leading: Icon(Icons.bookmark_outline),
        title: Text('Saved locations'),
        subtitle: Text(
          'Device persistence and account synchronization are not connected.',
        ),
      ),
      const ListTile(
        leading: Icon(Icons.notifications_outlined),
        title: Text('Notification preferences'),
        subtitle: Text(
          'Public alerts are available from the bell. Personalized notifications require a connected account.',
        ),
      ),
      const InfoCard(
        child: Text(
          'Help and About\nBAHAlerto ? Flood awareness prototype\nAll observations are demonstration fixtures. No live flood data, GPS, uploads or account storage is connected. Reports in memory disappear on restart. Avoid flooded roads and follow official advisories.',
        ),
      ),
    ],
  );
}
