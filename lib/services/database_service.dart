import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_item.dart';
import '../models/server_profile.dart';
import 'secure_server_credentials_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _keyBooks = 'library_books_json';
  static const String _keyServers = 'server_profiles_json';
  static const String _keyActiveServerId = 'active_server_id';

  SharedPreferences? _prefs;
  final SecureServerCredentialsService _credentials = SecureServerCredentialsService();
  final _syncChanges = StreamController<String>.broadcast();
  Stream<String> get syncChanges => _syncChanges.stream;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // Ensure base directories exist
    await getBooksDirectory();
    await getCoversDirectory();
  }

  Future<Directory> getBooksDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(docsDir.path, 'comics_library', 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  Future<Directory> getCoversDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docsDir.path, 'comics_library', 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir;
  }

  // --- Books Management ---

  Future<List<BookItem>> getBooks() async {
    await init();
    final jsonString = _prefs?.getString(_keyBooks);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return list.map((e) => BookItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBooks(List<BookItem> books) async {
    await init();
    final list = books.map((b) => b.toMap()).toList();
    await _prefs?.setString(_keyBooks, jsonEncode(list));
  }

  Future<void> addBook(BookItem book) async {
    final books = await getBooks();
    final existingIndex = books.indexWhere((b) => b.id == book.id);
    if (existingIndex >= 0) {
      books[existingIndex] = book;
    } else {
      books.add(book);
    }
    await saveBooks(books);
  }

  Future<void> updateBook(BookItem book) async {
    await addBook(book);
  }

  Future<void> updateBookProgress({
    required String bookId,
    required int currentPage,
    required int totalPages,
    bool? isCompleted,
  }) async {
    final books = await getBooks();
    final index = books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      final current = books[index];
      final tot = totalPages > 0 ? totalPages : current.totalPages;
      final prog = tot > 0 ? (currentPage / tot).clamp(0.0, 1.0) : 0.0;
      final completed = isCompleted ?? (prog >= 0.95);

      books[index] = current.copyWith(
        currentPage: currentPage,
        totalPages: tot,
        progress: prog,
        isCompleted: completed,
        lastReadDate: DateTime.now(),
      );
      await saveBooks(books);
      _syncChanges.add('progress');
    }
  }

  Future<void> toggleBookmark({required String bookId, required int pageNumber}) async {
    final books = await getBooks();
    final index = books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      final current = books[index];
      final bookmarks = List<int>.from(current.bookmarks);
      if (bookmarks.contains(pageNumber)) {
        bookmarks.remove(pageNumber);
      } else {
        bookmarks.add(pageNumber);
        bookmarks.sort();
      }
      books[index] = current.copyWith(bookmarks: bookmarks);
      await saveBooks(books);
      _syncChanges.add('progress');
    }
  }

  Future<void> toggleFavoriteBook(String bookId) async {
    final books = await getBooks();
    final index = books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      final current = books[index];
      books[index] = current.copyWith(isFavorite: !current.isFavorite);
      await saveBooks(books);
      _syncChanges.add('progress');
    }
  }

  static const String _keyFavoriteRemoteKeys = 'favorite_remote_paths_json';

  Future<Set<String>> getFavoriteRemoteKeys() async {
    await init();
    final jsonString = _prefs?.getString(_keyFavoriteRemoteKeys);
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      return Set<String>.from(list.map((e) => e.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveFavoriteRemoteKeys(Set<String> keys) async {
    await init();
    await _prefs?.setString(_keyFavoriteRemoteKeys, jsonEncode(keys.toList()));
  }

  Future<void> deleteBook(String bookId) async {
    final books = await getBooks();
    final book = books.firstWhere((b) => b.id == bookId, orElse: () => throw Exception('Not found'));

    // Delete local file
    final file = File(book.localPath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete cover file if exists
    if (book.coverPath != null) {
      final cover = File(book.coverPath!);
      if (await cover.exists()) {
        await cover.delete();
      }
    }

    books.removeWhere((b) => b.id == bookId);
    await saveBooks(books);
  }

  // --- Server Profiles ---

  Future<List<ServerProfile>> getServers() async {
    await init();
    final jsonString = _prefs?.getString(_keyServers);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
      final servers = <ServerProfile>[];
      for (final item in list) {
        final map = Map<String, dynamic>.from(item as Map);
        // One-time migration from legacy unprotected preferences.
        final legacyPassword = map['password'] as String?;
        final id = map['id'] as String;
        if (legacyPassword != null && legacyPassword.isNotEmpty) {
          await _credentials.save(id, legacyPassword);
        }
        map['password'] = await _credentials.read(id);
        servers.add(ServerProfile.fromMap(map));
      }
      // Re-save migrated profiles without their password in SharedPreferences.
      await saveServers(servers);
      return servers;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveServers(List<ServerProfile> servers) async {
    await init();
    for (final server in servers) {
      await _credentials.save(server.id, server.password);
    }
    final list = servers.map((s) {
      final map = s.toMap();
      map['password'] = null;
      return map;
    }).toList();
    await _prefs?.setString(_keyServers, jsonEncode(list));
  }

  Future<void> saveServer(ServerProfile server) async {
    final servers = await getServers();
    final idx = servers.indexWhere((s) => s.id == server.id);
    if (idx >= 0) {
      servers[idx] = server;
    } else {
      servers.add(server);
    }
    await saveServers(servers);
    await touchSyncDomain('servers');
    _syncChanges.add('servers');
  }

  Future<void> deleteServer(String serverId) async {
    final servers = await getServers();
    servers.removeWhere((s) => s.id == serverId);
    await saveServers(servers);
    await _credentials.delete(serverId);
    await touchSyncDomain('servers');
    _syncChanges.add('servers');
  }

  Future<String?> getActiveServerId() async {
    await init();
    return _prefs?.getString(_keyActiveServerId);
  }

  Future<void> setActiveServerId(String id) async {
    await init();
    await _prefs?.setString(_keyActiveServerId, id);
  }

  // --- Synchronization metadata (never sent to the backend) ---

  String _syncTimestampKey(String documentId) => 'sync.last_seen.$documentId';

  Future<DateTime?> getLastSyncedAt(String documentId) async {
    await init();
    final value = _prefs?.getString(_syncTimestampKey(documentId));
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setLastSyncedAt(String documentId, DateTime timestamp) async {
    await init();
    await _prefs?.setString(_syncTimestampKey(documentId), timestamp.toUtc().toIso8601String());
  }

  static const _syncDomainPrefix = 'sync.domain.updated.';

  Future<DateTime> getSyncDomainUpdatedAt(String domain) async {
    await init();
    final value = _prefs?.getString('$_syncDomainPrefix$domain');
    return value == null ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true) : DateTime.parse(value);
  }

  Future<void> touchSyncDomain(String domain) async {
    await init();
    await _prefs?.setString('$_syncDomainPrefix$domain', DateTime.now().toUtc().toIso8601String());
  }

  // --- Storage calculation ---

  Future<int> calculateTotalLibraryStorage() async {
    final books = await getBooks();
    var total = 0;
    for (final book in books) {
      final file = File(book.localPath);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }
}
