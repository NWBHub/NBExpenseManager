import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  Future<void> _afterLogin() async {
    await ApiService().post('/auth/sync-user', {});
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> googleLogin() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      await _afterLogin();
    } on FirebaseAuthException catch (e) {
      _show(_firebaseMessage(e));
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> emailLogin() async {
    setState(() => loading = true);
    try {
      await AuthService.instance.signInWithEmail(
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
      );
      await _afterLogin();
    } on FirebaseAuthException catch (e) {
      _show(_firebaseMessage(e));
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openRegister() async {
    final createdEmail = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );

    if (createdEmail != null && mounted) {
      emailCtrl.text = createdEmail;
      passCtrl.clear();
      _show('Account created. Please log in with your new password.');
    }
  }

  Future<void> forgotPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _show('Enter your email first to reset the password.');
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      _show('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      _show(_firebaseMessage(e));
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Login failed. Check your password, or use Continue with Google if this account was created with Google.';
      case 'wrong-password':
        return 'Incorrect password. Try again or reset your password.';
      case 'user-not-found':
        return 'No account found for this email. Create a new account first.';
      case 'email-already-in-use':
        return 'This email is already in use. Try Login, or Continue with Google if that is how the account was created.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked with another sign-in method. Try the original provider.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Smart Expense Manager',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : forgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: loading ? null : emailLogin,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: loading ? null : openRegister,
                      child: const Text('Create Account'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: loading ? null : googleLogin,
                      child: const Text('Continue with Google'),
                    ),
                    if (loading) ...const [
                      SizedBox(height: 16),
                      Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
