import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool scanRemindersEnabled = true;
  bool biometricLockEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: notificationsEnabled,
            onChanged: (value) => setState(() => notificationsEnabled = value),
            title: const Text('Marketplace notifications'),
            subtitle: const Text('Receive updates about saved vehicles'),
            secondary: const Icon(Icons.notifications_outlined),
          ),
          SwitchListTile(
            value: scanRemindersEnabled,
            onChanged: (value) => setState(() => scanRemindersEnabled = value),
            title: const Text('Scan reminders'),
            subtitle: const Text('Remind me when an inspection is incomplete'),
            secondary: const Icon(Icons.alarm_outlined),
          ),
          SwitchListTile(
            value: biometricLockEnabled,
            onChanged: (value) => setState(() => biometricLockEnabled = value),
            title: const Text('Biometric lock'),
            subtitle: const Text('Protect inspection reports on this device'),
            secondary: const Icon(Icons.fingerprint),
          ),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showMessage(context, 'Privacy policy is coming soon.'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About AutoDoc AI'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'AutoDoc AI',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Guided. Diagnostic. Trusted.',
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
