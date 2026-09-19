import 'dart:io';

import 'package:crypto/crypto.dart';

/// Builds a stable content identifier without loading an archive in memory.
class BookFingerprintService {
  BookFingerprintService._();

  static Future<String?> sha256ForFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}
