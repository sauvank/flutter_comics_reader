import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// Builds a stable content identifier without loading an archive in memory.
class BookFingerprintService {
  BookFingerprintService._();

  static Future<String?> sha256ForFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    // Hashing a large PDF takes a while: keep it off the UI thread.
    return Isolate.run(
        () async => (await sha256.bind(File(path).openRead()).first).toString());
  }
}
