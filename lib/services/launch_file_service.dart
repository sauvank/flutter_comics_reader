import 'dart:io';

import '../models/book_item.dart';
import 'book_fingerprint_service.dart';
import 'database_service.dart';
import 'local_book_import_service.dart';

/// Opens a book passed on the command line, which is how Windows hands over a
/// file when the app is the default reader (double-click or « Ouvrir avec »).
class LaunchFileService {
  LaunchFileService({DatabaseService? database, LocalBookImportService? importer})
      : _database = database ?? DatabaseService(),
        _importer = importer ??
            LocalBookImportService(database: database ?? DatabaseService());

  final DatabaseService _database;
  final LocalBookImportService _importer;

  /// First argument that is an existing book file, or null.
  static String? bookPathFromArgs(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith('-')) continue;
      if (LocalBookImportService.isSupportedPath(arg) && File(arg).existsSync()) {
        return arg;
      }
    }
    return null;
  }

  /// Returns the library entry for [path], importing the file when it is not
  /// in the library yet. The same content is never imported twice.
  Future<BookItem?> resolveBook(String path) async {
    final hash = await BookFingerprintService.sha256ForFile(path);
    final existing = await _findByHash(hash, path);
    if (existing != null) return existing;

    await _importer.importFiles([path]);
    return _findByHash(hash, path);
  }

  Future<BookItem?> _findByHash(String? hash, String path) async {
    final books = await _database.getBooks();
    for (final book in books) {
      if (hash != null && book.contentHash == hash) return book;
      if (book.localPath == path) return book;
    }
    return null;
  }
}
