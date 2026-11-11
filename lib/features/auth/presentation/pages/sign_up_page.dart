import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_mode.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_hero.dart';

/// Create-account page. After a successful sign-up the user goes back to Log in.
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key, required this.authAvailable});

  final bool authAvailable;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            AuthHero(
              height: 240,
              compact: true,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/auth');
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your\naccount',
                    style: text.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Register once, then log in.',
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        AuthForm(
                          mode: AuthMode.register,
                          authAvailable: authAvailable,
                          onRegistered: (email) =>
                              context.go('/auth', extra: email),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: text.bodyMedium?.copyWith(color: p.muted),
                            ),
                            TextButton(
                              onPressed: () => context.go('/auth'),
                              child: const Text(
                                'Log in',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}