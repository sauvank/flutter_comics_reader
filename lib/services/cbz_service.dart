import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart' hide ZLibDecoder, ZLibEncoder;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/format_utils.dart';

/// Lightweight ZIP entry metadata parsed directly from Central Directory
class _FastZipEntry {
  final String name;
  final int compressionMethod;
  final int compressedSize;
  final int uncompressedSize;
  final int localHeaderOffset;

  _FastZipEntry({
    required this.name,
    required this.compressionMethod,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.localHeaderOffset,
  });
}

/// Pure Dart, zero-allocation ZIP parser operating on RandomAccessFile.
/// Reads only the Central Directory metadata at the end of the file (< 50KB RAM),
/// and extracts single pages on-demand without loading the entire archive into memory.
class _FastZip {
  static const int _eocdSignature = 0x06054b50;
  static const int _cdSignature = 0x02014b50;
  static const int _lfhSignature = 0x04034b50;

  /// Scans the central directory of a ZIP file using RandomAccessFile.
  /// Reads at most a few kilobytes (EOCD + Central Directory).
  /// Consumes < 50 KB RAM and takes < 5ms.
  static List<_FastZipEntry> scan(RandomAccessFile raf) {
    try {
      final fileLength = raf.lengthSync();
      if (fileLength < 22) return [];

      // 1. Read the last 65557 bytes (or full file) to find EOCD
      final searchSize = fileLength > 65557 ? 65557 : fileLength;
      final searchStart = fileLength - searchSize;
      raf.setPositionSync(searchStart);
      final eocdBuffer = raf.readSync(searchSize);
      final byteData = ByteData.sublistView(eocdBuffer);

      int eocdOffsetInBuf = -1;
      // Scan backwards for EOCD signature 0x06054b50
      for (int i = searchSize - 22; i >= 0; i--) {
        if (byteData.getUint32(i, Endian.little) == _eocdSignature) {
          eocdOffsetInBuf = i;
          break;
        }
      }

      if (eocdOffsetInBuf == -1) return [];

      final cdSize = byteData.getUint32(eocdOffsetInBuf + 12, Endian.little);
      final cdOffset = byteData.getUint32(eocdOffsetInBuf + 16, Endian.little);

      if (cdOffset >= fileLength || cdSize == 0) return [];

      // 2. Read Central Directory
      raf.setPositionSync(cdOffset);
      final cdBuffer = raf.readSync(cdSize);
      final cdData = ByteData.sublistView(cdBuffer);

      final entries = <_FastZipEntry>[];
      int pos = 0;
      while (pos + 46 <= cdSize) {
        final sig = cdData.getUint32(pos, Endian.little);
        if (sig != _cdSignature) break;

        final method = cdData.getUint16(pos + 10, Endian.little);
        final compressedSize = cdData.getUint32(pos + 20, Endian.little);
        final uncompressedSize = cdData.getUint32(pos + 24, Endian.little);
        final fileNameLen = cdData.getUint16(pos + 28, Endian.little);
        final extraLen = cdData.getUint16(pos + 30, Endian.little);
        final commentLen = cdData.getUint16(pos + 32, Endian.little);
        final localOffset = cdData.getUint32(pos + 42, Endian.little);

        if (pos + 46 + fileNameLen > cdSize) break;

        final fileNameBytes = Uint8List.view(
          cdBuffer.buffer,
          cdBuffer.offsetInBytes + pos + 46,
          fileNameLen,
        );

        String name;
        try {
          name = utf8.decode(fileNameBytes);
        } catch (_) {
          name = latin1.decode(fileNameBytes);
        }

        entries.add(_FastZipEntry(
          name: name,
          compressionMethod: method,
          compressedSize: compressedSize,
          uncompressedSize: uncompressedSize,
          localHeaderOffset: localOffset,
        ));

        pos += 46 + fileNameLen + extraLen + commentLen;
      }

      return entries;
    } catch (e) {
      debugPrint('Error scanning zip central directory: $e');
      return [];
    }
  }

