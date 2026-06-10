import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  AppLockService._();
  static final AppLockService instance = AppLockService._();

  static const _pinKey = 'app_lock_pin';
  static const _biometricKey = 'app_lock_biometric_enabled';

  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _pin;
  bool _biometricEnabled = false;
  bool _unlockedForSession = false;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _biometricEnabled = prefs.getBool(_biometricKey) ?? false;
  }

  bool get hasPin => (_pin ?? '').isNotEmpty;
  bool get biometricEnabled => _biometricEnabled;
  bool get isProtectionEnabled => hasPin || biometricEnabled;
  bool get isUnlockedForSession => _unlockedForSession;

  Future<bool> isBiometricSupported() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final supported = await _localAuth.isDeviceSupported();
    return canCheck && supported;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    _pin = pin;
    await prefs.setString(_pinKey, pin);
    _unlockedForSession = true;
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = null;
    await prefs.remove(_pinKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _biometricEnabled = enabled;
    await prefs.setBool(_biometricKey, enabled);
    if (enabled) {
      _unlockedForSession = true;
    }
  }

  bool verifyPin(String pin) {
    final valid = (_pin ?? '') == pin;
    if (valid) {
      _unlockedForSession = true;
    }
    return valid;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock Smart Expense Manager',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (success) {
        _unlockedForSession = true;
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    _unlockedForSession = false;
  }

  void unlockSession() {
    _unlockedForSession = true;
  }
}
