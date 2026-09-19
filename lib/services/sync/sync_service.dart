import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/book_item.dart';
import '../../models/server_profile.dart';
import '../database_service.dart';
import '../book_fingerprint_service.dart';
import '../reader_settings_service.dart';
import 'crypto_service.dart';
import 'firebase_bootstrap.dart';
import 'sync_models.dart';
import 'vault_service.dart';

/// Synchronises encrypted user state. It intentionally never uploads comic
/// files, local paths, covers, or server passwords outside an AES-GCM envelope.
class SyncService {
  SyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    DatabaseService? database,
    VaultService? vault,
    CryptoService? crypto,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _database = database ?? DatabaseService(),
        _vault = vault ?? VaultService(),
        _crypto = crypto ?? CryptoService(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  final DatabaseService _database;
  final VaultService _vault;
  final CryptoService _crypto;
  final GoogleSignIn _googleSignIn;

  User? get user => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<UserCredential> createAccount(
          {required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<UserCredential> signIn(
          {required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    await FirebaseBootstrap.ensureGoogleSignInInitialized();
    if (_googleSignIn.supportsAuthenticate()) {
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      if (auth.idToken == null) {
        throw StateError('Jeton d’authentification Google introuvable.');
      }
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      return _auth.signInWithCredential(credential);
    }

    if (kIsWeb) return _auth.signInWithPopup(GoogleAuthProvider());
    throw UnsupportedError(
        'La connexion Google n’est pas disponible sur cet appareil.');
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Checks whether this device has unlocked its local encryption key.
  Future<bool> hasLocalKey() => _vault.hasLocalVault();

  /// Checks whether a remote vault exists in Firestore for the current user.
  Future<bool> hasRemoteVault() async {
    final currentUser = user;
    if (currentUser == null) return false;
    try {
      final snapshot =
          await _firestore.doc('users/${currentUser.uid}/private/vault').get();
      return snapshot.exists;
    } catch (_) {
      return false;
    }
  }

  /// Creates a device vault. Call once after the user has safely recorded a
  /// recovery phrase; the phrase is not persisted on this device.
  Future<void> createVault(String recoveryPhrase) async {
    if (recoveryPhrase.trim().length < 16) {
      throw ArgumentError(
          'La phrase de récupération doit comporter au moins 16 caractères.');
    }
    final currentUser = user;
    if (currentUser == null) throw StateError('Connexion requise');
    final master = await _vault.createLocalVault();
    final recovery = await _vault.recoveryKey(recoveryPhrase);
    final envelope = await _crypto.encryptJson(
      key: recovery,
      value: {'masterKey': base64UrlEncode(await master.extractBytes())},
    );
    await _firestore.doc('users/${currentUser.uid}/private/vault').set({
      'version': 1,
      'salt': await _vault.recoverySalt(),
      'envelope': envelope,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restores the encrypted key on an additional device using the phrase.
  Future<void> restoreVault(String recoveryPhrase) async {
    final currentUser = user;
    if (currentUser == null) throw StateError('Connexion requise');
    final snapshot =
        await _firestore.doc('users/${currentUser.uid}/private/vault').get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Aucun coffre de synchronisation trouvé.');
    }
    final salt = data['salt'] as String;
    final recovery = await _vault.recoveryKey(recoveryPhrase, salt: salt);
    final value = await _crypto.decryptJson(
        key: recovery,
        envelope: Map<String, dynamic>.from(data['envelope'] as Map));
    await _vault.saveLocalKey(await _crypto
        .keyFromBytes(base64Url.decode(value['masterKey'] as String)));
    await _vault.saveRecoverySalt(salt);
  }

  /// Updates the recovery phrase for the existing vault without losing any synced data.
  /// The vault must already be unlocked on this device.
  Future<void> updateRecoveryPhrase(String newRecoveryPhrase) async {
    if (newRecoveryPhrase.trim().length < 16) {
      throw ArgumentError(
          'La phrase de récupération doit comporter au moins 16 caractères.');
    }
    final currentUser = user;
    if (currentUser == null) throw StateError('Connexion requise');
    final master = await _vault.readLocalKey();
    if (master == null) {
      throw StateError(
          'Le coffre doit être déverrouillé pour modifier la phrase secrète.');
    }
    final salt = await _vault.generateNewRecoverySalt();
    final recovery = await _vault.recoveryKey(newRecoveryPhrase, salt: salt);
    final envelope = await _crypto.encryptJson(
      key: recovery,
      value: {'masterKey': base64UrlEncode(await master.extractBytes())},
    );
    await _firestore.doc('users/${currentUser.uid}/private/vault').set({
      'version': 1,
      'salt': salt,
      'envelope': envelope,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<SyncConflict>> syncNow() async {
    final currentUser = user;
    final key = await _vault.readLocalKey();
    if (currentUser == null) throw StateError('Connexion requise');
    if (key == null) {
      throw StateError('Phrase de récupération requise sur cet appareil.');
    }
    final conflicts = <SyncConflict>[];
    final root = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('private');

    await _syncDocument(root.doc('servers'), 'servers', await _serversPayload(),
        key, conflicts, 'Configurations de serveurs');
    await _syncDocument(root.doc('settings'), 'settings',
        await _settingsPayload(), key, conflicts, 'Paramètres de lecture');
    for (final book in await _database.getBooks()) {
      if (book.serverId == null || book.serverRelativePath == null) continue;
      final fingerprintedBook = await _ensureFingerprint(book);
      final id = _progressId(fingerprintedBook);
      await _syncDocument(
          root.doc('progress').collection('files').doc(id),
          'progress:$id',
          await _progressPayload(fingerprintedBook),
          key,
          conflicts,
          fingerprintedBook.title);
    }
    return conflicts;
  }

  /// Applies an explicit user choice for a detected conflict. The selected
  /// version is marked as the new shared base so another device can apply it
  /// without raising the same conflict again.
  Future<void> resolveConflict(
    SyncConflict conflict,
    SyncConflictResolution resolution,
  ) async {
    final currentUser = user;
    final key = await _vault.readLocalKey();
    if (currentUser == null) throw StateError('Connexion requise');
    if (key == null) {
      throw StateError('Phrase de récupération requise sur cet appareil.');
    }

    final root = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('private');
    final reference = conflict.documentId.startsWith('progress:')
        ? root
            .doc('progress')
            .collection('files')
            .doc(conflict.documentId.substring('progress:'.length))
        : root.doc(conflict.documentId);

    final resolvedAt = DateTime.now().toUtc();
    Map<String, dynamic> chosen;
    if (resolution == SyncConflictResolution.keepLocal) {
      chosen = await _payloadForDocument(conflict.documentId);
    } else {
      final snapshot = await reference.get();
      if (!snapshot.exists) {
        throw StateError('Les données Google à résoudre sont introuvables.');
      }
      chosen = await _crypto.decryptJson(
        key: key,
        envelope:
            Map<String, dynamic>.from(snapshot.data()!['envelope'] as Map),
      );
    }

    chosen = _withUpdatedAt(chosen, resolvedAt);
    await _write(reference, key, chosen, resolvedAt: resolvedAt);
    await _applyRemote(conflict.documentId, chosen);
    await _database.setLastSyncedAt(conflict.documentId, resolvedAt);
  }

  Future<Map<String, dynamic>> _payloadForDocument(String documentId) async {
    if (documentId == 'servers') return _serversPayload();
    if (documentId == 'settings') return _settingsPayload();
    if (documentId.startsWith('progress:')) {
      final progressId = documentId.substring('progress:'.length);
      for (final book in await _database.getBooks()) {
        final fingerprintedBook = await _ensureFingerprint(book);
        if (_progressId(fingerprintedBook) == progressId) {
          return _progressPayload(fingerprintedBook);
        }
      }
      throw StateError('La progression locale correspondante n’existe plus.');
    }
    throw ArgumentError.value(
        documentId, 'documentId', 'Document de synchronisation inconnu');
  }

  Future<void> _syncDocument(
    DocumentReference<Map<String, dynamic>> reference,
    String localId,
    Map<String, dynamic> local,
    SecretKey key,
    List<SyncConflict> conflicts,
    String label,
  ) async {
    final snapshot = await reference.get();
    final localUpdated = DateTime.parse(local['updatedAt'] as String);
    if (!snapshot.exists) {
      await _write(reference, key, local);
      await _database.setLastSyncedAt(localId, localUpdated);
      return;
    }
    final remote = await _crypto.decryptJson(
        key: key,
        envelope:
            Map<String, dynamic>.from(snapshot.data()!['envelope'] as Map));
    final remoteUpdated = DateTime.parse(remote['updatedAt'] as String);
    final lastSynced = await _database.getLastSyncedAt(localId);
    final resolutionValue = snapshot.data()!['resolvedAt'];
    final resolvedAt =
        resolutionValue is Timestamp ? resolutionValue.toDate() : null;
    final hasNewResolvedVersion = resolvedAt != null &&
        (lastSynced == null || resolvedAt.isAfter(lastSynced)) &&
        !localUpdated.isAfter(resolvedAt);
    if (hasNewResolvedVersion) {
      await _applyRemote(localId, remote);
      await _database.setLastSyncedAt(localId, remoteUpdated);
      return;
    }
    // Downloading a book creates a local record dated "now", even when it
    // has never been read. That timestamp must not overwrite its existing
    // cloud progress on the first sync of the new device.
    if (lastSynced == null &&
        localId.startsWith('progress:') &&
        _isUntouchedProgress(local)) {
      await _applyRemote(localId, remote);
      await _database.setLastSyncedAt(localId, remoteUpdated);
      return;
    }
    // A newly connected device has an epoch timestamp for domains it has never
    // changed. It must adopt existing cloud data rather than treating the
    // empty local state as a concurrent edit.
    if (lastSynced == null) {
      final localIsPristine = localUpdated.millisecondsSinceEpoch == 0;
      final remoteIsPristine = remoteUpdated.millisecondsSinceEpoch == 0;
      if (localIsPristine && !remoteIsPristine) {
        await _applyRemote(localId, remote);
        await _database.setLastSyncedAt(localId, remoteUpdated);
        return;
      }
      if (remoteIsPristine && !localIsPristine) {
        await _write(reference, key, local);
        await _database.setLastSyncedAt(localId, localUpdated);
        return;
      }
    }
    final localChanged = lastSynced == null || localUpdated.isAfter(lastSynced);
    final remoteChanged =
        lastSynced == null || remoteUpdated.isAfter(lastSynced);
    if (localChanged && remoteChanged && localUpdated != remoteUpdated) {
      conflicts.add(SyncConflict(
          documentId: localId,
          label: label,
          localUpdatedAt: localUpdated,
          remoteUpdatedAt: remoteUpdated));
      return;
    }
    if (remoteUpdated.isAfter(localUpdated)) {
      await _applyRemote(localId, remote);
      await _database.setLastSyncedAt(localId, remoteUpdated);
    } else {
      await _write(reference, key, local);
      await _database.setLastSyncedAt(localId, localUpdated);
    }
  }

  Map<String, dynamic> _withUpdatedAt(
    Map<String, dynamic> payload,
    DateTime timestamp,
  ) =>
      {
        ...payload,
        'updatedAt': timestamp.toUtc().toIso8601String(),
      };

  bool _isUntouchedProgress(Map<String, dynamic> payload) {
    final bookmarks = payload['bookmarks'];
    return (payload['currentPage'] as int? ?? 0) == 0 &&
        payload['isCompleted'] != true &&
        payload['isFavorite'] != true &&
        (bookmarks is! List || bookmarks.isEmpty);
  }

  Future<void> _write(
    DocumentReference<Map<String, dynamic>> reference,
    SecretKey key,
    Map<String, dynamic> payload, {
    DateTime? resolvedAt,
  }) async {
    final value = <String, dynamic>{
      'v': 1,
      'envelope': await _crypto.encryptJson(key: key, value: payload),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (resolvedAt != null) {
      value['resolvedAt'] = Timestamp.fromDate(resolvedAt);
    }
    await reference.set(value);
  }

  Future<Map<String, dynamic>> _serversPayload() async => {
        'updatedAt': (await _database.getSyncDomainUpdatedAt('servers'))
            .toUtc()
            .toIso8601String(),
        'servers': (await _database.getServers())
            .map((server) => server.toMap())
            .toList(),
      };

  Future<Map<String, dynamic>> _settingsPayload() async => {
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'settings': await ReaderSettingsService().exportForSync(),
      };

  Future<Map<String, dynamic>> _progressPayload(BookItem book) async => {
        'updatedAt':
            (book.lastReadDate ?? book.addedDate).toUtc().toIso8601String(),
        'serverId': book.serverId,
        'serverRelativePath': book.serverRelativePath,
        'contentHash': book.contentHash,
        'currentPage': book.currentPage,
        'totalPages': book.totalPages,
        'isCompleted': book.isCompleted,
        'bookmarks': book.bookmarks,
        'isFavorite': book.isFavorite,
      };

  String _progressId(BookItem book) {
    final hash = book.contentHash;
    if (hash != null && hash.isNotEmpty) return 'sha256_$hash';
    return base64UrlEncode(
            utf8.encode('${book.serverId}|${book.serverRelativePath}'))
        .replaceAll('=', '');
  }

  Future<BookItem> _ensureFingerprint(BookItem book) async {
    if (book.contentHash != null && book.contentHash!.isNotEmpty) return book;
    final hash = await BookFingerprintService.sha256ForFile(book.localPath);
    if (hash == null) return book;
    final fingerprinted = book.copyWith(contentHash: hash);
    await _database.updateBook(fingerprinted);
    return fingerprinted;
  }

  Future<void> _applyRemote(String localId, Map<String, dynamic> remote) async {
    if (localId == 'servers') {
      await _database.saveServers((remote['servers'] as List)
          .map((value) =>
              ServerProfile.fromMap(Map<String, dynamic>.from(value as Map)))
          .toList());
    } else if (localId == 'settings') {
      await ReaderSettingsService()
          .applyFromSync(Map<String, dynamic>.from(remote['settings'] as Map));
    } else if (localId.startsWith('progress:')) {
      final path = remote['serverRelativePath'] as String;
      final server = remote['serverId'] as String;
      final contentHash = remote['contentHash'] as String?;
      final currentPage = remote['currentPage'] as int;
      final totalPages = remote['totalPages'] as int;
      final progress =
          totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
      final books = await _database.getBooks();
      final candidates = books.where((book) {
        if (contentHash == null || contentHash.isEmpty) {
          return book.serverId == server && book.serverRelativePath == path;
        }
        return book.serverId == server;
      });
      for (final originalBook in candidates) {
        final book = contentHash == null || contentHash.isEmpty
            ? originalBook
            : await _ensureFingerprint(originalBook);
        if (contentHash != null &&
            contentHash.isNotEmpty &&
            book.contentHash != contentHash) {
          continue;
        }
        await _database.updateBook(book.copyWith(
          currentPage: currentPage,
          totalPages: totalPages,
          progress: progress,
          isCompleted: remote['isCompleted'] as bool,
          bookmarks: List<int>.from(remote['bookmarks'] as List),
          isFavorite: remote['isFavorite'] as bool,
          lastReadDate: DateTime.parse(remote['updatedAt'] as String).toLocal(),
        ));
      }
    }
  }
}
