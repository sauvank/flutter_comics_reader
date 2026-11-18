import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import '../models/book_item.dart';
import '../models/series_item.dart';
import '../services/cbz_service.dart';
import '../services/epub_service.dart';
import '../services/database_service.dart';
import '../services/local_book_import_service.dart';
import '../utils/format_utils.dart';

enum LibraryFilter {
  all,
  favorites,
  inProgress,
  unread,
  completed,
  cbz,
  pdf,
  epub,
}

enum LibrarySort {
  lastRead,
  title,
  dateAdded,
  progress,
}

class LibraryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  late final StreamSubscription<BookItem> _resumeRestoredSubscription;
  late final StreamSubscription<void> _remoteBooksChangedSubscription;

  List<BookItem> _books = [];
  Set<String> _favoriteRemoteKeys = {};
  bool _isLoading = false;
  String _searchQuery = '';
  LibraryFilter _filter = LibraryFilter.all;
  LibrarySort _sort = LibrarySort.lastRead;
  int _totalStorageBytes = 0;
  BookItem? _resumeSuggestion;
  bool _extractingCovers = false;

  // Derived views, rebuilt lazily after each change instead of on every build.
  List<BookItem>? _filteredBooksCache;
  List<SeriesItem>? _filteredSeriesCache;
  List<BookItem>? _recentBooksCache;

  LibraryProvider() {
    _resumeRestoredSubscription = _db.resumeRestored.listen((book) async {
      await loadLibrary();
      _resumeSuggestion =
          _books.where((candidate) => candidate.id == book.id).firstOrNull;
      notifyListeners();
    });
    _remoteBooksChangedSubscription = _db.remoteBooksChanged.listen((_) {
      loadLibrary();
    });
  }

  List<BookItem> get books => _books;
  Set<String> get favoriteRemoteKeys => _favoriteRemoteKeys;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  LibraryFilter get filter => _filter;
  LibrarySort get sort => _sort;
  int get totalStorageBytes => _totalStorageBytes;

  BookItem? takeResumeSuggestion() {
    final suggestion = _resumeSuggestion;
    _resumeSuggestion = null;
    return suggestion;
  }

  @override
  void notifyListeners() {
    _filteredBooksCache = null;
    _filteredSeriesCache = null;
    _recentBooksCache = null;
    super.notifyListeners();
  }

  /// Books matching the current filter, search and sort. The returned list is
  /// shared between callers until the next change and must not be modified.
  List<BookItem> get filteredBooks =>
      _filteredBooksCache ??= List.unmodifiable(_computeFilteredBooks());

  /// [filteredBooks] grouped into series.
  List<SeriesItem> get filteredSeries =>
      _filteredSeriesCache ??= SeriesItem.groupFromBooks(filteredBooks);

  List<BookItem> _computeFilteredBooks() {
    var list = List<BookItem>.from(_books);

    // Apply format/status filter
    switch (_filter) {
      case LibraryFilter.all:
        break;
      case LibraryFilter.favorites:
        list = list.where((b) => b.isFavorite).toList();
        break;
      case LibraryFilter.inProgress:
        list = list.where((b) => b.progress > 0 && !b.isCompleted).toList();
        break;
      case LibraryFilter.unread:
        list = list.where((b) => b.progress == 0 && !b.isCompleted).toList();
        break;
      case LibraryFilter.completed:
        list = list.where((b) => b.isCompleted).toList();
        break;
      case LibraryFilter.cbz:
        list = list
            .where(
                (b) => b.format == BookFormat.cbz || b.format == BookFormat.cbr)
            .toList();
        break;
      case LibraryFilter.pdf:
        list = list.where((b) => b.format == BookFormat.pdf).toList();
        break;
      case LibraryFilter.epub:
        list = list.where((b) => b.format == BookFormat.epub).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.originalFilename.toLowerCase().contains(q))
          .toList();
    }

    // Apply sort
    switch (_sort) {
      case LibrarySort.lastRead:
        list.sort((a, b) {
          if (a.lastReadDate == null && b.lastReadDate == null) {
            return b.addedDate.compareTo(a.addedDate);
          }
          if (a.lastReadDate == null) return 1;
          if (b.lastReadDate == null) return -1;
          return b.lastReadDate!.compareTo(a.lastReadDate!);
        });
        break;
      case LibrarySort.title:
        final keys = {for (final b in list) b.id: b.title.toLowerCase()};
        list.sort((a, b) => keys[a.id]!.compareTo(keys[b.id]!));
        break;
      case LibrarySort.dateAdded:
        list.sort((a, b) => b.addedDate.compareTo(a.addedDate));
        break;
      case LibrarySort.progress:
        list.sort((a, b) => b.progress.compareTo(a.progress));
        break;
    }

    return list;
  }

  List<BookItem> get recentBooks => _recentBooksCache ??= () {
        final list = _books.where((b) => b.lastReadDate != null).toList();
        list.sort((a, b) => b.lastReadDate!.compareTo(a.lastReadDate!));
        return List<BookItem>.unmodifiable(list.take(6));
      }();

  /// Finds the logically next volume in the library for the given book
  BookItem? getNextBook(BookItem currentBook) {
    if (_books.isEmpty) return null;
    final sorted = List<BookItem>.from(_books);
    sorted.sort((a, b) => NaturalSort.compare(a.title, b.title));
    final idx = sorted.indexWhere((b) => b.id == currentBook.id);
    if (idx >= 0 && idx < sorted.length - 1) {
      return sorted[idx + 1];
    }
    return null;
  }

  void addOrUpdateBook(BookItem book) {
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      _books[index] = book;
    } else {
      _books.insert(0, book);
    }
    _totalStorageBytes += book.fileSize;
    notifyListeners();
  }

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    _books = await _db.getBooks();
    _favoriteRemoteKeys = await _db.getFavoriteRemoteKeys();
    _totalStorageBytes = await _db.calculateTotalLibraryStorage();

    _isLoading = false;
    notifyListeners();

    _extractMissingCovers();
  }

  Future<void> _extractMissingCovers() async {
    // loadLibrary() is triggered from many places; a single pass is enough.
    if (_extractingCovers) return;
    _extractingCovers = true;
    try {
      await _extractMissingCoversPass();
    } finally {
      _extractingCovers = false;
    }
  }

  Future<void> _extractMissingCoversPass() async {
    final coversDir = await _db.getCoversDirectory();

    for (int i = 0; i < _books.length; i++) {
      final book = _books[i];
      if (book.coverPath == null || !await File(book.coverPath!).exists()) {
        final targetCover = p.join(coversDir.path, '${book.id}.jpg');
        String? newCover;

        if (book.format == BookFormat.cbz || book.format == BookFormat.zip) {
          newCover = await CbzService.extractCover(
            cbzFilePath: book.localPath,
            targetCoverPath: targetCover,
          );
        } else if (book.format == BookFormat.epub) {
          newCover = await EpubService.extractCover(
            epubFilePath: book.localPath,
            targetCoverPath: targetCover,
          );
        } else if (book.format == BookFormat.pdf) {
          try {
            final doc = await PdfDocument.openFile(book.localPath);
            if (doc.pages.isNotEmpty) {
              final page = doc.pages.first;
              final pdfImage =
                  await page.render(fullWidth: 600, fullHeight: 900);
              if (pdfImage != null) {
                final uiImage = await pdfImage.createImage();
                final byteData =
                    await uiImage.toByteData(format: ui.ImageByteFormat.png);
                pdfImage.dispose();
                uiImage.dispose();
                if (byteData != null) {
                  final f = File(targetCover);
                  await f.writeAsBytes(byteData.buffer.asUint8List(),
                      flush: true);
                  newCover = targetCover;
                }
              }
            }
          } catch (_) {}
        }

        if (newCover != null && await File(newCover).exists()) {
          final updated = book.copyWith(coverPath: newCover);
          await _db.updateBook(updated);
          // The list may have been reloaded while the cover was extracted.
          final index = _books.indexWhere((b) => b.id == book.id);
          if (index >= 0) {
            _books[index] = _books[index].copyWith(coverPath: newCover);
            notifyListeners();
          }
        }
      }
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(LibraryFilter newFilter) {
    _filter = newFilter;
    notifyListeners();
  }

  void setSort(LibrarySort newSort) {
    _sort = newSort;
    notifyListeners();
  }

  Future<void> updateBookProgress({
    required String bookId,
    required int currentPage,
    required int totalPages,
    double? epubChapterProgress,
    bool? isCompleted,
  }) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      final current = _books[index];
      final tot = totalPages > 0 ? totalPages : current.totalPages;
      final chapterProgress =
          (epubChapterProgress ?? current.epubChapterProgress)
              .clamp(0.0, 1.0)
              .toDouble();
      final prog = tot > 0
          ? ((currentPage +
                      (current.format == BookFormat.epub
                          ? chapterProgress
                          : 0)) /
                  tot)
              .clamp(0.0, 1.0)
              .toDouble()
          : 0.0;
      final completed = isCompleted ?? (prog >= 0.95);

      _books[index] = current.copyWith(
        currentPage: currentPage,
        totalPages: tot,
        progress: prog,
        epubChapterProgress: chapterProgress,
        isCompleted: completed,
        lastReadDate: DateTime.now(),
      );
      notifyListeners();
    }

    await _db.updateBookProgress(
      bookId: bookId,
      currentPage: currentPage,
      totalPages: totalPages,
      epubChapterProgress: epubChapterProgress,
      isCompleted: isCompleted,
    );
  }

  Future<void> updateBookFormat(String bookId, BookFormat format) async {
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      final updated = _books[index].copyWith(format: format);
      await _db.updateBook(updated);
      _books[index] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String bookId) async {
    await _db.toggleFavoriteBook(bookId);
    final index = _books.indexWhere((b) => b.id == bookId);
    if (index >= 0) {
      _books[index] =
          _books[index].copyWith(isFavorite: !_books[index].isFavorite);
      notifyListeners();
    }
  }

  bool isRemoteFavorite(String serverId, String remotePath) {
    final key = '$serverId:$remotePath';
    return _favoriteRemoteKeys.contains(key);
  }

  Future<void> toggleRemoteFavorite(String serverId, String remotePath) async {
    final key = '$serverId:$remotePath';
    if (_favoriteRemoteKeys.contains(key)) {
      _favoriteRemoteKeys.remove(key);
    } else {
      _favoriteRemoteKeys.add(key);
    }
    await _db.saveFavoriteRemoteKeys(_favoriteRemoteKeys);
    notifyListeners();
  }

  Future<void> toggleBookmark(
      {required String bookId, required int pageNumber}) async {
    await _db.toggleBookmark(bookId: bookId, pageNumber: pageNumber);
    // Only bookmarks changed: skip the storage scan and cover pass.
    _books = await _db.getBooks();
    notifyListeners();
  }

  /// Bulk actions of the library selection mode.
  Future<void> deleteBooks(Iterable<String> bookIds) async {
    for (final id in bookIds.toList()) {
      try {
        await _db.deleteBook(id);
      } catch (_) {
        // Already removed: keep deleting the others.
      }
    }
    await loadLibrary();
  }

  Future<void> setBooksCompleted(
      Iterable<String> bookIds, bool completed) async {
    for (final id in bookIds.toList()) {
      final book = getBookById(id);
      if (book == null) continue;
      await updateBookProgress(
        bookId: id,
        currentPage: completed ? book.totalPages : 0,
        totalPages: book.totalPages,
        isCompleted: completed,
      );
    }
  }

  Future<void> setBooksFavorite(Iterable<String> bookIds, bool favorite) async {
    for (final id in bookIds.toList()) {
      final book = getBookById(id);
      if (book != null && book.isFavorite != favorite) await toggleFavorite(id);
    }
  }

  /// Moves books to [series]; null or empty restores the automatic series.
  Future<void> moveBooksToSeries(
      Iterable<String> bookIds, String? series) async {
    final name = series?.trim();
    for (final id in bookIds.toList()) {
      final index = _books.indexWhere((b) => b.id == id);
      if (index < 0) continue;
      final updated = (name == null || name.isEmpty)
          ? _books[index].copyWith(clearCustomSeries: true)
          : _books[index].copyWith(customSeries: name);
      await _db.updateBook(updated);
      _books[index] = updated;
    }
    notifyListeners();
  }

  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
    await loadLibrary();
  }

  /// Adds user-selected files that were already present on this device.
  Future<LocalBookImportResult> importLocalFiles(Iterable<String> paths) async {
    final result =
        await LocalBookImportService(database: _db).importFiles(paths);
    await loadLibrary();
    return result;
  }

  /// Finds compatible books in a directory selected by the user.
  Future<List<String>> scanLocalDirectory(String directoryPath) {
    return LocalBookImportService.scanDirectory(directoryPath);
  }

  BookItem? getBookById(String bookId) {
    try {
      return _books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  BookItem? getBookByServerPath(String serverId, String relativePath) {
    try {
      return _books.firstWhere((b) =>
          b.serverId == serverId && b.serverRelativePath == relativePath);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _resumeRestoredSubscription.cancel();
    _remoteBooksChangedSubscription.cancel();
    super.dispose();
  }
}
