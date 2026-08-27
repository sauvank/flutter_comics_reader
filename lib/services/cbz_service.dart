import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:unrar_file/unrar_file.dart';
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

  /// Extracts cover image from a CBZ/CBR file and saves it to [targetCoverPath]
  static Future<String?> extractCover({
    required String cbzFilePath,
    required String targetCoverPath,
  }) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      var coverBytes = await compute(_extractCoverBytesFromZip, bytes);

      // Fallback: If Zip decoder returned null, try RAR extraction for CBR files
      if (coverBytes == null || coverBytes.isEmpty) {
        coverBytes = await _extractCoverFromRar(cbzFilePath);
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

  /// Scans CBZ/CBR archive and returns the total count of image pages
  static Future<int> getPageCount(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return 0;

      final bytes = await file.readAsBytes();
      var count = await compute(_countPagesFromZip, bytes);

      if (count == 0) {
        final pages = await _loadPagesFromRar(cbzFilePath);
        count = pages.length;
      }

      return count;
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

      // If it's a directory of images
      if (FileSystemEntity.isDirectorySync(cbzFilePath)) {
        return _loadPagesFromDirectory(Directory(cbzFilePath));
      }

      final bytes = await file.readAsBytes();
      var pages = await compute(_loadPagesFromZip, bytes);

      // Fallback: If Zip decoder produced 0 images, try RAR extractor (for CBR files)
      if (pages.isEmpty) {
        pages = await _loadPagesFromRar(cbzFilePath);
      }

      return pages;
    } catch (e) {
      debugPrint('Error loading CBZ/CBR pages: $e');
      try {
        return await _loadPagesFromRar(cbzFilePath);
      } catch (_) {
        return [];
      }
    }
  }

  // --- Directory loading ---
  static Future<List<ComicPage>> _loadPagesFromDirectory(Directory dir) async {
    final imageFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => isImageFile(f.path))
        .toList();

    imageFiles.sort((a, b) => NaturalSort.compare(p.basename(a.path), p.basename(b.path)));

    final List<ComicPage> pages = [];
    for (int i = 0; i < imageFiles.length; i++) {
      final f = imageFiles[i];
      final raw = await f.readAsBytes();
      pages.add(ComicPage(
        pageIndex: i,
        pageNumber: i + 1,
        name: p.basename(f.path),
        bytes: raw,
      ));
    }
    return pages;
  }

  // --- RAR / CBR extraction fallback ---
  static Future<List<ComicPage>> _loadPagesFromRar(String filePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final key = filePath.hashCode.toRadixString(16);
      final extractDir = Directory(p.join(tempDir.path, 'cbr_$key'));

      if (!await extractDir.exists() || extractDir.listSync().isEmpty) {
        await extractDir.create(recursive: true);
        await UnrarFile.extract_rar(filePath, extractDir.path);
      }

      return await _loadPagesFromDirectory(extractDir);
    } catch (e) {
      debugPrint('RAR extraction error on $filePath: $e');
      return [];
    }
  }

  static Future<Uint8List?> _extractCoverFromRar(String filePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final key = filePath.hashCode.toRadixString(16);
      final extractDir = Directory(p.join(tempDir.path, 'cbr_$key'));

      if (!await extractDir.exists() || extractDir.listSync().isEmpty) {
        await extractDir.create(recursive: true);
        await UnrarFile.extract_rar(filePath, extractDir.path);
      }

      final imageFiles = extractDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => isImageFile(f.path))
          .toList();

      if (imageFiles.isEmpty) return null;
      imageFiles.sort((a, b) => NaturalSort.compare(p.basename(a.path), p.basename(b.path)));

      return await imageFiles.first.readAsBytes();
    } catch (e) {
      debugPrint('RAR cover extraction error on $filePath: $e');
      return null;
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
        if (content is InputStream) {
          return content.toUint8List();
        }
      }
    } catch (_) {}
    return null;
  }

  static Uint8List? _extractCoverBytesFromZip(Uint8List bytes) {
    try {
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes, verify: false);
      } catch (_) {
        try {
          archive = TarDecoder().decodeBytes(bytes);
        } catch (_) {
          return null;
        }
      }

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
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes, verify: false);
      } catch (_) {
        try {
          archive = TarDecoder().decodeBytes(bytes);
        } catch (_) {
          return 0;
        }
      }
      return archive.files.where((f) => !f.name.endsWith('/') && isImageFile(f.name)).length;
    } catch (e) {
      return 0;
    }
  }

  static List<ComicPage> _loadPagesFromZip(Uint8List bytes) {
    try {
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes, verify: false);
      } catch (_) {
        try {
          archive = TarDecoder().decodeBytes(bytes);
        } catch (_) {
          return [];
        }
      }

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
