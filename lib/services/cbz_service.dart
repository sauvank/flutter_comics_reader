import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../utils/format_utils.dart';

class CbzService {
  static const Set<String> supportedImageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.avif',
  };

  static bool isImageFile(String filename) {
    if (filename.startsWith('__MACOSX') ||
        filename.contains('/.') ||
        filename.startsWith('.') ||
        filename.toLowerCase().contains('thumbs.db')) {
      return false;
    }
    final ext = p.extension(filename).toLowerCase();
    return supportedImageExtensions.contains(ext);
  }

  /// Extracts cover image from a CBZ file and saves it to [targetCoverPath]
  static Future<String?> extractCover({
    required String cbzFilePath,
    required String targetCoverPath,
  }) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final archive = await compute(_decodeZipArchive, bytes);

      // Find all image files
      final imageEntries = archive.files.where((f) => f.isFile && isImageFile(f.name)).toList();
      if (imageEntries.isEmpty) return null;

      // Sort naturally
      imageEntries.sort((a, b) => NaturalSort.compare(a.name, b.name));

      final firstImage = imageEntries.first;
      final rawBytes = firstImage.readBytes();
      if (rawBytes == null) return null;

      final imageBytes = rawBytes;

      final coverFile = File(targetCoverPath);
      await coverFile.parent.create(recursive: true);
      await coverFile.writeAsBytes(imageBytes);

      return targetCoverPath;
    } catch (e) {
      debugPrint('Error extracting cover from $cbzFilePath: $e');
      return null;
    }
  }

  /// Scans CBZ archive and returns the total count of image pages
  static Future<int> getPageCount(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return 0;

      final bytes = await file.readAsBytes();
      final archive = await compute(_decodeZipArchive, bytes);

      final imageEntries = archive.files.where((f) => f.isFile && isImageFile(f.name)).toList();
      return imageEntries.length;
    } catch (e) {
      debugPrint('Error getting page count: $e');
      return 0;
    }
  }

  /// Loads all pages as a sorted list of page names and raw byte data in memory
  static Future<List<ComicPage>> loadAllPages(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return [];

      final bytes = await file.readAsBytes();
      final archive = await compute(_decodeZipArchive, bytes);

      final imageEntries = archive.files.where((f) => f.isFile && isImageFile(f.name)).toList();
      imageEntries.sort((a, b) => NaturalSort.compare(a.name, b.name));

      final List<ComicPage> pages = [];
      for (int i = 0; i < imageEntries.length; i++) {
        final entry = imageEntries[i];
        final rawBytes = entry.readBytes();
        if (rawBytes == null) continue;

        final pageBytes = rawBytes;

        pages.add(ComicPage(
          pageIndex: i,
          pageNumber: i + 1,
          name: p.basename(entry.name),
          bytes: pageBytes,
        ));
      }

      return pages;
    } catch (e) {
      debugPrint('Error loading CBZ pages: $e');
      return [];
    }
  }

  // Top-level / static function for compute isolate
  static Archive _decodeZipArchive(Uint8List bytes) {
    return ZipDecoder().decodeBytes(bytes, verify: false);
  }
}

class ComicPage {
  final int pageIndex;
  final int pageNumber;
  final String name;
  final Uint8List bytes;

  ComicPage({
    required this.pageIndex,
    required this.pageNumber,
    required this.name,
    required this.bytes,
  });
}
