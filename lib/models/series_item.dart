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
  int get inProgressBooks => books.where((b) => b.progress > 0 && !b.isCompleted).length;
  int get unreadBooks => books.where((b) => b.progress == 0 && !b.isCompleted).length;
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
    final inProgress = books.where((b) => b.progress > 0 && !b.isCompleted).toList();
    if (inProgress.isNotEmpty) return inProgress.first;

    final unread = books.where((b) => b.progress == 0 && !b.isCompleted).toList();
    if (unread.isNotEmpty) return unread.first;

    return books.isNotEmpty ? books.first : null;
  }

  String? get coverPath {
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
    // 1. From serverRelativePath folder if present
    if (book.serverRelativePath != null && book.serverRelativePath!.isNotEmpty) {
      final clean = book.serverRelativePath!.replaceAll(RegExp(r'/+$'), '');
      final parts = clean.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        final folderName = parts[parts.length - 2].replaceAll('_', ' ').trim();
        if (folderName.isNotEmpty && folderName != '/' && folderName.toLowerCase() != 'root') {
          return folderName;
        }
      }
    }

    // 2. Extract series from title patterns
    final title = book.title.trim();

    // e.g. "Spider-Man - Tome 01" -> "Spider-Man"
    final sepRegex = RegExp(r'^(.*?)\s*[-–—]\s*(?:Tome|Vol\.?|Volume|Book|Ch\.?|Chapitre|T|V|#|\d+)', caseSensitive: false);
    final sepMatch = sepRegex.firstMatch(title);
    if (sepMatch != null && sepMatch.group(1)!.trim().length >= 2) {
      return sepMatch.group(1)!.trim();
    }

    // e.g. "Batman Tome 01", "One Piece Vol 12", "Astérix T04"
    final volRegex = RegExp(r'^(.*?)\s+(?:Tome|Vol\.?|Volume|Book|#|T)\s*\d+', caseSensitive: false);
    final volMatch = volRegex.firstMatch(title);
    if (volMatch != null && volMatch.group(1)!.trim().length >= 2) {
      return volMatch.group(1)!.trim();
    }

    // e.g. "Dragon Ball #12"
    final hashRegex = RegExp(r'^(.*?)\s*#\s*\d+', caseSensitive: false);
    final hashMatch = hashRegex.firstMatch(title);
    if (hashMatch != null && hashMatch.group(1)!.trim().length >= 2) {
      return hashMatch.group(1)!.trim();
    }

    return title;
  }
}
