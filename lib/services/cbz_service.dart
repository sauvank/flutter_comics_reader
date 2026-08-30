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
    '.jfif',
    '.jxl',
    '.tif',
    '.tiff',
  };

  static bool isImageFile(String filename) {
    final normalized = filename.replaceAll('\\', '/');
    final base = p.basename(normalized);
    if (normalized.startsWith('__MACOSX') ||
        normalized.contains('/__MACOSX') ||
        base.startsWith('.') ||
        base.toLowerCase() == 'thumbs.db') {
      return false;
    }
    final ext = p.extension(base).toLowerCase();
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
      Uint8List? coverBytes;
      try {
        coverBytes = await compute(_extractCoverBytesFromZip, bytes);
      } catch (_) {
        coverBytes = _extractCoverBytesFromZip(bytes);
      }
      if (coverBytes == null || coverBytes.isEmpty) return null;

      final coverFile = File(targetCoverPath);
      await coverFile.parent.create(recursive: true);
      await coverFile.writeAsBytes(coverBytes, flush: true);

      return targetCoverPath;
    } catch (e) {
      debugPrint('Error extracting cover from $cbzFilePath: $e');
      return null;
    }
  }

  /// Scans a CBZ archive and returns the total count of image pages
  static Future<int> getPageCount(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return 0;

      final bytes = await file.readAsBytes();
      try {
        return await compute(_countPagesFromZip, bytes);
      } catch (_) {
        return _countPagesFromZip(bytes);
      }
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
      List<ComicPage> pages = [];
      try {
        pages = await compute(_loadPagesFromZip, bytes);
      } catch (eCompute) {
        debugPrint('Compute isolate failed, falling back to direct parse: $eCompute');
        pages = _loadPagesFromZip(bytes);
      }

      return pages;
    } catch (e) {
      debugPrint('Error loading CBZ pages: $e');
      return [];
    }
  }

  // --- Top-level Isolate worker functions ---

  static Uint8List? _getArchiveFileBytes(ArchiveFile entry) {
    try {
      final raw = entry.readBytes();
      if (raw != null && raw.isNotEmpty) {
        return Uint8List.fromList(raw);
      }
      final dynamic content = entry.content;
      if (content != null) {
        if (content is List<int>) {
          return Uint8List.fromList(content);
        }
        try {
          return (content as dynamic).toUint8List() as Uint8List?;
        } catch (_) {}
      }
      final dynamic rawContent = entry.rawContent;
      if (rawContent != null) {
        if (rawContent is List<int>) return Uint8List.fromList(rawContent);
        try {
          return (rawContent as dynamic).toUint8List() as Uint8List?;
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  static Archive? _decodeArchive(Uint8List bytes) {
    // 1. Try standard ZipDecoder with verify: false
    try {
      return ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (_) {}

    // 2. Try TarDecoder
    try {
      return TarDecoder().decodeBytes(bytes);
    } catch (_) {}

    // 3. Try GZipDecoder wrapping Tar
    try {
      final uncompressed = GZipDecoder().decodeBytes(bytes);
      return TarDecoder().decodeBytes(uncompressed);
    } catch (_) {}

    // 4. Try BZip2Decoder wrapping Tar
    try {
      final uncompressed = BZip2Decoder().decodeBytes(bytes);
      return TarDecoder().decodeBytes(uncompressed);
    } catch (_) {}

    return null;
  }

  static Uint8List? _extractCoverBytesFromZip(Uint8List bytes) {
    try {
      final archive = _decodeArchive(bytes);
      if (archive == null) return null;

      final imageEntries = archive.files
          .where((f) => !f.name.endsWith('/') && isImageFile(f.name))
          .toList();
      if (imageEntries.isEmpty) return null;

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      final firstImage = imageEntries.first;
      return _getArchiveFileBytes(firstImage);
    } catch (e) {
      debugPrint('Error extracting cover bytes: $e');
      return null;
    }
  }

  static int _countPagesFromZip(Uint8List bytes) {
    try {
      final archive = _decodeArchive(bytes);
      if (archive == null) return 0;
      return archive.files.where((f) => !f.name.endsWith('/') && isImageFile(f.name)).length;
    } catch (e) {
      return 0;
    }
  }

  static List<ComicPage> _loadPagesFromZip(Uint8List bytes) {
    try {
      final archive = _decodeArchive(bytes);
      if (archive == null) return [];

      final imageEntries = archive.files
          .where((f) => !f.name.endsWith('/') && isImageFile(f.name))
          .toList();
      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      final List<ComicPage> pages = [];
      for (int i = 0; i < imageEntries.length; i++) {
        final entry = imageEntries[i];
        final raw = _getArchiveFileBytes(entry);
        if (raw == null || raw.isEmpty) continue;

        pages.add(ComicPage(
          pageIndex: i,
          pageNumber: i + 1,
          name: p.basename(entry.name),
          bytes: raw,
        ));
      }
      return pages;
    } catch (e) {
      debugPrint('Error loading pages from zip: $e');
      return [];
    }
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
