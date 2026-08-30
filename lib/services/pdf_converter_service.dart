import 'dart:io';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/book_item.dart';
import '../services/cbz_service.dart';
import '../services/database_service.dart';
import '../services/reader_settings_service.dart';
import '../utils/format_utils.dart';

class _JpgTask {
  final int width;
  final int height;
  final Uint8List pixels;
  final bool isBgra;
  final int quality;

  _JpgTask({
    required this.width,
    required this.height,
    required this.pixels,
    required this.isBgra,
    required this.quality,
  });
}

Uint8List _encodeJpgIsolate(_JpgTask params) {
  final image = img.Image.fromBytes(
    width: params.width,
    height: params.height,
    bytes: params.pixels.buffer,
    numChannels: 4,
    order: params.isBgra ? img.ChannelOrder.bgra : img.ChannelOrder.rgba,
  );
  return img.encodeJpg(image, quality: params.quality);
}

class _ArchiveItem {
  final String name;
  final List<int> bytes;
  _ArchiveItem({required this.name, required this.bytes});
}

List<int> _encodeZipIsolate(List<_ArchiveItem> items) {
  final archive = Archive();
  for (final item in items) {
    archive.addFile(ArchiveFile(item.name, item.bytes.length, item.bytes));
  }
  return ZipEncoder().encode(archive);
}

class PdfConverterProgress {
  final int currentPage;
  final int totalPages;
  final double progress; // 0.0 to 1.0
  final String statusText;
  final BookItem? convertedBook;

  PdfConverterProgress({
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.statusText,
    this.convertedBook,
  });
}

class PdfConverterService {
  static final PdfConverterService _instance = PdfConverterService._internal();
  factory PdfConverterService() => _instance;
  PdfConverterService._internal();

