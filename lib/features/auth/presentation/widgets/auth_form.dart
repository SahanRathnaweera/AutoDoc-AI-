import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:autodoc_ai/config/injection.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/theme/app_theme.dart';
import 'package:autodoc_ai/core/usecase/usecase.dart';
import 'package:autodoc_ai/core/utils/show_snackbar.dart';
import 'package:autodoc_ai/features/authentication/domain/entities/social_provider.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/login_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/logout_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/register_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/reset_password.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/sign_in_with_social.dart';
import '../../domain/entities/auth_mode.dart';

import 'package:shared_preferences/shared_preferences.dart';

const _googleMark = Text(
  'G',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Color(0xFF4285F4),
  ),
);

const _yahooMark = Text(
  'Y',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Color(0xFF6001D2),
  ),
);


class AuthForm extends StatefulWidget {
  const AuthForm({
    required this.mode,
    required this.authAvailable,
    required this.onRegistered,
    this.initialEmail = '',
    super.key,
  });

  final AuthMode mode;
  final bool authAvailable;

 
  final ValueChanged<String> onRegistered;


  final String initialEmail;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isLogin = widget.mode == AuthMode.login;
    final phone = _phoneController.text.trim();

    await _runAuthAction(() async {
      final result = isLogin
          ? await getIt<LoginUser>()(
              LoginParams(email: email, password: password),
            )
          : await getIt<RegisterUser>()(
              RegisterParams(
                email: email,
                password: password,
                displayName: _nameController.text.trim(),
                phoneNumber: phone.isEmpty ? null : phone,
              ),
            );

      if (!mounted) return;
      await result.fold<Future<void>>(
        (failure) async => showCustomSnackBar(
          context,
          failure is UserNotFoundFailure
              ? 'Invalid email or password.'
              : failure.message,
        ),
        (_) async {
          if (isLogin) {
            await _markLoggedIn();
            if (!mounted) return;
            context.go('/dashboard');
            return;
          }
          
          await getIt<LogoutUser>()(NoParams());
          if (!mounted) return;
          showCustomSnackBar(
            context,
            'Account created. Please log in.',
            isError: false,
          );
          widget.onRegistered(email);
        },
      );
    });
  }

  Future<void> _socialSignIn(SocialProvider provider) async {
    await _runAuthAction(() async {
      final result = await getIt<SignInWithSocial>()(
        SocialSignInParams(provider),
      );
      if (!mounted) return;
      await result.fold<Future<void>>(
        (failure) async => showCustomSnackBar(context, failure.message),
        (_) async {
          await _markLoggedIn();
          if (!mounted) return;
          context.go('/dashboard');
        },
      );
    });
  }

  
  Future<void> _markLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_logged_in_before', true);
    } catch (_) {}
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final error = _validateEmail(email);
    if (error != null) {
      showCustomSnackBar(context, error);
      return;
    }

    await _runAuthAction(() async {
      final result = await getIt<ResetPassword>()(
        ResetPasswordParams(email: email),
      );
      if (!mounted) return;
      final failure = result.fold<Failure?>((failure) => failure, (_) => null);
      if (failure != null && failure is! UserNotFoundFailure) {
        showCustomSnackBar(context, failure.message);
        return;
      }

      showCustomSnackBar(
        context,
        'If an account exists for that email, a reset link will be sent.',
        isError: false,
      );
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (_busy) return;
    if (!widget.authAvailable) {
      showCustomSnackBar(
        context,
        'Firebase Authentication is unavailable. Configure Firebase for this device.',
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!email.contains('@')) return 'Enter a valid email address';
    return null;
  }

  InputDecoration _passwordDecoration(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;
    final theme = Theme.of(context);
    final p = AppPalette.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isLogin) ...[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          if (!isLogin) ...[
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isNotEmpty && phone.length < 7) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _passwordDecoration('Password'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your password';
              if (!isLogin && value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          if (!isLogin) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscurePassword,
              decoration: _passwordDecoration('Confirm password'),
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
          ],
          if (isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _resetPassword,
                child: const Text('Forgot password?'),
              ),
            )
          else ...[
            const SizedBox(height: 14),
            Text(
              'By creating an account, you agree to our Terms and Privacy Policy.',
              style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: p.strong,
                foregroundColor: p.onStrong,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isLogin ? 'Log in' : 'Create account',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: Divider(color: p.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  isLogin ? 'or continue with' : 'or sign up with',
                  style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                ),
              ),
              Expanded(child: Divider(color: p.line)),
            ],
          ),
          const SizedBox(height: 18),
          if (isLogin)
           
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    leading: _googleMark,
                    compact: true,
                    onPressed: _busy
                        ? null
                        : () => _socialSignIn(SocialProvider.google),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    label: 'Yahoo',
                    leading: _yahooMark,
                    compact: true,
                    onPressed: _busy
                        ? null
                        : () => _socialSignIn(SocialProvider.yahoo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    label: 'Microsoft',
                    leading: const _MicrosoftMark(),
                    compact: true,
                    onPressed: _busy
                        ? null
                        : () => _socialSignIn(SocialProvider.microsoft),
                  ),
                ),
              ],
            )
          else ...[
            // Sign up: full labelled buttons.
            _SocialButton(
              label: 'Sign up with Google',
              leading: _googleMark,
              onPressed: _busy
                  ? null
                  : () => _socialSignIn(SocialProvider.google),
            ),
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Sign up with Yahoo',
              leading: _yahooMark,
              onPressed: _busy
                  ? null
                  : () => _socialSignIn(SocialProvider.yahoo),
            ),
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Sign up with Microsoft',
              leading: const _MicrosoftMark(),
              onPressed: _busy
                  ? null
                  : () => _socialSignIn(SocialProvider.microsoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return SizedBox(
      height: 54,
      child: Tooltip(
        message: label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: p.text,
            backgroundColor: p.surface,
            side: BorderSide(color: p.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: compact
              ? leading
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


class _MicrosoftMark extends StatelessWidget {
  const _MicrosoftMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: GridView(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        children: const [
          ColoredBox(color: Color(0xFFF25022)),
          ColoredBox(color: Color(0xFF7FBA00)),
          ColoredBox(color: Color(0xFF00A4EF)),
          ColoredBox(color: Color(0xFFFFB900)),
        ],
      ),
    );
  }
}