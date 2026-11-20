import 'dart:io';
import '../models/book_item.dart';
import '../utils/format_utils.dart';

class SeriesItem {
  final String name;
  final List<BookItem> books;

  SeriesItem({
    required this.name,
    required this.books,
  });

  int get totalBooks => books.length;
  int get completedBooks => books.where((b) => b.isCompleted).length;
  int get inProgressBooks =>
      books.where((b) => b.progress > 0 && !b.isCompleted).length;
  int get unreadBooks =>
      books.where((b) => b.progress == 0 && !b.isCompleted).length;
  bool get isCompleted => totalBooks > 0 && completedBooks == totalBooks;
  bool get hasFavorites => books.any((b) => b.isFavorite);

  double get overallProgress {
    if (books.isEmpty) return 0.0;
    final sum = books.fold<double>(0.0, (prev, b) => prev + b.progress);
    return sum / books.length;
  }

  BookItem? get latestReadBook {
    final withRead = books.where((b) => b.lastReadDate != null).toList();
    if (withRead.isEmpty) return null;
    withRead.sort((a, b) => b.lastReadDate!.compareTo(a.lastReadDate!));
    return withRead.first;
  }

  BookItem? get nextToReadBook {
    final inProgress =
        books.where((b) => b.progress > 0 && !b.isCompleted).toList();
    if (inProgress.isNotEmpty) return inProgress.first;

    final unread =
        books.where((b) => b.progress == 0 && !b.isCompleted).toList();
    if (unread.isNotEmpty) return unread.first;

    return books.isNotEmpty ? books.first : null;
  }

  /// Shelf the series sits on (BD, Manga, Comics US…), from the server folder
  /// above the series folder; null for local imports.
  late final String? category = _resolveCategory();

  String? _resolveCategory() {
    for (final b in books) {
      final c = categoryOf(b);
      if (c != null) return c;
    }
    return null;
  }

  static final RegExp _rootFolder = RegExp(
      r'^([a-z]:|books?|media|terabox\d*|root|home|dav|webdav|remote\.php|files)$',
      caseSensitive: false);

  /// `…/BOOKS/BD/XIII/XIII T01.cbz` → `BD`: the folder after `BOOKS` when
  /// present, otherwise the parent of the series folder.
  static String? categoryOf(BookItem book) {
    final parts = _folders(book);
    if (parts == null) return null;
    // At least shelf / series / file.
    if (parts.length < 3) return null;
    final books = parts.lastIndexWhere((p) => p.toLowerCase() == 'books');
    final i =
        books >= 0 && books < parts.length - 3 ? books + 1 : parts.length - 3;
    final c = parts[i].replaceAll('_', ' ').trim();
    if (c.isEmpty || _rootFolder.hasMatch(c)) return null;
    return c;
  }

  /// Path segments of the server path, or of the original local path of an
  /// imported file (Windows separators included); null when neither is known.
  static List<String>? _folders(BookItem book) {
    final server = book.serverRelativePath;
    final path = server != null && server.isNotEmpty ? server : book.sourcePath;
    if (path == null || path.isEmpty) return null;
    return path
        .split(RegExp(r'[/\\]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  /// Folders that hold unrelated files: never taken as a series name.
  static final RegExp _looseFolder = RegExp(
      r'^([a-z]:|downloads?|t[ée]l[ée]chargements|documents|desktop|bureau|'
      r'books?|livres|bd|manga|comics( us)?|users|home|root|onedrive)$',
      caseSensitive: false);

  /// Resolved once per instance: series cards read it several times per build
  /// and each lookup otherwise hits the file system synchronously.
  late final String? coverPath = _resolveCoverPath();

  String? _resolveCoverPath() {
    final latest = latestReadBook;
    if (latest?.coverPath != null && File(latest!.coverPath!).existsSync()) {
      return latest.coverPath;
    }
    for (final b in books) {
      if (b.coverPath != null && File(b.coverPath!).existsSync()) {
        return b.coverPath;
      }
    }
    return null;
  }

  static final RegExp _sepRegex = RegExp(
      r'^(.*?)\s*[-–—]\s*(?:Tome|Vol\.?|Volume|Book|Ch\.?|Chapitre|T|V|#|\d+)',
      caseSensitive: false);
  static final RegExp _volRegex = RegExp(
      r'^(.*?)\s+(?:Tome|Vol\.?|Volume|Book|#|T)\s*\d+',
      caseSensitive: false);

  /// Issue number at the end of a name: "Injustice 2 007" → "Injustice 2".
  /// Only 3 digits or a leading zero, so "Batman 1989" or "Spider-Man 2099"
  /// stay whole.
  static final RegExp _issueRegex = RegExp(r'^(.*\S)\s+(?:0\d+|\d{3})$');

  static String _stripIssue(String name) {
    final m = _issueRegex.firstMatch(name.trim());
    return m != null && m.group(1)!.trim().length >= 2
        ? m.group(1)!.trim()
        : name.trim();
  }

  static final RegExp _hashRegex =
      RegExp(r'^(.*?)\s*#\s*\d+', caseSensitive: false);

  /// Groups a list of books into series
  static List<SeriesItem> groupFromBooks(List<BookItem> books) {
    final Map<String, List<BookItem>> groups = {};

    for (final book in books) {
      final seriesName = _extractSeriesName(book);
      groups.putIfAbsent(seriesName, () => []).add(book);
    }

    final List<SeriesItem> result = [];
    for (final entry in groups.entries) {
      final sortedBooks = List<BookItem>.from(entry.value);
      sortedBooks.sort((a, b) => NaturalSort.compare(a.title, b.title));
      result.add(SeriesItem(name: entry.key, books: sortedBooks));
    }

    // Sort series alphabetically
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  static String _extractSeriesName(BookItem book) {
    final custom = book.customSeries?.trim();
    if (custom != null && custom.isNotEmpty) return custom;

    // 1. From the server folder, or the original folder of a local import
    final parts = _folders(book);
    if (parts != null && parts.length >= 2) {
      final folderName = parts[parts.length - 2].replaceAll('_', ' ').trim();
      if (folderName.isNotEmpty && !_looseFolder.hasMatch(folderName)) {
        return _stripIssue(folderName);
      }
    }

    // 2. Extract series from title patterns
    final title = book.title.trim();

    // e.g. "Spider-Man - Tome 01" -> "Spider-Man"
    final sepMatch = _sepRegex.firstMatch(title);
    if (sepMatch != null && sepMatch.group(1)!.trim().length >= 2) {
      return sepMatch.group(1)!.trim();
    }

    // e.g. "Batman Tome 01", "One Piece Vol 12", "Astérix T04"
    final volMatch = _volRegex.firstMatch(title);
    if (volMatch != null && volMatch.group(1)!.trim().length >= 2) {
      return volMatch.group(1)!.trim();
    }

    // e.g. "Dragon Ball #12"
    final hashMatch = _hashRegex.firstMatch(title);
    if (hashMatch != null && hashMatch.group(1)!.trim().length >= 2) {
      return hashMatch.group(1)!.trim();
    }

    // e.g. "Injustice 2 007"
    return _stripIssue(title);
  }
}
