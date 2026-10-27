import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text(
          'Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo User',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text('test@autodoc.ai'),
                    SizedBox(height: 4),
                    Text('Verified account'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.history),
          title: Text('Inspection history'),
          subtitle: Text('View your completed vehicle checks'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => context.go('/dashboard/report'),
        ),
        ListTile(
          leading: Icon(Icons.notifications_none),
          title: Text('Notifications'),
          subtitle: Text('Manage marketplace updates'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showMessage(context, 'You are up to date.'),
        ),
        ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Help and support'),
          subtitle: Text('Get assistance with AutoDoc AI'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _showMessage(
            context,
            'Support is available from your AutoDoc AI team.',
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.go('/auth'),
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