  /// Converts a local PDF file into a standard CBZ comic archive with high-speed supersampled HD rendering
  Stream<PdfConverterProgress> convertPdfToCbz({
    required String pdfFilePath,
    String? outputCbzPath,
    double? targetDpiScale, // Supersampled resolution matching user preference (default 2.6x ~ 2600px)
    bool registerInDatabase = true,
    BookItem? originalBook,
  }) async* {
    final pdfFile = File(pdfFilePath);
    if (!await pdfFile.exists()) {
      throw Exception('Fichier PDF introuvable : $pdfFilePath');
    }

    final effectiveScale = targetDpiScale ?? ReaderSettingsService().pdfDpiScale;

    final doc = await PdfDocument.openFile(pdfFilePath);
    final totalPages = doc.pages.length;

    if (totalPages == 0) {
      throw Exception('Le fichier PDF ne contient aucune page.');
    }

    yield PdfConverterProgress(
      currentPage: 0,
      totalPages: totalPages,
      progress: 0.0,
      statusText: 'Initialisation de la conversion ($totalPages pages)...',
    );

    final baseName = p.basenameWithoutExtension(pdfFilePath);

    // Output path in user documents/comics directory
    String targetPath = outputCbzPath ?? '';
    if (targetPath.isEmpty) {
      final db = DatabaseService();
      final booksDir = await db.getBooksDirectory();
      targetPath = p.join(booksDir.path, '$baseName.cbz');
    }

    final tempDir = await getTemporaryDirectory();
    final conversionTempDir = Directory(p.join(tempDir.path, 'pdf_cbz_${DateTime.now().millisecondsSinceEpoch}'));
    await conversionTempDir.create(recursive: true);

    try {
      for (int i = 0; i < totalPages; i++) {
        final page = doc.pages[i];
        final pageNum = i + 1;

        yield PdfConverterProgress(
          currentPage: pageNum,
          totalPages: totalPages,
          progress: (i / totalPages) * 0.85,
          statusText: 'Rendu HD page $pageNum / $totalPages...',
        );

        // Render page with optimal HD resolution maintaining aspect ratio (800-2000px width)
        final renderWidth = (page.width * effectiveScale).round().clamp(800, 2000);
        final renderHeight = (page.height * effectiveScale).round().clamp(1000, 2800);

        final pdfImage = await page.render(
          fullWidth: renderWidth.toDouble(),
          fullHeight: renderHeight.toDouble(),
        );

        if (pdfImage != null) {
          final formattedIndex = pageNum.toString().padLeft(4, '0');
          final pageFile = File(p.join(conversionTempDir.path, 'page_$formattedIndex.jpg'));

          try {
            final isBgra = pdfImage.format.name.toLowerCase().contains('bgra');
            final task = _JpgTask(
              width: pdfImage.width,
              height: pdfImage.height,
              pixels: pdfImage.pixels,
              isBgra: isBgra,
              quality: 88,
            );

            // Execute heavy JPEG compression in a background isolate to keep UI 100% fluid
            final jpgBytes = await compute(_encodeJpgIsolate, task);
            await pageFile.writeAsBytes(jpgBytes, flush: true);
          } catch (eImg) {
            // Fallback via Flutter ui.Image to PNG with accurate offset & length
            final uiImage = await pdfImage.createImage();
            final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
            uiImage.dispose();
            if (byteData != null) {
              final pngBytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
              final fallbackFile = File(p.join(conversionTempDir.path, 'page_$formattedIndex.png'));
              await fallbackFile.writeAsBytes(pngBytes, flush: true);
            }
          } finally {
            pdfImage.dispose();
          }

          // Small yield to let Flutter's UI engine breathe and render frames smoothly
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      yield PdfConverterProgress(
        currentPage: totalPages,
        totalPages: totalPages,
        progress: 0.90,
        statusText: 'Compression de l\'archive CBZ standard...',
      );

      final generatedImages = conversionTempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png') || f.path.endsWith('.jpeg'))
          .toList();
      generatedImages.sort((a, b) => NaturalSort.compare(p.basename(a.path), p.basename(b.path)));

      if (generatedImages.isEmpty) {
        throw Exception('Aucune page n\'a pu être générée depuis le PDF.');
      }

      final items = <_ArchiveItem>[];
      for (final imageFile in generatedImages) {
        final fileBytes = await imageFile.readAsBytes();
        items.add(_ArchiveItem(
          name: p.basename(imageFile.path),
          bytes: fileBytes,
        ));
      }

      // Execute ZIP compression in background isolate
      final encodedZip = await compute(_encodeZipIsolate, items);
      if (encodedZip.isEmpty) {
        throw Exception('Échec de l\'encodage de l\'archive CBZ.');
      }

      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await targetFile.parent.create(recursive: true);
      await targetFile.writeAsBytes(encodedZip, flush: true);

      yield PdfConverterProgress(
        currentPage: totalPages,
        totalPages: totalPages,
        progress: 0.95,
        statusText: 'Finalisation et extraction de la couverture...',
      );

      BookItem? newBook;
      if (registerInDatabase) {
        final db = DatabaseService();
        final coversDir = await db.getCoversDirectory();
        final bookId = originalBook?.id ?? 'cbz_${DateTime.now().millisecondsSinceEpoch}';
        final coverPath = p.join(coversDir.path, '$bookId.jpg');

        await CbzService.extractCover(
          cbzFilePath: targetPath,
          targetCoverPath: coverPath,
        );

        if (originalBook != null) {
          newBook = originalBook.copyWith(
            localPath: targetPath,
            originalFilename: p.basename(targetPath),
            format: BookFormat.cbz,
            coverPath: File(coverPath).existsSync() ? coverPath : originalBook.coverPath,
            totalPages: totalPages,
            fileSize: File(targetPath).existsSync() ? await File(targetPath).length() : originalBook.fileSize,
          );
          await db.updateBook(newBook);
        } else {
          newBook = BookItem(
            id: bookId,
            title: baseName,
            originalFilename: p.basename(targetPath),
            localPath: targetPath,
            coverPath: File(coverPath).existsSync() ? coverPath : null,
            format: BookFormat.cbz,
            totalPages: totalPages,
            currentPage: 0,
            progress: 0.0,
            isCompleted: false,
            addedDate: DateTime.now(),
            fileSize: File(targetPath).existsSync() ? await File(targetPath).length() : 0,
            bookmarks: [],
          );
          await db.addBook(newBook);
        }
      }

        yield PdfConverterProgress(
          currentPage: totalPages,
          totalPages: totalPages,
          progress: 1.0,
          statusText: 'Conversion terminée avec succès !',
          convertedBook: newBook,
        );
    } finally {
      await doc.dispose();
      if (await conversionTempDir.exists()) {
        await conversionTempDir.delete(recursive: true).catchError((_) => conversionTempDir);
      }
    }
  }
}
