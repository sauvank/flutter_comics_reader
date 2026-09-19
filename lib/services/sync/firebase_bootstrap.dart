import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase is optional until the maintainer links a Firebase project.
/// The reader must remain fully usable locally in the meantime.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isAvailable = false;
  static bool _googleSignInInitialized = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      isAvailable = true;
      await ensureGoogleSignInInitialized();
    } catch (_) {
      // Missing platform configuration is expected in open-source checkouts.
      isAvailable = false;
    }
  }

  static Future<void> ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    try {
      // Version 7 of google_sign_in requires initialization before invoking
      // its native authentication flow. Checking support first can otherwise
      // select the incompatible Firebase OAuth-provider fallback on Android.
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    } catch (_) {
      // Ignored if Google Sign-In is unavailable or not supported on this platform.
    }
  }
}
