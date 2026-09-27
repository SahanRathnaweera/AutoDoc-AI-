import 'package:flutter/material.dart';

import '../../../../core/utils/brand_logo.dart';
import '../../domain/entities/auth_mode.dart';
import '../widgets/auth_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _mode = AuthMode.login;

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;

    return Scaffold(
      backgroundColor: const Color(0xff071722),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Theme(
                data: ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: const Color(0xff1479e8),
                  brightness: Brightness.light,
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    fillColor: Color(0xfff3f6f9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                child: Builder(
                  builder: (panelContext) {
                    final panelTheme = Theme.of(panelContext);
                    return Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 28,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: BrandLogo(width: 150)),
                          const SizedBox(height: 24),
                          Text(
                            isLogin ? 'Welcome back' : 'Create your account',
                            style: panelTheme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLogin
                                ? 'Sign in to continue your vehicle journey.'
                                : 'Start trusted vehicle diagnostics with AutoDoc AI.',
                            style: panelTheme.textTheme.bodyMedium?.copyWith(
                              color: panelTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SegmentedButton<AuthMode>(
                            segments: const [
                              ButtonSegment(
                                value: AuthMode.login,
                                label: Text('Log in'),
                              ),
                              ButtonSegment(
                                value: AuthMode.register,
                                label: Text('Register'),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (selection) {
                              setState(() => _mode = selection.first);
                            },
                          ),
                          const SizedBox(height: 28),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: AuthForm(key: ValueKey(_mode), mode: _mode),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
