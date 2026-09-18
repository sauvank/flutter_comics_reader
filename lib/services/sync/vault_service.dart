import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto_service.dart';

/// Keeps only cryptographic material in OS protected storage.
/// The recovery phrase itself is deliberately never stored.
class VaultService {
  VaultService({FlutterSecureStorage? storage, CryptoService? crypto})
      : _storage = storage ?? const FlutterSecureStorage(),
        _crypto = crypto ?? CryptoService();

  static const _masterKey = 'sync.master-key.v1';
  static const _recoverySalt = 'sync.recovery-salt.v1';
  final FlutterSecureStorage _storage;
  final CryptoService _crypto;

  Future<bool> hasLocalVault() async => (await _storage.read(key: _masterKey)) != null;

  Future<SecretKey> createLocalVault() async {
    final key = await _crypto.createMasterKey();
    final bytes = await key.extractBytes();
    await _storage.write(key: _masterKey, value: base64UrlEncode(bytes));
    return key;
  }

  Future<SecretKey?> readLocalKey() async {
    final encoded = await _storage.read(key: _masterKey);
    if (encoded == null) return null;
    return _crypto.keyFromBytes(base64Url.decode(encoded));
  }

  Future<void> saveLocalKey(SecretKey key) async {
    await _storage.write(key: _masterKey, value: base64UrlEncode(await key.extractBytes()));
  }

  /// Derives a separate key from a user-provided recovery phrase. The salt may
  /// be stored remotely; it is not secret and cannot decrypt data by itself.
  Future<SecretKey> recoveryKey(String phrase, {String? salt}) async {
    final actualSalt = salt ?? await _newOrStoredSalt();
    final algorithm = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 210000, bits: 256);
    return algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(phrase.trim())),
      nonce: base64Url.decode(actualSalt),
    );
  }

  Future<String> recoverySalt() => _newOrStoredSalt();

  Future<void> saveRecoverySalt(String salt) async {
    await _storage.write(key: _recoverySalt, value: salt);
  }

  Future<String> generateNewRecoverySalt() async {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final value = base64UrlEncode(bytes);
    await _storage.write(key: _recoverySalt, value: value);
    return value;
  }

  Future<String> _newOrStoredSalt() async {
    final existing = await _storage.read(key: _recoverySalt);
    if (existing != null) return existing;
    return generateNewRecoverySalt();
  }
}
