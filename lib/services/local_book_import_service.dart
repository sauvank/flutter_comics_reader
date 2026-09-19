import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:uuid/uuid.dart';

import '../models/book_item.dart';
import 'book_fingerprint_service.dart';
import 'cbz_service.dart';
import 'database_service.dart';
import 'epub_service.dart';

class LocalBookImportResult {
  const LocalBookImportResult({
    required this.imported,
    required this.skipped,
  });

  final int imported;
  final int skipped;
}

/// Imports user-selected files into the app's own storage.
///
/// Android grants durable access only to documents explicitly selected by the
/// user. Copying them also means that a later cache cleanup cannot make a book
/// disappear from the library.
class LocalBookImportService {
  LocalBookImportService({DatabaseService? database})
      : _database = database ?? DatabaseService();

  final DatabaseService _database;

  static bool isSupportedPath(String path) =>
      BookItem.formatFromExtension(path) != BookFormat.unknown;

  Future<LocalBookImportResult> importFiles(
      Iterable<String> sourcePaths) async {
    var imported = 0;
    var skipped = 0;
    final known = await _database.getBooks();
    final booksDirectory = await _database.getBooksDirectory();
    final coversDirectory = await _database.getCoversDirectory();

    for (final sourcePath in sourcePaths.toSet()) {
      final source = File(sourcePath);
      final format = BookItem.formatFromExtension(sourcePath);
      if (format == BookFormat.unknown || !await source.exists()) {
        skipped++;
        continue;
      }
      final size = await source.length();
      final fileName = p.basename(sourcePath);
      final contentHash =
          await BookFingerprintService.sha256ForFile(sourcePath);
      // Do not copy the same picked document twice into the library. A content
      // hash avoids treating two different books with the same filename as one.
      if (contentHash != null &&
          known.any((book) => book.contentHash == contentHash)) {
        skipped++;
        continue;
      }

      final id = 'local_${const Uuid().v4()}';
      final destination =
          p.join(booksDirectory.path, '$id${p.extension(fileName)}');
      try {
        await source.copy(destination);
        final metadata = await _readMetadata(
          id: id,
          path: destination,
          format: format,
          coversDirectory: coversDirectory,
        );
        final book = BookItem(
          id: id,
          title: p.basenameWithoutExtension(fileName).replaceAll('_', ' '),
          originalFilename: fileName,
          localPath: destination,
          coverPath: metadata.coverPath,
          format: format,
          totalPages: metadata.totalPages,
          addedDate: DateTime.now(),
          fileSize: size,
          contentHash: contentHash,
        );
        await _database.addBook(book);
        known.add(book);
        imported++;
      } catch (_) {
        try {
          await File(destination).delete();
        } catch (_) {}
        skipped++;
      }
    }
    return LocalBookImportResult(imported: imported, skipped: skipped);
  }

  Future<({String? coverPath, int totalPages})> _readMetadata({
    required String id,
    required String path,
    required BookFormat format,
    required Directory coversDirectory,
  }) async {
    final coverTarget = p.join(coversDirectory.path, '$id.jpg');
    if (format == BookFormat.cbz ||
        format == BookFormat.zip ||
        format == BookFormat.cbr) {
      final result = await CbzService.extractCoverAndPageCount(
        cbzFilePath: path,
        targetCoverPath: coverTarget,
      ).timeout(const Duration(seconds: 12));
      return (coverPath: result.coverPath, totalPages: result.pageCount);
    }
    if (format == BookFormat.epub) {
      final result = await EpubService.extractCoverAndPageCount(
        epubFilePath: path,
        targetCoverPath: coverTarget,
      ).timeout(const Duration(seconds: 12));
      return (coverPath: result.coverPath, totalPages: result.pageCount);
    }
    if (format == BookFormat.pdf) {
      final document =
          await PdfDocument.openFile(path).timeout(const Duration(seconds: 10));
      try {
        String? coverPath;
        if (document.pages.isNotEmpty) {
          final image = await document.pages.first
              .render(fullWidth: 600, fullHeight: 900)
              .timeout(const Duration(seconds: 8));
          if (image != null) {
            final rendered = await image.createImage();
            final bytes =
                await rendered.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            rendered.dispose();
            if (bytes != null) {
              await File(coverTarget).writeAsBytes(
                bytes.buffer.asUint8List(),
                flush: true,
              );
              coverPath = coverTarget;
            }
          }
        }
        return (coverPath: coverPath, totalPages: document.pages.length);
      } finally {
        await document.dispose();
      }
    }
    return (coverPath: null, totalPages: 1);
  }
}
