import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:comic_reader_app/services/sync/sync_service.dart';
import 'package:comic_reader_app/services/sync/sync_models.dart';
import 'package:comic_reader_app/services/sync/vault_service.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  AuthProvider? lastProvider;

  @override
  Future<UserCredential> signInWithProvider(AuthProvider provider) async {
    lastProvider = provider;
    return _FakeUserCredential();
  }

  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('signInWithGoogle reports unsupported native Google authentication',
      () async {
    final fakeAuth = _FakeFirebaseAuth();
    final service = SyncService(
      auth: fakeAuth,
      googleSignIn: GoogleSignIn.instance,
    );

    await expectLater(
        service.signInWithGoogle(), throwsA(isA<UnsupportedError>()));
    expect(fakeAuth.lastProvider, isNull);
  });

  test('updateRecoveryPhrase rejects phrase shorter than 16 characters',
      () async {
    final service = SyncService(
      auth: _FakeFirebaseAuth(),
    );

    expect(
      () => service.updateRecoveryPhrase('too-short'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('updateRecoveryPhrase requires authenticated user and unlocked vault',
      () async {
    final service = SyncService(
      auth: _FakeFirebaseAuth(),
    );

    expect(
      () => service.updateRecoveryPhrase('this-is-a-long-enough-phrase-12345'),
      throwsA(isA<StateError>()),
    );
  });

  test('VaultService can save and generate new recovery salts', () async {
    final storage = _FakeSecureStorage();
    final vault = VaultService(storage: storage);

    final salt1 = await vault.generateNewRecoverySalt();
    expect(salt1, isNotEmpty);

    await vault.saveRecoverySalt('custom-salt-value');
    expect(await vault.recoverySalt(), 'custom-salt-value');

    final salt2 = await vault.generateNewRecoverySalt();
    expect(salt2, isNot('custom-salt-value'));
    expect(await vault.recoverySalt(), salt2);
  });

  test('SyncConflict keeps the details shown before replacing local data', () {
    final conflict = SyncConflict(
      documentId: 'progress:book',
      label: 'Book',
      localUpdatedAt: DateTime.utc(2026),
      remoteUpdatedAt: DateTime.utc(2026, 1, 2),
      localSummary: 'Page 4/20 · Favori : non · 0 marque-page',
      remoteSummary: 'Page 12/20 · Favori : oui · 2 marque-pages',
    );

    expect(conflict.localSummary, contains('Page 4/20'));
    expect(conflict.remoteSummary, contains('Page 12/20'));
  });

  test('SyncDeviceBackup keeps an anonymous device restore point', () {
    final backup = SyncDeviceBackup(
      id: 'random-installation-id',
      label: 'Appareil 1A2B',
      isCurrentDevice: false,
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    expect(backup.id, 'random-installation-id');
    expect(backup.label, 'Appareil 1A2B');
    expect(backup.isCurrentDevice, isFalse);
    expect(backup.updatedAt, DateTime.utc(2026, 1, 2));
  });
}
