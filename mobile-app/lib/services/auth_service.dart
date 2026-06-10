import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _loginProviderKey = 'login_provider';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Future<String?> getIdToken() async {
    return _auth.currentUser?.getIdToken(true);
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    await _setProvider('google');
    return result;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _setProvider('password');
    return result;
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _setProvider('password');
    return result;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updatePassword(String newPassword) {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'No signed-in user found.');
    }
    return user.updatePassword(newPassword);
  }

  Future<void> restoreSession() async {
    await _auth.authStateChanges().first;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(_loginProviderKey);

    if (provider == 'google') {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    }

    await prefs.remove(_loginProviderKey);
    await _auth.signOut();
  }

  Future<void> _setProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginProviderKey, provider);
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }
}
