import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../navigation/main_shell_screen.dart';
import '../security/app_lock_gate.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthService.instance.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (AuthService.instance.currentUser == null) {
          return const LoginScreen();
        }

        return const AppLockGate(
          child: MainShellScreen(),
        );
      },
    );
  }
}
