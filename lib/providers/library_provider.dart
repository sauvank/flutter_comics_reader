import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import '../models/book_item.dart';
import '../services/cbz_service.dart';
import '../services/database_service.dart';

enum LibraryFilter {
  all,
  inProgress,
  unread,
  completed,
  cbz,
  pdf,
}

enum LibrarySort {
  lastRead,
  title,
  dateAdded,
  progress,
}

class LibraryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<BookItem> _books = [];
  bool _isLoading = false;
  String _searchQuery = '';
  LibraryFilter _filter = LibraryFilter.all;
  LibrarySort _sort = LibrarySort.lastRead;
  int _totalStorageBytes = 0;

  List<BookItem> get books => _books;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  LibraryFilter get filter => _filter;
  LibrarySort get sort => _sort;
  int get totalStorageBytes => _totalStorageBytes;

  List<BookItem> get filteredBooks {
    var list = List<BookItem>.from(_books);

    // Apply format/status filter
    switch (_filter) {
      case LibraryFilter.all:
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
        list = list.where((b) => b.format == BookFormat.cbz || b.format == BookFormat.cbr).toList();
        break;
      case LibraryFilter.pdf:
        list = list.where((b) => b.format == BookFormat.pdf).toList();
        break;
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) => b.title.toLowerCase().contains(q) || b.originalFilename.toLowerCase().contains(q)).toList();
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
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
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

  List<BookItem> get recentBooks {
    final list = _books.where((b) => b.lastReadDate != null).toList();
    list.sort((a, b) => b.lastReadDate!.compareTo(a.lastReadDate!));
    return list.take(6).toList();
  }

  Future<void> loadLibrary() async {
    _isLoading = true;
    notifyListeners();

    _books = await _db.getBooks();
    _totalStorageBytes = await _db.calculateTotalLibraryStorage();

    _isLoading = false;
    notifyListeners();

    _extractMissingCovers();
  }

  void _extractMissingCovers() async {
    bool hasUpdates = false;
    final coversDir = await _db.getCoversDirectory();

    for (int i = 0; i < _books.length; i++) {
      final book = _books[i];
      if (book.coverPath == null || !File(book.coverPath!).existsSync()) {
        final targetCover = p.join(coversDir.path, '${book.id}.jpg');
        String? newCover;

        if (book.format == BookFormat.cbz || book.format == BookFormat.zip) {
          newCover = await CbzService.extractCover(
            cbzFilePath: book.localPath,
            targetCoverPath: targetCover,
          );
        } else if (book.format == BookFormat.pdf) {
          try {
            final doc = await PdfDocument.openFile(book.localPath);
            if (doc.pages.isNotEmpty) {
              final page = doc.pages.first;
              final pdfImage = await page.render(fullWidth: 600, fullHeight: 900);
              if (pdfImage != null) {
                final uiImage = await pdfImage.createImage();
                final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
                pdfImage.dispose();
                uiImage.dispose();
                if (byteData != null) {
                  final f = File(targetCover);
                  await f.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
                  newCover = targetCover;
                }
              }
            }
          } catch (_) {}
        }

        if (newCover != null && File(newCover).existsSync()) {
          final updated = book.copyWith(coverPath: newCover);
          await _db.updateBook(updated);
          _books[i] = updated;
          hasUpdates = true;
        }
      }
    }

    if (hasUpdates) {
      notifyListeners();
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
    bool? isCompleted,
  }) async {
    await _db.updateBookProgress(
      bookId: bookId,
      currentPage: currentPage,
      totalPages: totalPages,
      isCompleted: isCompleted,
    );
    await loadLibrary();
  }

  Future<void> toggleBookmark({required String bookId, required int pageNumber}) async {
    await _db.toggleBookmark(bookId: bookId, pageNumber: pageNumber);
    await loadLibrary();
  }

  Future<void> deleteBook(String bookId) async {
    await _db.deleteBook(bookId);
    await loadLibrary();
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
      return _books.firstWhere((b) => b.serverId == serverId && b.serverRelativePath == relativePath);
    } catch (_) {
      return null;
    }
  }
}
