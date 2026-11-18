import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase is optional until the maintainer links a Firebase project.
/// The reader must remain fully usable locally in the meantime.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isAvailable = false;
  static bool _googleSignInInitialized = false;

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Google Sign-In only has mobile and web implementations.
  static bool get supportsGoogleSignIn => !_isDesktop;

  /// Desktop has no google-services.json: the Firebase web-app configuration
  /// is passed at build time with `--dart-define-from-file` (see
  /// docs/FIREBASE_SETUP.md). Null when the build carries no configuration.
  static FirebaseOptions? get desktopOptions {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) return null;
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: senderId,
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    );
  }

  static Future<void> initialize() async {
    try {
      if (_isDesktop) {
        final options = desktopOptions;
        if (options == null) {
          isAvailable = false;
          return;
        }
        await Firebase.initializeApp(options: options);
        isAvailable = true;
        return;
      }
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
