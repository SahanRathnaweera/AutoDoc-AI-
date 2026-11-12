import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_mode.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_hero.dart';


const kHasLoggedInBefore = 'has_logged_in_before';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.authAvailable,
    this.initialEmail = '',
  });

  final bool authAvailable;


  final String initialEmail;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _returningUser = false;

  bool get _justCreated => widget.initialEmail.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(kHasLoggedInBefore) ?? false;
      if (mounted && value != _returningUser) {
        setState(() => _returningUser = value);
      }
    } catch (_) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = AppPalette.of(context);

 
    final showWelcomeBack = _returningUser && !_justCreated;
    final title = showWelcomeBack ? 'Welcome back' : 'Log in to AUTODOC';
    final subtitle = showWelcomeBack
        ? 'Log in to continue your inspections.'
        : _justCreated
            ? 'Enter your password to continue.'
            : 'Log in, or create an account to get started.';

    return Scaffold(
      backgroundColor: p.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHero(height: 270),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_justCreated) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F6EC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF2E9E5B),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2E9E5B),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Account created successfully. '
                                    'Please log in.',
                                    style: TextStyle(
                                      color: Color(0xFF14532D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          title,
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: text.bodyLarge?.copyWith(color: p.muted),
                        ),
                        const SizedBox(height: 26),
                        AuthForm(
                          mode: AuthMode.login,
                          authAvailable: widget.authAvailable,
                          initialEmail: widget.initialEmail,
                          onRegistered: (_) {},
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _returningUser
                                  ? "Don't have an account?"
                                  : 'New here?',
                              style: text.bodyMedium?.copyWith(color: p.muted),
                            ),
                            TextButton(
                              onPressed: () => context.push('/auth/signup'),
                              child: Text(
                                _returningUser ? 'Sign up' : 'Create an account',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
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