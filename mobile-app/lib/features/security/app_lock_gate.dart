import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool loading = true;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  Future<void> initialize() async {
    await AppLockService.instance.initialize();
    if (!mounted) return;
    setState(() {
      loading = false;
      locked = AppLockService.instance.isProtectionEnabled &&
          !AppLockService.instance.isUnlockedForSession;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      AppLockService.instance.lock();
    }

    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {
        locked = AppLockService.instance.isProtectionEnabled &&
            !AppLockService.instance.isUnlockedForSession;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void unlock() {
    setState(() => locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (locked) {
      return AppUnlockScreen(onUnlocked: unlock);
    }

    return widget.child;
  }
}

class AppUnlockScreen extends StatefulWidget {
  const AppUnlockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<AppUnlockScreen> createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen> {
  final pinCtrl = TextEditingController();
  bool working = false;
  String? message;

  @override
  void dispose() {
    pinCtrl.dispose();
    super.dispose();
  }

  Future<void> unlockWithPin() async {
    final pin = pinCtrl.text.trim();
    if (pin.length < 4) {
      setState(() => message = 'Enter your 4-digit PIN.');
      return;
    }

    final valid = AppLockService.instance.verifyPin(pin);
    if (!valid) {
      setState(() => message = 'Incorrect PIN. Try again.');
      return;
    }

    widget.onUnlocked();
  }

  Future<void> unlockWithBiometrics() async {
    setState(() {
      working = true;
      message = null;
    });

    final success = await AppLockService.instance.authenticateWithBiometrics();
    if (!mounted) return;

    setState(() => working = false);
    if (success) {
      widget.onUnlocked();
    } else {
      setState(() => message = 'Biometric unlock was not completed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockService = AppLockService.instance;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B6EF5).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        size: 34,
                        color: Color(0xFF5B6EF5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock App',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use your PIN or biometrics to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (lockService.hasPin) ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: pinCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'App PIN',
                          counterText: '',
                        ),
                        onSubmitted: (_) => unlockWithPin(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: working ? null : unlockWithPin,
                          child: const Text('Unlock with PIN'),
                        ),
                      ),
                    ],
                    if (lockService.biometricEnabled) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: working ? null : unlockWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: Text(working ? 'Checking...' : 'Use Biometrics'),
                        ),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        message!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
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
