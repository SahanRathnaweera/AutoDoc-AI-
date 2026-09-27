import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/demo_credentials.dart';
import '../../domain/entities/auth_mode.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({required this.mode, super.key});

  final AuthMode mode;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (widget.mode == AuthMode.login &&
        (_emailController.text.trim().toLowerCase() != DemoCredentials.email ||
            _passwordController.text != DemoCredentials.password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid demo login credentials.')),
      );
      return;
    }

    context.go('/dashboard');
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
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter your email address';
              }
              if (!value.contains('@')) return 'Enter a valid email address';
              return null;
            },
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
            validator: (value) => value == null || value.length < 8
                ? 'Password must be at least 8 characters'
                : null,
          ),
          if (isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset is not connected yet.'),
                  ),
                ),
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
            onPressed: _submit,
            child: Text(isLogin ? 'Log in' : 'Create account'),
          ),
        ],
      ),
    );
  }
}
