import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:autodoc_ai/config/injection.dart';
import 'package:autodoc_ai/core/error/failures.dart';
import 'package:autodoc_ai/core/utils/show_snackbar.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/login_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/register_user.dart';
import 'package:autodoc_ai/features/authentication/domain/usecases/reset_password.dart';
import '../../domain/entities/auth_mode.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({
    required this.mode,
    required this.authAvailable,
    required this.onBusyChanged,
    super.key,
  });

  final AuthMode mode;
  final bool authAvailable;
  final ValueChanged<bool> onBusyChanged;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isLogin = widget.mode == AuthMode.login;
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
              ),
            );

      if (!mounted) return;
      result.fold(
        (failure) => showCustomSnackBar(
          context,
          failure is UserNotFoundFailure
              ? 'Invalid email or password.'
              : failure.message,
        ),
        (_) => context.go('/dashboard'),
      );
    });
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
      showCustomSnackBar(context, 'Firebase Authentication is unavailable.');
      return;
    }

    setState(() => _busy = true);
    widget.onBusyChanged(true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!email.contains('@')) return 'Enter a valid email address';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = widget.mode == AuthMode.login;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isLogin) ...[
            TextFormField(
              controller: _nameController,
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
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration:
                const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your password';
              if (!isLogin && value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
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
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isLogin ? 'Log in' : 'Create account'),
          ),
        ],
      ),
    );
  }
}
