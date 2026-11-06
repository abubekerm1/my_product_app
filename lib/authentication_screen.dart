import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class AuthenticationScreen extends StatefulWidget {
    const AuthenticationScreen({super.key});

    @override
    State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final AuthService _authService = AuthService();

    bool _loading = false;
    String? _errorMessage;

    @override
    void dispose() {
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Future<void> _submit(bool register) async {
        if (!_formKey.currentState!.validate()) return;

        setState(() {
            _loading = true;
            _errorMessage = null;
        });

        try {
            final email = _emailController.text.trim();
            final password = _passwordController.text;

            if (register) {
                await _authService.register(email, password);
            } else {
                await _authService.signIn(email, password);
            }
        } on FirebaseAuthException catch (error) {
            String message;

            switch (error.code) {
                case 'invalid-email':
                    message = 'Check your email address format.';
                    break;
                case 'weak-password':
                    message = 'Choose a stronger password that meets the project requirements.';
                    break;
                case 'email-already-in-use':
                    message = 'Unable to register with these details. Try signing in.';
                    break;
                case 'network-request-failed':
                    message = 'Check your internet connection and try again.';
                    break;
                case 'too-many-requests':
                    message = 'Too many attempts. Please wait and try again.';
                    break;
                case 'operation-not-allowed':
                    message = 'Email/password sign-in is unavailable. Contact the app administrator.';
                    break;
                default:
                    message = register
                        ? 'Registration failed. Check your details and try again.'
                        : 'Sign-in failed. Check your email and password.';
            }

            if (!mounted) return;
            setState(() {
                _errorMessage = message;
            });
        } catch (_) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'Something went wrong. Please try again.';
            });
        } finally {
            if (mounted) {
                setState(() {
                    _loading = false;
                });
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Register or Sign In'),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            TextFormField(
                                controller: _emailController,
                                enabled: !_loading,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                decoration: const InputDecoration(labelText: 'Email'),
                                validator: (value) {
                                    if (value == null || value.isEmpty) return 'Email is required';
                                    if (!value.contains('@')) return 'Enter a valid email address';
                                    return null;
                                },
                            ),
                            TextFormField(
                                controller: _passwordController,
                                enabled: !_loading,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: const InputDecoration(labelText: 'Password'),
                                validator: (value) {
                                    if (value == null || value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                },
                            ),
                            const SizedBox(height: 16),
                            if (_errorMessage != null)
                                Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                    ),
                                ),
                            if (_loading)
                                const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator(),
                                    ),
                                ),
                            ElevatedButton(
                                onPressed: _loading ? null : () => _submit(false),
                                child: const Text('Sign In'),
                            ),
                            TextButton(
                                onPressed: _loading ? null : () => _submit(true),
                                child: const Text('Register'),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