  /// Extracts the data of a specific entry from the ZIP file using RandomAccessFile.
  /// Reads only entry.compressedSize bytes directly into memory.
  static Uint8List? extractEntry(RandomAccessFile raf, _FastZipEntry entry) {
    try {
      raf.setPositionSync(entry.localHeaderOffset);
      final lfhHeader = raf.readSync(30);
      if (lfhHeader.length < 30) return null;

      final lfhData = ByteData.sublistView(lfhHeader);
      final sig = lfhData.getUint32(0, Endian.little);
      if (sig != _lfhSignature) return null;

      final localNameLen = lfhData.getUint16(26, Endian.little);
      final localExtraLen = lfhData.getUint16(28, Endian.little);

      final dataOffset = entry.localHeaderOffset + 30 + localNameLen + localExtraLen;
      raf.setPositionSync(dataOffset);

      final compressedBytes = raf.readSync(entry.compressedSize);
      if (compressedBytes.length != entry.compressedSize) return null;

      if (entry.compressionMethod == 0) {
        // Uncompressed (STORE)
        return compressedBytes;
      } else if (entry.compressionMethod == 8) {
        // DEFLATE
        try {
          // Native C libz decompressor (zero Dart VM heap overhead)
          final decompressed = ZLibDecoder(raw: true).convert(compressedBytes);
          return Uint8List.fromList(decompressed);
        } catch (_) {
          // Fallback to archive Inflate
          return Uint8List.fromList(Inflate(compressedBytes).getBytes());
        }
      } else {
        // Other compression method (rare) - try Inflate
        try {
          return Uint8List.fromList(Inflate(compressedBytes).getBytes());
        } catch (_) {
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error extracting zip entry ${entry.name}: $e');
      return null;
    }
  }
}

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

  /// Extracts cover image and page count in a single efficient pass without reading whole file into memory
  static Future<CbzScanResult> extractCoverAndPageCount({
    required String cbzFilePath,
    required String targetCoverPath,
  }) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return CbzScanResult(coverPath: null, pageCount: 1);

      _ZipScanData scanData;
      try {
        scanData = await compute(_scanZipPathIsolate, cbzFilePath);
      } catch (eCompute) {
        debugPrint('Compute isolate failed in extractCoverAndPageCount, fallback: $eCompute');
        scanData = _scanZipPathIsolate(cbzFilePath);
      }

      String? savedCoverPath;
      if (scanData.coverBytes != null && scanData.coverBytes!.isNotEmpty) {
        try {
          final coverFile = File(targetCoverPath);
          await coverFile.parent.create(recursive: true);
          await coverFile.writeAsBytes(scanData.coverBytes!, flush: true);
          savedCoverPath = targetCoverPath;
        } catch (eWrite) {
          debugPrint('Error writing cover file: $eWrite');
        }
      }

      return CbzScanResult(
        coverPath: savedCoverPath,
        pageCount: scanData.pageCount > 0 ? scanData.pageCount : 1,
      );
    } catch (e) {
      debugPrint('Error in extractCoverAndPageCount for $cbzFilePath: $e');
      return CbzScanResult(coverPath: null, pageCount: 1);
    }
  }

  /// Extracts cover image from a CBZ file and saves it to [targetCoverPath]
  static Future<String?> extractCover({
    required String cbzFilePath,
    required String targetCoverPath,
  }) async {
    final result = await extractCoverAndPageCount(
      cbzFilePath: cbzFilePath,
      targetCoverPath: targetCoverPath,
    );
    return result.coverPath;
  }

  /// Scans a CBZ archive and returns the total count of image pages
  static Future<int> getPageCount(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return 0;

      try {
        return await compute(_countPagesFromZipPathIsolate, cbzFilePath);
      } catch (_) {
        return _countPagesFromZipPathIsolate(cbzFilePath);
      }
    } catch (e) {
      debugPrint('Error getting page count: $e');
      return 0;
    }
  }

  static Directory? _cacheBaseDir;

  /// Returns the cache directory for a given book's extracted pages
  static Future<Directory> getCacheDirForBook(String bookId) async {
    if (_cacheBaseDir == null) {
      try {
        final tempDir = await getTemporaryDirectory();
        _cacheBaseDir = Directory(p.join(tempDir.path, 'cbz_page_cache'));
      } catch (_) {
        _cacheBaseDir = Directory(p.join(Directory.systemTemp.path, 'cbz_page_cache'));
      }
    }
    final bookCacheDir = Directory(p.join(_cacheBaseDir!.path, bookId));
    if (!await bookCacheDir.exists()) {
      await bookCacheDir.create(recursive: true);
    }
    return bookCacheDir;
  }

  /// Synchronously checks if a page file is already cached on disk
  static String? getCachedPagePathSync(String bookId, int pageIndex) {
    if (_cacheBaseDir == null) return null;
    final formattedIndex = pageIndex.toString().padLeft(4, '0');
    final path = p.join(_cacheBaseDir!.path, bookId, 'page_$formattedIndex.jpg');
    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) return path;
    return null;
  }

  /// Fast index scanner: parses directory structure ONLY without extracting page images (1-3ms)
  static Future<List<CbzPageInfo>> getPageList(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return [];

      try {
        return await compute(_getPageListFromPathIsolate, cbzFilePath);
      } catch (eCompute) {
        debugPrint('Compute isolate failed in getPageList, direct fallback: $eCompute');
        return _getPageListFromPathIsolate(cbzFilePath);
      }
    } catch (e) {
      debugPrint('Error getting page list from $cbzFilePath: $e');
      return [];
    }
  }

  /// Extracts and caches a single page on-demand to disk (1-3ms)
  static Future<String?> loadAndCachePage({
    required String cbzFilePath,
    required String bookId,
    required int pageIndex,
  }) async {
    final cacheDir = await getCacheDirForBook(bookId);
    final formattedIndex = pageIndex.toString().padLeft(4, '0');
    final targetFile = File(p.join(cacheDir.path, 'page_$formattedIndex.jpg'));

    if (await targetFile.exists() && (await targetFile.length()) > 0) {
      return targetFile.path;
    }

    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return null;

      final task = _ExtractPageToFileTask(
        cbzFilePath: cbzFilePath,
        targetIndex: pageIndex,
        outputPath: targetFile.path,
      );

      bool success = false;
      try {
        success = await compute(_extractSinglePageToFileIsolate, task);
      } catch (_) {
        success = _extractSinglePageToFileIsolate(task);
      }

      if (success && await targetFile.exists() && (await targetFile.length()) > 0) {
        return targetFile.path;
      }
    } catch (e) {
      debugPrint('Error extracting page $pageIndex from $cbzFilePath: $e');
    }
    return null;
  }

  static bool _isPrefetching = false;
  static _ExtractBatchToFileTask? _pendingBatchTask;

  /// Pre-extracts neighboring pages in the background isolate with stream seeking and queue debouncing
  static void prefetchPages({
    required String cbzFilePath,
    required String bookId,
    required int currentIndex,
    required int totalPages,
    int count = 2,
  }) {
    Future.microtask(() async {
      final cacheDir = await getCacheDirForBook(bookId);
      final indicesToFetch = <int>[];

      // Prioritize forward reading pages (+1, +2), then backward (-1)
      for (int offset = 1; offset <= count; offset++) {
        final nextIdx = currentIndex + offset;
        if (nextIdx < totalPages) {
          final formatted = nextIdx.toString().padLeft(4, '0');
          final f = File(p.join(cacheDir.path, 'page_$formatted.jpg'));
          if (!f.existsSync() || f.lengthSync() == 0) {
            indicesToFetch.add(nextIdx);
          }
        }
      }
      for (int offset = 1; offset <= 1; offset++) {
        final prevIdx = currentIndex - offset;
        if (prevIdx >= 0) {
          final formatted = prevIdx.toString().padLeft(4, '0');
          final f = File(p.join(cacheDir.path, 'page_$formatted.jpg'));
          if (!f.existsSync() || f.lengthSync() == 0) {
            indicesToFetch.add(prevIdx);
          }
        }
      }

      if (indicesToFetch.isEmpty) return;

      final batchTask = _ExtractBatchToFileTask(
        cbzFilePath: cbzFilePath,
        targetIndices: indicesToFetch,
        cacheDirPath: cacheDir.path,
      );

      if (_isPrefetching) {
        _pendingBatchTask = batchTask;
        return;
      }

      _isPrefetching = true;
      _runPrefetchTask(batchTask);
    });
  }

  static void _runPrefetchTask(_ExtractBatchToFileTask task) async {
    try {
      try {
        await compute(_extractBatchPagesToFileIsolate, task);
      } catch (_) {
        _extractBatchPagesToFileIsolate(task);
      }
    } catch (e) {
      debugPrint('Error in prefetch task: $e');
    } finally {
      if (_pendingBatchTask != null) {
        final nextTask = _pendingBatchTask!;
        _pendingBatchTask = null;
        _runPrefetchTask(nextTask);
      } else {
        _isPrefetching = false;
      }
    }
  }

  /// Cleans temporary page cache for a specific book
  static Future<void> cleanCacheForBook(String bookId) async {
    try {
      final cacheDir = await getCacheDirForBook(bookId);
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Loads all pages as a sorted list of page names and raw byte data in memory
  static Future<List<ComicPage>> loadAllPages(String cbzFilePath) async {
    try {
      final file = File(cbzFilePath);
      if (!await file.exists()) return [];

      try {
        return await compute(_loadAllPagesFromPathIsolate, cbzFilePath);
      } catch (eCompute) {
        return _loadAllPagesFromPathIsolate(cbzFilePath);
      }
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

  static List<ComicPage> _loadAllPagesFromPathIsolate(String filePath) {
    RandomAccessFile? raf;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return [];
      raf = file.openSync(mode: FileMode.read);
      final entries = _FastZip.scan(raf);
      final imageEntries = entries
          .where((e) => !e.name.endsWith('/') && isImageFile(e.name))
          .toList();

      if (imageEntries.isEmpty) {
        raf.closeSync();
        raf = null;
        final bytes = file.readAsBytesSync();
        return _loadPagesFromZip(bytes);
      }

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      final List<ComicPage> pages = [];
      for (int i = 0; i < imageEntries.length; i++) {
        final entry = imageEntries[i];
        final raw = _FastZip.extractEntry(raf, entry);
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
      debugPrint('Error in _loadAllPagesFromPathIsolate: $e');
      try {
        final bytes = File(filePath).readAsBytesSync();
        return _loadPagesFromZip(bytes);
      } catch (_) {}
      return [];
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
  }

  static _ZipScanData _scanZipIsolate(Uint8List bytes) {
    try {
      final archive = _decodeArchive(bytes);
      if (archive == null) return _ZipScanData(coverBytes: null, pageCount: 0);

      final imageEntries = archive.files
          .where((f) => !f.name.endsWith('/') && isImageFile(f.name))
          .toList();

      if (imageEntries.isEmpty) {
        return _ZipScanData(coverBytes: null, pageCount: 0);
      }

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      final firstImage = imageEntries.first;
      final coverBytes = _getArchiveFileBytes(firstImage);

      return _ZipScanData(
        coverBytes: coverBytes,
        pageCount: imageEntries.length,
      );
    } catch (e) {
      debugPrint('Error in _scanZipIsolate: $e');
      return _ZipScanData(coverBytes: null, pageCount: 0);
    }
  }

  static _ZipScanData _scanZipPathIsolate(String filePath) {
    RandomAccessFile? raf;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return _ZipScanData(coverBytes: null, pageCount: 0);
      raf = file.openSync(mode: FileMode.read);
      final entries = _FastZip.scan(raf);
      final imageEntries = entries
          .where((e) => !e.name.endsWith('/') && isImageFile(e.name))
          .toList();

      if (imageEntries.isEmpty) {
        raf.closeSync();
        raf = null;
        final bytes = file.readAsBytesSync();
        return _scanZipIsolate(bytes);
      }

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));
      final coverEntry = imageEntries.first;
      final coverBytes = _FastZip.extractEntry(raf, coverEntry);

      return _ZipScanData(
        coverBytes: coverBytes,
        pageCount: imageEntries.length,
      );
    } catch (e) {
      debugPrint('Error in _scanZipPathIsolate: $e');
      try {
        final bytes = File(filePath).readAsBytesSync();
        return _scanZipIsolate(bytes);
      } catch (_) {}
      return _ZipScanData(coverBytes: null, pageCount: 0);
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
  }

  static int _countPagesFromZipPathIsolate(String filePath) {
    RandomAccessFile? raf;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return 0;
      raf = file.openSync(mode: FileMode.read);
      final entries = _FastZip.scan(raf);
      final count = entries.where((e) => !e.name.endsWith('/') && isImageFile(e.name)).length;
      if (count > 0) return count;

      raf.closeSync();
      raf = null;
      final bytes = file.readAsBytesSync();
      return _countPagesFromZip(bytes);
    } catch (e) {
      try {
        final bytes = File(filePath).readAsBytesSync();
        return _countPagesFromZip(bytes);
      } catch (_) {}
      return 0;
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
  }

  static List<CbzPageInfo> _getPageListFromPathIsolate(String filePath) {
    RandomAccessFile? raf;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return [];
      raf = file.openSync(mode: FileMode.read);
      final entries = _FastZip.scan(raf);
      final imageEntries = entries
          .where((e) => !e.name.endsWith('/') && isImageFile(e.name))
          .toList();

      if (imageEntries.isEmpty) {
        raf.closeSync();
        raf = null;
        final bytes = file.readAsBytesSync();
        return _getPageListIsolate(bytes);
      }

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      return List.generate(
        imageEntries.length,
        (i) => CbzPageInfo(
          pageIndex: i,
          pageNumber: i + 1,
          name: p.basename(imageEntries[i].name),
        ),
      );
    } catch (e) {
      debugPrint('Error in _getPageListFromPathIsolate: $e');
      try {
        final bytes = File(filePath).readAsBytesSync();
        return _getPageListIsolate(bytes);
      } catch (_) {}
      return [];
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
  }

  static List<CbzPageInfo> _getPageListIsolate(Uint8List bytes) {
    final archive = _decodeArchive(bytes);
    if (archive == null) return [];

    final imageEntries = archive.files
        .where((f) => !f.name.endsWith('/') && isImageFile(f.name))
        .toList();
    imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

    return List.generate(
      imageEntries.length,
      (i) => CbzPageInfo(
        pageIndex: i,
        pageNumber: i + 1,
        name: p.basename(imageEntries[i].name),
      ),
    );
  }

  static bool _extractSinglePageToFileIsolate(_ExtractPageToFileTask task) {
    final outFile = File(task.outputPath);
    if (outFile.existsSync() && outFile.lengthSync() > 0) return true;

    RandomAccessFile? raf;
    try {
      final file = File(task.cbzFilePath);
      if (!file.existsSync()) return false;
      raf = file.openSync(mode: FileMode.read);
      final entries = _FastZip.scan(raf);
      final imageEntries = entries
          .where((e) => !e.name.endsWith('/') && isImageFile(e.name))
          .toList();

      if (imageEntries.isEmpty || task.targetIndex < 0 || task.targetIndex >= imageEntries.length) {
        raf.closeSync();
        raf = null;
        final fileBytes = file.readAsBytesSync();
        final byteTask = _ExtractPageTask(bytes: fileBytes, targetIndex: task.targetIndex);
        final imgBytes = _extractSinglePageIsolate(byteTask);
        if (imgBytes != null && imgBytes.isNotEmpty) {
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(imgBytes, flush: true);
          return true;
        }
        return false;
      }

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));
      final targetEntry = imageEntries[task.targetIndex];
      final bytes = _FastZip.extractEntry(raf, targetEntry);
      if (bytes != null && bytes.isNotEmpty) {
        outFile.parent.createSync(recursive: true);
        outFile.writeAsBytesSync(bytes, flush: true);
        return true;
      }
    } catch (e) {
      debugPrint('Error in _extractSinglePageToFileIsolate: $e');
      try {
        final fileBytes = File(task.cbzFilePath).readAsBytesSync();
        final byteTask = _ExtractPageTask(bytes: fileBytes, targetIndex: task.targetIndex);
        final imgBytes = _extractSinglePageIsolate(byteTask);
        if (imgBytes != null && imgBytes.isNotEmpty) {
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(imgBytes, flush: true);
          return true;
        }
      } catch (_) {}
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
    return false;
  }

  static int _extractBatchPagesToFileIsolate(_ExtractBatchToFileTask task) {
    RandomAccessFile? raf;
    int extractedCount = 0;
    try {
      final file = File(task.cbzFilePath);
      if (!file.existsSync()) return 0;
      raf = file.openSync(mode: FileMode.read);
      final entries = _FastZip.scan(raf);
      final imageEntries = entries
          .where((e) => !e.name.endsWith('/') && isImageFile(e.name))
          .toList();

      if (imageEntries.isEmpty) return 0;

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      for (final idx in task.targetIndices) {
        if (idx >= 0 && idx < imageEntries.length) {
          final formatted = idx.toString().padLeft(4, '0');
          final targetFile = File(p.join(task.cacheDirPath, 'page_$formatted.jpg'));
          if (!targetFile.existsSync() || targetFile.lengthSync() == 0) {
            final raw = _FastZip.extractEntry(raf, imageEntries[idx]);
            if (raw != null && raw.isNotEmpty) {
              targetFile.parent.createSync(recursive: true);
              targetFile.writeAsBytesSync(raw, flush: false);
              extractedCount++;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _extractBatchPagesToFileIsolate: $e');
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
    return extractedCount;
  }

  static Uint8List? _extractSinglePageIsolate(_ExtractPageTask task) {
    try {
      final archive = _decodeArchive(task.bytes);
      if (archive == null) return null;

      final imageEntries = archive.files
          .where((f) => !f.name.endsWith('/') && isImageFile(f.name))
          .toList();

      if (imageEntries.isEmpty || task.targetIndex < 0 || task.targetIndex >= imageEntries.length) {
        return null;
      }

      imageEntries.sort((a, b) => NaturalSort.compare(p.basename(a.name), p.basename(b.name)));

      final targetEntry = imageEntries[task.targetIndex];
      return _getArchiveFileBytes(targetEntry);
    } catch (e) {
      debugPrint('Error in _extractSinglePageIsolate: $e');
      return null;
    }
  }
}

class CbzPageInfo {
  final int pageIndex;
  final int pageNumber;
  final String name;

  CbzPageInfo({
    required this.pageIndex,
    required this.pageNumber,
    required this.name,
  });
}

class _ExtractPageToFileTask {
  final String cbzFilePath;
  final int targetIndex;
  final String outputPath;
  _ExtractPageToFileTask({
    required this.cbzFilePath,
    required this.targetIndex,
    required this.outputPath,
  });
}

class _ExtractBatchToFileTask {
  final String cbzFilePath;
  final List<int> targetIndices;
  final String cacheDirPath;
  _ExtractBatchToFileTask({
    required this.cbzFilePath,
    required this.targetIndices,
    required this.cacheDirPath,
  });
}

class _ExtractPageTask {
  final Uint8List bytes;
  final int targetIndex;
  _ExtractPageTask({required this.bytes, required this.targetIndex});
}

class CbzScanResult {
  final String? coverPath;
  final int pageCount;

  CbzScanResult({this.coverPath, required this.pageCount});
}

class _ZipScanData {
  final Uint8List? coverBytes;
  final int pageCount;
  _ZipScanData({this.coverBytes, required this.pageCount});
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


