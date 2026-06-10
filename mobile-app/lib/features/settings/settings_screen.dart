import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../auth/login_screen.dart';
import 'data_backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  bool savingPassword = false;
  bool deleting = false;
  bool loadingSecurity = true;
  bool pinEnabled = false;
  bool biometricEnabled = false;
  bool biometricSupported = false;

  @override
  void initState() {
    super.initState();
    loadSecuritySettings();
  }

  @override
  void dispose() {
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> loadSecuritySettings() async {
    await AppLockService.instance.initialize();
    final supported = await AppLockService.instance.isBiometricSupported();
    if (!mounted) return;
    setState(() {
      pinEnabled = AppLockService.instance.hasPin;
      biometricEnabled = AppLockService.instance.biometricEnabled;
      biometricSupported = supported;
      loadingSecurity = false;
    });
  }

  Future<void> updatePassword() async {
    final password = passwordCtrl.text.trim();
    final confirmPassword = confirmPasswordCtrl.text.trim();

    if (password.length < 6) {
      _show('Use at least 6 characters for the new password.');
      return;
    }

    if (password != confirmPassword) {
      _show('Password and confirm password do not match.');
      return;
    }

    setState(() => savingPassword = true);
    try {
      await AuthService.instance.updatePassword(password);
      _show('Password updated successfully.');
      passwordCtrl.clear();
      confirmPasswordCtrl.clear();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _show('Please log out and log in again before changing your password.');
      } else {
        _show(e.message ?? 'Unable to update password.');
      }
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => savingPassword = false);
    }
  }

  Future<void> logout() async {
    AppLockService.instance.lock();
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: const Text(
          'This will permanently delete your account and all stored expense data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => deleting = true);
    try {
      await const ProfileService().deleteAccount();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> configurePin() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? localError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set App PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                ),
              ),
              if (localError != null) ...[
                const SizedBox(height: 10),
                Text(
                  localError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();
                if (pin.length < 4) {
                  setDialogState(() => localError = 'Use at least 4 digits.');
                  return;
                }
                if (pin != confirm) {
                  setDialogState(() => localError = 'PIN values do not match.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await AppLockService.instance.setPin(pinController.text.trim());
      if (!mounted) return;
      setState(() => pinEnabled = true);
      _show('App PIN enabled.');
    }
  }

  Future<void> removePin() async {
    await AppLockService.instance.clearPin();
    if (!mounted) return;
    setState(() => pinEnabled = false);
    _show('App PIN removed.');
  }

  Future<void> toggleBiometrics(bool value) async {
    if (value) {
      final verified = await AppLockService.instance.authenticateWithBiometrics();
      if (!verified) {
        if (!mounted) return;
        _show('Biometric verification was not completed.');
        return;
      }
    }

    await AppLockService.instance.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => biometricEnabled = value);
    _show(value ? 'Biometric unlock enabled.' : 'Biometric unlock disabled.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'App Security',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (loadingSecurity)
            const Center(child: CircularProgressIndicator())
          else ...[
            SwitchListTile(
              value: pinEnabled,
              onChanged: (value) {
                if (value) {
                  configurePin();
                } else {
                  removePin();
                }
              },
              title: const Text('Require App PIN'),
              subtitle: const Text('Use a PIN to unlock the app locally'),
            ),
            SwitchListTile(
              value: biometricEnabled,
              onChanged: biometricSupported ? toggleBiometrics : null,
              title: const Text('Enable Biometrics'),
              subtitle: Text(
                biometricSupported
                    ? 'Use fingerprint/face unlock when reopening the app'
                    : 'Biometric unlock is not available on this device',
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Text(
            'Backup & Restore',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('CSV Backup Manager'),
              subtitle: const Text('Export local CSV backups and import them back into the app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DataBackupScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmPasswordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: savingPassword ? null : updatePassword,
            child: Text(savingPassword ? 'Updating...' : 'Update Password'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: deleting ? null : deleteAccount,
            icon: const Icon(Icons.delete_forever),
            label: Text(deleting ? 'Deleting...' : 'Delete Account Permanently'),
          ),
        ],
      ),
    );
  }
}
