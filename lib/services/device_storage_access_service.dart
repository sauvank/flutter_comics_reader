import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android bridge for the special all-files access needed to scan a phone.
class DeviceStorageAccessService {
  static const _channel = MethodChannel('comicstream/device_files');

  static Future<bool> hasAllFilesAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return await _channel.invokeMethod<bool>('hasAllFilesAccess') ?? false;
  }

  /// Opens Android's special-app-access settings for ComicStream.
  static Future<bool> requestAllFilesAccess() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    return await _channel.invokeMethod<bool>('requestAllFilesAccess') ?? false;
  }

  static Future<String?> sharedStoragePath() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return _channel.invokeMethod<String>('sharedStoragePath');
  }
}
