import 'package:firebase_core/firebase_core.dart';

/// Firebase is optional until the maintainer links a Firebase project.
/// The reader must remain fully usable locally in the meantime.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool isAvailable = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      isAvailable = true;
    } catch (_) {
      // Missing platform configuration is expected in open-source checkouts.
      isAvailable = false;
    }
  }
}
