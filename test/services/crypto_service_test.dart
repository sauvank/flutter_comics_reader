import 'package:flutter_test/flutter_test.dart';
import 'package:comic_reader_app/services/sync/crypto_service.dart';

void main() {
  test('AES-GCM encrypts data and rejects a modified envelope', () async {
    final crypto = CryptoService();
    final key = await crypto.createMasterKey();
    final envelope = await crypto.encryptJson(key: key, value: {'password': 'not-plain-text', 'page': 12});

    expect(envelope['ciphertext'], isNot(contains('not-plain-text')));
    expect(await crypto.decryptJson(key: key, envelope: envelope), {'password': 'not-plain-text', 'page': 12});

    final tampered = Map<String, String>.from(envelope)..['ciphertext'] = 'AAAA';
    expect(() => crypto.decryptJson(key: key, envelope: tampered), throwsA(isA<Object>()));
  });
}
