import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-GCM envelope used before data leaves the device.
///
/// Firebase only stores the resulting nonce, cipher text and authentication
/// tag. It never receives a server password or reading metadata in clear text.
class CryptoService {
  CryptoService({Cipher? cipher}) : _cipher = cipher ?? AesGcm.with256bits();

  final Cipher _cipher;

  Future<SecretKey> createMasterKey() async => _cipher.newSecretKey();

  Future<Map<String, String>> encryptJson({
    required SecretKey key,
    required Map<String, dynamic> value,
  }) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(value)),
      secretKey: key,
    );
    return {
      'nonce': base64UrlEncode(box.nonce),
      'ciphertext': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
      'v': '1',
    };
  }

  Future<Map<String, dynamic>> decryptJson({
    required SecretKey key,
    required Map<String, dynamic> envelope,
  }) async {
    if (envelope['v'] != '1') throw const FormatException('Version de chiffrement inconnue');
    final box = SecretBox(
      base64Url.decode(envelope['ciphertext'] as String),
      nonce: base64Url.decode(envelope['nonce'] as String),
      mac: Mac(base64Url.decode(envelope['mac'] as String)),
    );
    final clear = await _cipher.decrypt(box, secretKey: key);
    return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
  }

  Future<SecretKey> keyFromBytes(List<int> bytes) => _cipher.newSecretKeyFromBytes(Uint8List.fromList(bytes));
}
