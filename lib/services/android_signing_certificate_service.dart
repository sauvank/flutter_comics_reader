import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Returns the certificate currently signing the installed Android package.
/// It is only used to diagnose an OAuth configuration mismatch.
class AndroidSigningCertificateService {
  AndroidSigningCertificateService._();

  static const _channel = MethodChannel('comicstream/security');

  static Future<List<String>> currentSha1() async {
    if (kIsWeb || !Platform.isAndroid) return const [];
    final values = await _channel.invokeListMethod<String>('signingCertificateSha1');
    return values ?? const [];
  }
}
