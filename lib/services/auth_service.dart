import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Ensures the user is anonymously authenticated.
  /// Returns the current user's UID.
  Future<String?> ensureAnonymousLogin() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        final UserCredential credential = await _firebaseAuth.signInAnonymously();
        user = credential.user;
        debugPrint('AuthService: Signed in anonymously. UID: ${user?.uid}');
      } else {
        debugPrint('AuthService: Already signed in. UID: ${user.uid}');
      }
      return user?.uid;
    } catch (e) {
      debugPrint('AuthService Error: Failed to sign in anonymously - $e');
      return null;
    }
  }

  /// Exposes the current UID.
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  /// Placeholder for future Google Login
  Future<void> signInWithGoogle() async {
    // Coming Soon
    throw UnimplementedError('Google Login is coming soon.');
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
