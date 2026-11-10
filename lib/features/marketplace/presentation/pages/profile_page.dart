import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:autodoc_ai/config/injection.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/core/utils/show_snackbar.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/logout_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;

  Future<void> _logout() async {
    setState(() => _signingOut = true);
    final result = await getIt<LogoutUser>()(const NoParams());
    if (!mounted) return;
    setState(() => _signingOut = false);

    result.fold(
      (failure) => showCustomSnackBar(context, failure.message),
      (_) => context.go('/auth'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = getIt<FirebaseAuth>().currentUser;
    final displayName = user?.displayName?.trim();

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName == null || displayName.isEmpty
                            ? 'AutoDoc user'
                            : displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(user?.email ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        user?.emailVerified == true
                            ? 'Email verified'
                            : 'Email not verified',
                      ),
                    ],
                  ),
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
          onPressed: _signingOut ? null : _logout,
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
