import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class ProfileScreen extends StatefulWidget {
    const ProfileScreen({super.key});

    @override
    State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
    final AuthService _authService = AuthService();
    final _formKey = GlobalKey<FormState>();
    final _newPassword = TextEditingController();
    final _currentPassword = TextEditingController();

    bool _loading = false;
    bool _needsReauthentication = false;
    String? _message;

    @override
    void dispose() {
        _newPassword.dispose();
        _currentPassword.dispose();
        super.dispose();
    }

    Future<void> _updatePassword() async {
        if (!_formKey.currentState!.validate()) return;

        setState(() {
            _loading = true;
            _message = null;
        });

        try {
            if (_needsReauthentication) {
                await _authService.reauthenticate(_currentPassword.text);
            }

            await _authService.changePassword(_newPassword.text);

            if (!mounted) return;
            _newPassword.clear();
            _currentPassword.clear();
            setState(() {
                _needsReauthentication = false;
                _message = 'Password updated successfully.';
            });
        } on FirebaseAuthException catch (error) {
            if (!mounted) return;

            setState(() {
                switch (error.code) {
                    case 'requires-recent-login':
                        _needsReauthentication = true;
                        _message = 'Enter your current password below, then retry the update.';
                        break;
                    case 'weak-password':
                        _message = 'Choose a stronger password that meets the project requirements.';
                        break;
                    case 'network-request-failed':
                        _message = 'Check your internet connection and try again.';
                        break;
                    case 'too-many-requests':
                        _message = 'Too many attempts. Please wait and try again.';
                        break;
                    default:
                        _message = _needsReauthentication
                            ? 'Verification failed. Check your current password and retry.'
                            : 'Password update failed. Please try again.';
                }
            });
        } catch (_) {
            if (!mounted) return;
            setState(() {
                _message = 'Unable to update your password. Try signing out and signing in again.';
            });
        } finally {
            if (mounted) {
                setState(() {
                    _loading = false;
                });
            }
        }
    }

    void _cancelUpdate() {
        _newPassword.clear();
        _currentPassword.clear();
        _formKey.currentState?.reset();

        setState(() {
            _needsReauthentication = false;
            _message = 'Password update canceled.';
        });
    }

    Future<void> _signOut() async {
        setState(() {
            _loading = true;
            _message = null;
        });

        try {
            await _authService.signOut();
        } catch (_) {
            if (!mounted) return;
            setState(() {
                _message = 'Sign-out failed. Please try again.';
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
        final email = _authService.currentUser?.email;

        return Scaffold(
            appBar: AppBar(
                title: const Text('Profile'),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Text('Signed in as: ${email ?? 'Email unavailable'}'),
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: _newPassword,
                                enabled: !_loading,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: const InputDecoration(
                                    labelText: 'New password',
                                ),
                                validator: (value) {
                                    if (value == null || value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                },
                            ),
                            if (_needsReauthentication)
                                TextFormField(
                                    controller: _currentPassword,
                                    enabled: !_loading,
                                    obscureText: true,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    decoration: const InputDecoration(
                                        labelText: 'Current password',
                                    ),
                                    validator: (value) {
                                        if (value == null || value.isEmpty) {
                                            return 'Enter your current password';
                                        }
                                        return null;
                                    },
                                ),
                            const SizedBox(height: 16),
                            if (_message != null)
                                Text(_message!),
                            if (_loading)
                                const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator(),
                                    ),
                                ),
                            ElevatedButton(
                                onPressed: _loading ? null : _updatePassword,
                                child: Text(
                                    _needsReauthentication
                                        ? 'Verify and Update Password'
                                        : 'Update Password',
                                ),
                            ),
                            TextButton(
                                onPressed: _loading ? null : _cancelUpdate,
                                child: const Text('Cancel Password Update'),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                                onPressed: _loading ? null : _signOut,
                                child: const Text('Sign Out'),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
