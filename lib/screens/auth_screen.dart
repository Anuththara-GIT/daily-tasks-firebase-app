import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoginMode = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isLoginMode) {
        await widget.authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.authService.signUp(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is AuthServiceException
          ? error.message
          : 'Could not continue right now. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLoginMode ? 'Welcome back' : 'Create your account';
    final subtitle = _isLoginMode
        ? 'Log in to view your own daily tasks and keep them synced.'
        : 'Sign up with email and password to keep your planner personal and secure.';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7E8DA), Color(0xFFE8F1E4), Color(0xFFD8E2D1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF5E8),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            size: 34,
                            color: Color(0xFF2F6B45),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF415148),
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 24),
                        if (!_isLoginMode) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Your name',
                            ),
                            validator: (value) {
                              if (_isLoginMode) {
                                return null;
                              }

                              if ((value ?? '').trim().isEmpty) {
                                return 'Enter your name.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'name@example.com',
                          ),
                          validator: (value) {
                            final email = (value ?? '').trim();
                            if (email.isEmpty) {
                              return 'Enter your email.';
                            }
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Enter a valid email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: _isLoginMode
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 6 characters',
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) {
                              return 'Enter your password.';
                            }
                            if (!_isLoginMode && password.length < 6) {
                              return 'Use at least 6 characters.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (_isLoginMode && !_isSubmitting) {
                              _submit();
                            }
                          },
                        ),
                        if (!_isLoginMode) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              hintText: 'Re-enter your password',
                            ),
                            validator: (value) {
                              if (_isLoginMode) {
                                return null;
                              }

                              if ((value ?? '').isEmpty) {
                                return 'Confirm your password.';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_isSubmitting) {
                                _submit();
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isLoginMode
                                        ? Icons.login_rounded
                                        : Icons.person_add_alt_1_rounded,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? 'Please wait...'
                                  : _isLoginMode
                                  ? 'Log in'
                                  : 'Create account',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _isSubmitting ? null : _toggleMode,
                            child: Text(
                              _isLoginMode
                                  ? 'Need a new account? Sign up'
                                  : 'Already have an account? Log in',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
