import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/book_item.dart';
import '../../models/server_profile.dart';
import '../database_service.dart';
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
  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  final DatabaseService _database;
  final VaultService _vault;
  final CryptoService _crypto;
  final GoogleSignIn _googleSignIn;

  User? get user => _auth.currentUser;
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<UserCredential> createAccount({required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    bool canAuthenticateNatively = false;
    try {
      canAuthenticateNatively = _googleSignIn.supportsAuthenticate();
    } catch (_) {
      canAuthenticateNatively = false;
    }

    if (canAuthenticateNatively) {
      await FirebaseBootstrap.ensureGoogleSignInInitialized();
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

    return _auth.signInWithProvider(GoogleAuthProvider());
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  /// Checks whether this device has unlocked its local encryption key.
  Future<bool> hasLocalKey() => _vault.hasLocalVault();

  /// Checks whether a remote vault exists in Firestore for the current user.
  Future<bool> hasRemoteVault() async {
    final currentUser = user;
    if (currentUser == null) return false;
    try {
      final snapshot = await _firestore.doc('users/${currentUser.uid}/private/vault').get();
      return snapshot.exists;
    } catch (_) {
      return false;
    }
  }

  /// Creates a device vault. Call once after the user has safely recorded a
  /// recovery phrase; the phrase is not persisted on this device.
  Future<void> createVault(String recoveryPhrase) async {
    if (recoveryPhrase.trim().length < 16) {
      throw ArgumentError('La phrase de récupération doit comporter au moins 16 caractères.');
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
    final snapshot = await _firestore.doc('users/${currentUser.uid}/private/vault').get();
    final data = snapshot.data();
    if (data == null) throw StateError('Aucun coffre de synchronisation trouvé.');
    final recovery = await _vault.recoveryKey(recoveryPhrase, salt: data['salt'] as String);
    final value = await _crypto.decryptJson(key: recovery, envelope: Map<String, dynamic>.from(data['envelope'] as Map));
    await _vault.saveLocalKey(await _crypto.keyFromBytes(base64Url.decode(value['masterKey'] as String)));
  }

  Future<List<SyncConflict>> syncNow() async {
    final currentUser = user;
    final key = await _vault.readLocalKey();
    if (currentUser == null) throw StateError('Connexion requise');
    if (key == null) throw StateError('Phrase de récupération requise sur cet appareil.');
    final conflicts = <SyncConflict>[];
    final root = _firestore.collection('users').doc(currentUser.uid).collection('private');

    await _syncDocument(root.doc('servers'), 'servers', await _serversPayload(), key, conflicts, 'Configurations de serveurs');
    await _syncDocument(root.doc('settings'), 'settings', await _settingsPayload(), key, conflicts, 'Paramètres de lecture');
    for (final book in await _database.getBooks()) {
      if (book.serverId == null || book.serverRelativePath == null) continue;
      final id = _progressId(book);
      await _syncDocument(root.doc('progress').collection('files').doc(id), 'progress:$id', _progressPayload(book), key, conflicts, book.title);
    }
    return conflicts;
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
    final remote = await _crypto.decryptJson(key: key, envelope: Map<String, dynamic>.from(snapshot.data()!['envelope'] as Map));
    final remoteUpdated = DateTime.parse(remote['updatedAt'] as String);
    final lastSynced = await _database.getLastSyncedAt(localId);
    final localChanged = lastSynced == null || localUpdated.isAfter(lastSynced);
    final remoteChanged = lastSynced == null || remoteUpdated.isAfter(lastSynced);
    if (localChanged && remoteChanged && localUpdated != remoteUpdated) {
      conflicts.add(SyncConflict(documentId: localId, label: label, localUpdatedAt: localUpdated, remoteUpdatedAt: remoteUpdated));
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

  Future<void> _write(DocumentReference<Map<String, dynamic>> reference, SecretKey key, Map<String, dynamic> payload) async {
    await reference.set({
      'v': 1,
      'envelope': await _crypto.encryptJson(key: key, value: payload),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> _serversPayload() async => {
        'updatedAt': (await _database.getSyncDomainUpdatedAt('servers')).toUtc().toIso8601String(),
        'servers': (await _database.getServers()).map((server) => server.toMap()).toList(),
      };

  Future<Map<String, dynamic>> _settingsPayload() async => {
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'settings': await ReaderSettingsService().exportForSync(),
      };

  Map<String, dynamic> _progressPayload(BookItem book) => {
        'updatedAt': (book.lastReadDate ?? book.addedDate).toUtc().toIso8601String(),
        'serverId': book.serverId,
        'serverRelativePath': book.serverRelativePath,
        'currentPage': book.currentPage,
        'totalPages': book.totalPages,
        'isCompleted': book.isCompleted,
        'bookmarks': book.bookmarks,
        'isFavorite': book.isFavorite,
      };

  String _progressId(BookItem book) => base64UrlEncode(utf8.encode('${book.serverId}|${book.serverRelativePath}')).replaceAll('=', '');

  Future<void> _applyRemote(String localId, Map<String, dynamic> remote) async {
    if (localId == 'servers') {
      await _database.saveServers((remote['servers'] as List).map((value) => ServerProfile.fromMap(Map<String, dynamic>.from(value as Map))).toList());
    } else if (localId == 'settings') {
      await ReaderSettingsService().applyFromSync(Map<String, dynamic>.from(remote['settings'] as Map));
    } else if (localId.startsWith('progress:')) {
      final path = remote['serverRelativePath'] as String;
      final server = remote['serverId'] as String;
      final books = await _database.getBooks();
      for (final book in books.where((b) => b.serverId == server && b.serverRelativePath == path)) {
        await _database.updateBook(book.copyWith(
          currentPage: remote['currentPage'] as int,
          totalPages: remote['totalPages'] as int,
          isCompleted: remote['isCompleted'] as bool,
          bookmarks: List<int>.from(remote['bookmarks'] as List),
          isFavorite: remote['isFavorite'] as bool,
          lastReadDate: DateTime.parse(remote['updatedAt'] as String).toLocal(),
        ));
      }
    }
  }
}
