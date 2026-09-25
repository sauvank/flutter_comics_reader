import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/book_item.dart';
import '../../models/server_profile.dart';
import '../database_service.dart';
import '../book_fingerprint_service.dart';
import '../reader_settings_service.dart';
import 'crypto_service.dart';
import 'firebase_bootstrap.dart';
import 'sync_models.dart';
import 'vault_service.dart';

/// Determines whether a book has a stable, private identity for progress
/// synchronization. Content hashes cover both server downloads and files
/// imported directly on a device; server metadata is a legacy fallback.
@visibleForTesting
bool hasProgressIdentity(BookItem book) {
  final hash = book.contentHash;
  return (hash != null && hash.isNotEmpty) ||
      (book.serverId != null && book.serverRelativePath != null);
}

/// Reading-position comparison shared by the sync service and its tests.
/// Bookmarks and favorites deliberately do not participate: choosing a page
/// must never discard those independent pieces of metadata.
@visibleForTesting
bool hasDifferentReadingPosition(BookItem local, Map<String, dynamic> remote) {
  final remotePage = remote['currentPage'] as int? ?? 0;
  final remoteChapterProgress =
      (remote['epubChapterProgress'] as num?)?.toDouble() ?? 0.0;
  return local.currentPage != remotePage ||
      (local.epubChapterProgress - remoteChapterProgress).abs() > 0.001;
}

bool _payloadsHaveSameReadingPosition(
    Map<String, dynamic> first, Map<String, dynamic> second) {
  final firstProgress =
      (first['epubChapterProgress'] as num?)?.toDouble() ?? 0.0;
  final secondProgress =
      (second['epubChapterProgress'] as num?)?.toDouble() ?? 0.0;
  return (first['currentPage'] as int? ?? 0) ==
          (second['currentPage'] as int? ?? 0) &&
      (firstProgress - secondProgress).abs() <= 0.001;
}

/// Synchronises encrypted user state. It intentionally never uploads comic
/// files, local paths, covers, or server passwords outside an AES-GCM envelope.
class SyncService {
  static const _deviceIdKey = 'sync.device.id';
  static const _deviceNameKey = 'sync.device.name';
  static const _bookDecisionPrefix = 'sync.book.decision.';
  static const _legacyDeviceId = 'legacy-shared-progress';
  static Future<List<SyncConflict>>? _activeSync;
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

  /// Shares one in-flight run between the automatic provider and the account
  /// screen. Without this, two service instances could compare the same stale
  /// state simultaneously and create duplicate conflicts.
  Future<List<SyncConflict>> syncNow() {
    final active = _activeSync;
    if (active != null) return active;
    final run = _syncNow();
    _activeSync = run;
    run.then<void>(
      (_) {
        if (identical(_activeSync, run)) _activeSync = null;
      },
      onError: (Object _, StackTrace __) {
        if (identical(_activeSync, run)) _activeSync = null;
      },
    );
    return run;
  }

