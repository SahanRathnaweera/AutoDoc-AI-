import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:autodoc_ai/config/injection.dart';
import 'package:autodoc_ai/core/theme/app_theme.dart';
import 'package:autodoc_ai/core/theme/theme_controller.dart';
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

    final palette = AppPalette.of(context);
    final name = displayName == null || displayName.isEmpty
        ? 'AutoDoc user'
        : displayName;
    final email = user?.email;
    final verified = user?.emailVerified == true;
    final statusColor = verified ? palette.accent : palette.muted;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: palette.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.person_outline, size: 32),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.muted),
                      ),
                      const SizedBox(height: 12),
                      Chip(
                        avatar: Icon(
                          verified
                              ? Icons.verified_outlined
                              : Icons.mail_outline,
                          size: 18,
                          color: statusColor,
                        ),
                        label: Text(
                          verified ? 'Email verified' : 'Email not verified',
                        ),
                        labelStyle: TextStyle(color: statusColor),
                        side: BorderSide(color: palette.line),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Appearance', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeController,
              builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {
                  mode == ThemeMode.system
                      ? (theme.brightness == Brightness.dark
                            ? ThemeMode.dark
                            : ThemeMode.light)
                      : mode,
                },
                onSelectionChanged: (selection) =>
                    themeController.setMode(selection.first),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: palette.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Inspection reports'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/dashboard/report'),
                  ),
                  Divider(height: 1, color: palette.line),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help and support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showMessage(
                      context,
                      'Support is available from your AutoDoc AI team.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _signingOut ? null : _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
