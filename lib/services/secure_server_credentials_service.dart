import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Passwords never belong in SharedPreferences or exported JSON.
class SecureServerCredentialsService {
  SecureServerCredentialsService({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _key(String serverId) => 'server.password.$serverId';

  Future<void> save(String serverId, String? password) async {
    if (password == null || password.isEmpty) {
      await _storage.delete(key: _key(serverId));
      return;
    }
    await _storage.write(key: _key(serverId), value: password);
  }

  Future<String?> read(String serverId) => _storage.read(key: _key(serverId));

  Future<void> delete(String serverId) => _storage.delete(key: _key(serverId));
}
