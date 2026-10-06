import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_item.dart';
import 'local_book_import_service.dart';

/// Extracts and caches cover previews of books found by a device scan.
///
/// The files are not imported yet, so covers go to a temporary cache keyed by
/// path, size and modification date. Extraction runs on demand (only for
/// visible tiles) with a small parallelism limit to keep scrolling smooth.
class ScanCoverService {
  ScanCoverService._();

  static const _maxParallel = 2;
  static final _covers = <String, Future<String?>>{};
  static final _waiting = <Completer<void>>[];
  static int _running = 0;
  static Directory? _cacheDirectory;

  static Future<String?> coverFor(String path) =>
      _covers.putIfAbsent(path, () => _load(path));

  static Future<String?> _load(String path) async {
    try {
      final stat = await File(path).stat();
      final key = sha1
          .convert(utf8.encode(
              '$path|${stat.size}|${stat.modified.millisecondsSinceEpoch}'))
          .toString();
      final directory = await _directory();
      final target = p.join(directory.path, '$key.jpg');
      if (await File(target).exists()) return target;

      await _acquire();
      try {
        final metadata = await LocalBookImportService.readMetadata(
          path: path,
          format: BookItem.formatFromExtension(path),
          coverTarget: target,
        ).timeout(const Duration(seconds: 20));
        return metadata.coverPath;
      } finally {
        _release();
      }
    } catch (_) {
      return null;
    }
  }

  static Future<Directory> _directory() async {
    final cached = _cacheDirectory;
    if (cached != null) return cached;
    final directory =
        Directory(p.join((await getTemporaryDirectory()).path, 'scan_covers'));
    await directory.create(recursive: true);
    return _cacheDirectory = directory;
  }

  static Future<void> _acquire() async {
    if (_running < _maxParallel) {
      _running++;
      return;
    }
    final turn = Completer<void>();
    _waiting.add(turn);
    await turn.future;
  }

  static void _release() {
    if (_waiting.isNotEmpty) {
      // The slot is handed over directly, so [_running] stays unchanged.
      _waiting.removeAt(0).complete();
    } else {
      _running--;
    }
  }
}
