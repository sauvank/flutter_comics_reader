import 'dart:io';
import 'dart:ui' as ui;
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/book_item.dart';
import '../services/cbz_service.dart';
import '../services/database_service.dart';
import '../services/reader_settings_service.dart';
import '../utils/format_utils.dart';

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
            final channelOrder = isBgra ? img.ChannelOrder.bgra : img.ChannelOrder.rgba;
            final image = img.Image.fromBytes(
              width: pdfImage.width,
              height: pdfImage.height,
              bytes: pdfImage.pixels.buffer,
              numChannels: 4,
              order: channelOrder,
            );
            final jpgBytes = img.encodeJpg(image, quality: 88);
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

      final archive = Archive();
      for (final imageFile in generatedImages) {
        final fileBytes = await imageFile.readAsBytes();
        archive.addFile(ArchiveFile(
          p.basename(imageFile.path),
          fileBytes.length,
          fileBytes,
        ));
      }

      final encodedZip = ZipEncoder().encode(archive);
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