  Future<List<SyncConflict>> _syncNow() async {
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
      final fingerprintedBook = await _ensureFingerprint(book);
      if (!hasProgressIdentity(fingerprintedBook)) continue;
      final id = _progressId(fingerprintedBook);
      // Every installation owns its snapshot. It can therefore publish its
      // current position without erasing the position of another device.
      await _saveDeviceProgress(root, fingerprintedBook, key);
      await _syncDocument(
          root.doc('progress').collection('files').doc(id),
          'progress:$id',
          await _progressPayload(fingerprintedBook),
          key,
          conflicts,
          fingerprintedBook.title);
    }
    // Keep an encrypted restore point for this installation as well as the
    // shared state. It lets the user explicitly choose another device later.
    await _saveDeviceBackup(root, key);
    return conflicts;
  }

  /// A user-chosen name used only to distinguish encrypted device backups.
  Future<String> currentDeviceName() async {
    final deviceId = await _deviceId();
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_deviceNameKey)?.trim().isNotEmpty == true
        ? preferences.getString(_deviceNameKey)!.trim()
        : _deviceLabel(deviceId);
  }

  /// Renames this installation and updates its encrypted backup immediately
  /// when the vault is available.
  Future<DeviceRenameResult> renameCurrentDevice(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 40) {
      throw ArgumentError('Le nom doit contenir entre 1 et 40 caractères.');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_deviceNameKey, normalized);
    final currentUser = user;
    final key = await _vault.readLocalKey();
    if (currentUser == null || key == null) {
      return DeviceRenameResult.savedLocally;
    }
    final root = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('private');
    try {
      await _saveDeviceBackup(root, key);
      return DeviceRenameResult.synced;
    } catch (_) {
      // The local rename is still valid. A later manual or automatic sync
      // retries writing this encrypted restore point.
      return DeviceRenameResult.savedLocally;
    }
  }

  /// Finds the most recently read, different position for [book] on another
  /// installation. A dismissed revision is not offered again unless that
  /// device advances the book afterwards.
  Future<BookSyncProposal?> bookProgressProposal(BookItem book) async {
    final currentUser = user;
    final key = await _vault.readLocalKey();
    if (currentUser == null || key == null) return null;

    final localBooks = await _database.getBooks();
    final local =
        localBooks.where((item) => item.id == book.id).firstOrNull ?? book;
    final fingerprintedBook = await _ensureFingerprint(local);
    if (!hasProgressIdentity(fingerprintedBook)) return null;

    final root = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('private');
    final progressId = _progressId(fingerprintedBook);
    final currentDeviceId = await _deviceId();
    final progressReference =
        root.doc('progress').collection('files').doc(progressId);
    final candidates = <_DeviceProgressCandidate>[];

    final deviceSnapshots = await progressReference.collection('devices').get();
    for (final snapshot in deviceSnapshots.docs) {
      if (snapshot.id == currentDeviceId) continue;
      try {
        final payload = await _crypto.decryptJson(
          key: key,
          envelope:
              Map<String, dynamic>.from(snapshot.data()['envelope'] as Map),
        );
        final updatedAt = _payloadUpdatedAt(payload);
        if (_isUntouchedProgress(payload) ||
            !hasDifferentReadingPosition(fingerprintedBook, payload) ||
            await _hasHandledBookRevision(progressId, snapshot.id, updatedAt)) {
          continue;
        }
        candidates.add(_DeviceProgressCandidate(
          deviceId: snapshot.id,
          deviceName: payload['sourceDeviceName'] as String? ??
              'Appareil ${snapshot.id.substring(0, 4).toUpperCase()}',
          payload: payload,
          updatedAt: updatedAt,
        ));
      } catch (_) {
        // One stale or unreadable device snapshot must not prevent reading.
      }
    }

    // Compatibility with progress uploaded before per-device snapshots were
    // introduced. It remains available until every installation has synced.
    final legacySnapshot = await progressReference.get();
    if (legacySnapshot.exists) {
      try {
        final payload = await _crypto.decryptJson(
          key: key,
          envelope: Map<String, dynamic>.from(
              legacySnapshot.data()!['envelope'] as Map),
        );
        final sourceId =
            payload['sourceDeviceId'] as String? ?? _legacyDeviceId;
        final alreadyRepresented =
            candidates.any((candidate) => candidate.deviceId == sourceId);
        final updatedAt = _payloadUpdatedAt(payload);
        if (sourceId != currentDeviceId &&
            !alreadyRepresented &&
            !_isUntouchedProgress(payload) &&
            hasDifferentReadingPosition(fingerprintedBook, payload) &&
            !await _hasHandledBookRevision(progressId, sourceId, updatedAt)) {
          candidates.add(_DeviceProgressCandidate(
            // This payload is physically stored in the historical shared
            // document even when newer fields identify its source device.
            deviceId: _legacyDeviceId,
            deviceName:
                payload['sourceDeviceName'] as String? ?? 'Autre appareil',
            payload: payload,
            updatedAt: updatedAt,
          ));
        }
      } catch (_) {
        // Ignore a legacy value that can no longer be decrypted.
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final selected = candidates.first;
    final remote = selected.payload;
    return BookSyncProposal(
      bookId: fingerprintedBook.id,
      progressId: progressId,
      remoteDeviceId: selected.deviceId,
      remoteDeviceName: selected.deviceName,
      localPage: fingerprintedBook.currentPage,
      localTotalPages: fingerprintedBook.totalPages,
      localChapterProgress: fingerprintedBook.epubChapterProgress,
      localUpdatedAt:
          fingerprintedBook.lastReadDate ?? fingerprintedBook.addedDate,
      remotePage: remote['currentPage'] as int? ?? 0,
      remoteTotalPages: remote['totalPages'] as int? ?? 0,
      remoteChapterProgress:
          (remote['epubChapterProgress'] as num?)?.toDouble() ?? 0.0,
      remoteUpdatedAt: selected.updatedAt,
      isEpub: remote['format'] == BookFormat.epub.name,
    );
  }

  /// Applies one book-scoped choice. Only the reading location is replaced;
  /// favorites and bookmarks stay local and continue to sync independently.
  Future<void> resolveBookProgress(
      BookSyncProposal proposal, BookProgressChoice choice) async {
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
    final progressReference =
        root.doc('progress').collection('files').doc(proposal.progressId);

    Map<String, dynamic>? remote;
    if (choice == BookProgressChoice.useRemote) {
      final reference = proposal.remoteDeviceId == _legacyDeviceId
          ? progressReference
          : progressReference
              .collection('devices')
              .doc(proposal.remoteDeviceId);
      final snapshot = await reference.get();
      if (!snapshot.exists) {
        throw StateError('Cette progression distante n’existe plus.');
      }
      remote = await _crypto.decryptJson(
        key: key,
        envelope:
            Map<String, dynamic>.from(snapshot.data()!['envelope'] as Map),
      );
      await _applyRemoteBookPosition(proposal.bookId, remote);
    }

    final books = await _database.getBooks();
    final local = books.where((book) => book.id == proposal.bookId).firstOrNull;
    if (local != null && choice != BookProgressChoice.ignore) {
      final fingerprintedBook = await _ensureFingerprint(local);
      final localPayload = await _progressPayload(fingerprintedBook);
      await _saveDeviceProgress(root, fingerprintedBook, key);
      await _write(progressReference, key, localPayload,
          resolvedAt: DateTime.now().toUtc());
      await _database.setLastSyncedAt('progress:${proposal.progressId}',
          DateTime.parse(localPayload['updatedAt'] as String));
    }

    await _markBookRevisionHandled(proposal);
  }

  /// Lists the current installation and the encrypted restore points uploaded
  /// by the other installations of the same account.
  Future<List<SyncDeviceBackup>> listDeviceBackups() async {
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
    final currentId = await _deviceId();
    final currentName = await currentDeviceName();
    final backups = <SyncDeviceBackup>[
      SyncDeviceBackup(
        id: currentId,
        label: 'Cet appareil — $currentName',
        isCurrentDevice: true,
      ),
    ];
    final snapshots =
        await root.doc('deviceBackups').collection('devices').get();
    for (final snapshot in snapshots.docs) {
      // Do not expose an unreadable/stale record in the chooser.
      late Map<String, dynamic> payload;
      try {
        payload = await _crypto.decryptJson(
          key: key,
          envelope:
              Map<String, dynamic>.from(snapshot.data()['envelope'] as Map),
        );
      } catch (_) {
        continue;
      }
      final savedAt = snapshot.data()['updatedAt'];
      final updatedAt = savedAt is Timestamp ? savedAt.toDate() : null;
      if (snapshot.id == currentId) {
        backups[0] = SyncDeviceBackup(
          id: currentId,
          label: 'Cet appareil — $currentName',
          isCurrentDevice: true,
          updatedAt: updatedAt,
        );
        continue;
      }
      backups.add(SyncDeviceBackup(
        id: snapshot.id,
        label: payload['deviceName'] as String? ??
            snapshot.data()['label'] as String? ??
            'Autre appareil',
        isCurrentDevice: false,
        updatedAt: updatedAt,
      ));
    }
    if (backups.length > 1) {
      final current = backups.removeAt(0);
      backups.sort((a, b) {
        final aTime = a.updatedAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.updatedAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
      backups.insert(0, current);
    }
    return backups;
  }

  /// Makes an explicitly selected device backup the new shared reference and
  /// applies it locally. This is never used by automatic synchronization.
  Future<void> restoreDeviceBackup(String deviceId) async {
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
    final reference =
        root.doc('deviceBackups').collection('devices').doc(deviceId);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      throw StateError('La sauvegarde de cet appareil est introuvable.');
    }
    final backup = await _crypto.decryptJson(
      key: key,
      envelope: Map<String, dynamic>.from(snapshot.data()!['envelope'] as Map),
    );
    final resolvedAt = DateTime.now().toUtc();
    await _restoreBackupDocument(
      root.doc('servers'),
      'servers',
      Map<String, dynamic>.from(backup['servers'] as Map),
      key,
      resolvedAt,
    );
    await _restoreBackupDocument(
      root.doc('settings'),
      'settings',
      Map<String, dynamic>.from(backup['settings'] as Map),
      key,
      resolvedAt,
    );
    for (final value in backup['progress'] as List) {
      final progress = Map<String, dynamic>.from(value as Map);
      final id = _progressIdFromPayload(progress);
      await _restoreBackupDocument(
        root.doc('progress').collection('files').doc(id),
        'progress:$id',
        progress,
        key,
        resolvedAt,
      );
    }
    await _saveDeviceBackup(root, key);
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
        if (hasProgressIdentity(fingerprintedBook) &&
            _progressId(fingerprintedBook) == progressId) {
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
    if (localId.startsWith('progress:')) {
      final localSource = local['sourceDeviceId'] as String?;
      final remoteSource = remote['sourceDeviceId'] as String?;
      if (localSource != remoteSource &&
          !_payloadsHaveSameReadingPosition(local, remote)) {
        // A background sync must never choose between two devices. The
        // decision is deferred until this specific book is opened.
        return;
      }
    }
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
          remoteUpdatedAt: remoteUpdated,
          localSummary: _conflictSummary(localId, local),
          remoteSummary: _conflictSummary(localId, remote)));
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
        (payload['epubChapterProgress'] as num? ?? 0) == 0 &&
        payload['isCompleted'] != true &&
        payload['isFavorite'] != true &&
        (bookmarks is! List || bookmarks.isEmpty);
  }

  String _conflictSummary(String documentId, Map<String, dynamic> payload) {
    if (documentId.startsWith('progress:')) {
      final page = payload['currentPage'] as int? ?? 0;
      final total = payload['totalPages'] as int? ?? 0;
      final isEpub = payload['format'] == BookFormat.epub.name;
      final bookmarks = payload['bookmarks'];
      final bookmarkCount = bookmarks is List ? bookmarks.length : 0;
      final favorite = payload['isFavorite'] == true ? 'oui' : 'non';
      final location =
          isEpub ? 'Chapitre ${page + 1}/$total' : 'Page $page/$total';
      return '$location · Favori : $favorite · '
          '$bookmarkCount marque-page${bookmarkCount > 1 ? 's' : ''}';
    }
    if (documentId == 'servers') {
      final servers = payload['servers'];
      final count = servers is List ? servers.length : 0;
      return '$count profil${count > 1 ? 's' : ''} de serveur';
    }
    return 'Réglages de lecture';
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

  Future<void> _restoreBackupDocument(
    DocumentReference<Map<String, dynamic>> reference,
    String documentId,
    Map<String, dynamic> payload,
    SecretKey key,
    DateTime resolvedAt,
  ) async {
    final restored = _withUpdatedAt(payload, resolvedAt);
    await _write(reference, key, restored, resolvedAt: resolvedAt);
    await _applyRemote(documentId, restored);
    await _database.setLastSyncedAt(documentId, resolvedAt);
  }

  DateTime _payloadUpdatedAt(Map<String, dynamic> payload) {
    final value = payload['updatedAt'] as String?;
    return value == null
        ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.parse(value).toUtc();
  }

  String _bookDecisionKey(String progressId, String deviceId) =>
      '$_bookDecisionPrefix$progressId.$deviceId';

  Future<bool> _hasHandledBookRevision(
      String progressId, String deviceId, DateTime updatedAt) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_bookDecisionKey(progressId, deviceId)) ==
        updatedAt.toUtc().toIso8601String();
  }

  Future<void> _markBookRevisionHandled(BookSyncProposal proposal) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _bookDecisionKey(proposal.progressId, proposal.remoteDeviceId),
      proposal.remoteUpdatedAt.toUtc().toIso8601String(),
    );
  }

  Future<void> _saveDeviceProgress(
    CollectionReference<Map<String, dynamic>> root,
    BookItem book,
    SecretKey key,
  ) async {
    final deviceId = await _deviceId();
    final payload = await _progressPayload(book);
    await root
        .doc('progress')
        .collection('files')
        .doc(_progressId(book))
        .collection('devices')
        .doc(deviceId)
        .set({
      'v': 1,
      'envelope': await _crypto.encryptJson(key: key, value: payload),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _applyRemoteBookPosition(
      String bookId, Map<String, dynamic> remote) async {
    final books = await _database.getBooks();
    final local = books.where((book) => book.id == bookId).firstOrNull;
    if (local == null) return;
    final currentPage = remote['currentPage'] as int? ?? 0;
    final totalPages = remote['totalPages'] as int? ?? local.totalPages;
    final chapterProgress =
        ((remote['epubChapterProgress'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 1.0)
            .toDouble();
    final progress = totalPages > 0
        ? ((currentPage +
                    (local.format == BookFormat.epub ? chapterProgress : 0)) /
                totalPages)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;
    final restored = local.copyWith(
      currentPage: currentPage,
      totalPages: totalPages,
      progress: progress,
      epubChapterProgress: chapterProgress,
      isCompleted: remote['isCompleted'] as bool? ?? local.isCompleted,
      lastReadDate: _payloadUpdatedAt(remote).toLocal(),
    );
    await _database.updateBook(restored, notifySync: false);
    _database.notifyRemoteBooksChanged();
  }

  Future<void> _saveDeviceBackup(
    CollectionReference<Map<String, dynamic>> root,
    SecretKey key,
  ) async {
    final deviceId = await _deviceId();
    final progress = <Map<String, dynamic>>[];
    for (final book in await _database.getBooks()) {
      final fingerprintedBook = await _ensureFingerprint(book);
      if (!hasProgressIdentity(fingerprintedBook)) continue;
      progress.add(await _progressPayload(fingerprintedBook));
    }
    await root.doc('deviceBackups').collection('devices').doc(deviceId).set({
      'v': 1,
      'envelope': await _crypto.encryptJson(
        key: key,
        value: {
          'deviceName': await currentDeviceName(),
          'servers': await _serversPayload(),
          'settings': await _settingsPayload(),
          'progress': progress,
        },
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _deviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final id = const Uuid().v4();
    await preferences.setString(_deviceIdKey, id);
    return id;
  }

  String _deviceLabel(String deviceId) =>
      'Appareil ${deviceId.substring(0, 4).toUpperCase()}';

  Future<Map<String, dynamic>> _serversPayload() async => {
        'updatedAt': (await _database.getSyncDomainUpdatedAt('servers'))
            .toUtc()
            .toIso8601String(),
        'servers': (await _database.getServers())
            .map((server) => server.toMap())
            .toList(),
      };

  Future<Map<String, dynamic>> _settingsPayload() async => {
        // A stable timestamp is essential: using "now" here made unchanged
        // settings look like a fresh edit on every device and repeatedly
        // raised the same conflict.
        'updatedAt': (await _database.getSyncDomainUpdatedAt('settings'))
            .toUtc()
            .toIso8601String(),
        'settings': await ReaderSettingsService().exportForSync(),
      };

  Future<Map<String, dynamic>> _progressPayload(BookItem book) async => {
        'updatedAt':
            (book.lastReadDate ?? book.addedDate).toUtc().toIso8601String(),
        'sourceDeviceId': await _deviceId(),
        'sourceDeviceName': await currentDeviceName(),
        'serverId': book.serverId,
        'serverRelativePath': book.serverRelativePath,
        'contentHash': book.contentHash,
        'currentPage': book.currentPage,
        'totalPages': book.totalPages,
        'format': book.format.name,
        'epubChapterProgress': book.epubChapterProgress,
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

  String _progressIdFromPayload(Map<String, dynamic> progress) {
    final hash = progress['contentHash'] as String?;
    if (hash != null && hash.isNotEmpty) return 'sha256_$hash';
    return base64UrlEncode(utf8.encode(
            '${progress['serverId']}|${progress['serverRelativePath']}'))
        .replaceAll('=', '');
  }

  Future<BookItem> _ensureFingerprint(BookItem book) async {
    if (book.contentHash != null && book.contentHash!.isNotEmpty) return book;
    final hash = await BookFingerprintService.sha256ForFile(book.localPath);
    if (hash == null) return book;
    final fingerprinted = book.copyWith(contentHash: hash);
    await _database.updateBook(fingerprinted, notifySync: false);
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
      _database.notifyRemoteSettingsChanged();
    } else if (localId.startsWith('progress:')) {
      final path = remote['serverRelativePath'] as String?;
      final server = remote['serverId'] as String?;
      final contentHash = remote['contentHash'] as String?;
      final currentPage = remote['currentPage'] as int;
      final totalPages = remote['totalPages'] as int;
      final epubChapterProgress =
          ((remote['epubChapterProgress'] as num?)?.toDouble() ?? 0.0)
              .clamp(0.0, 1.0)
              .toDouble();
      final books = await _database.getBooks();
      // An archive fingerprint is independent from the server profile. A
      // profile can legitimately have a different local id on another device
      // (for example when it was added before the first account sync), while
      // the downloaded archive is still the same book.
      final candidates = books.where((book) {
        if (contentHash != null && contentHash.isNotEmpty) {
          return book.contentHash == contentHash;
        }
        if (server == null || path == null) return false;
        return book.serverId == server && book.serverRelativePath == path;
      });
      var restoredAnyBook = false;
      for (final originalBook in candidates) {
        final progress = totalPages > 0
            ? ((currentPage +
                        (originalBook.format == BookFormat.epub
                            ? epubChapterProgress
                            : 0)) /
                    totalPages)
                .clamp(0.0, 1.0)
                .toDouble()
            : 0.0;
        final restored = originalBook.copyWith(
          currentPage: currentPage,
          totalPages: totalPages,
          progress: progress,
          epubChapterProgress: epubChapterProgress,
          isCompleted: remote['isCompleted'] as bool,
          bookmarks: List<int>.from(remote['bookmarks'] as List),
          isFavorite: remote['isFavorite'] as bool,
          lastReadDate: DateTime.parse(remote['updatedAt'] as String).toLocal(),
        );
        await _database.updateBook(restored, notifySync: false);
        restoredAnyBook = true;
        if (currentPage > 0) _database.notifyRestoredProgress(restored);
      }
      if (restoredAnyBook) _database.notifyRemoteBooksChanged();
    }
  }
}

class _DeviceProgressCandidate {
  const _DeviceProgressCandidate({
    required this.deviceId,
    required this.deviceName,
    required this.payload,
    required this.updatedAt,
  });

  final String deviceId;
  final String deviceName;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
}
