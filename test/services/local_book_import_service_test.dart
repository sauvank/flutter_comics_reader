import 'dart:io';

import 'package:comic_reader_app/services/local_book_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes the formats available for device import', () {
    expect(LocalBookImportService.isSupportedPath('album.cbz'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.cbr'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.zip'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.pdf'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.epub'), isTrue);
    expect(LocalBookImportService.isSupportedPath('album.jpg'), isFalse);
  });

  test('scans supported books in nested directories', () async {
    final directory = await Directory.systemTemp.createTemp('comic_stream_');
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/album.cbz').writeAsBytes([]);
    await Directory('${directory.path}/series').create();
    await File('${directory.path}/series/tome.epub').writeAsBytes([]);
    await File('${directory.path}/cover.jpg').writeAsBytes([]);

    final paths = await LocalBookImportService.scanDirectory(directory.path);

    expect(paths, hasLength(2));
    expect(paths, contains(endsWith('album.cbz')));
    expect(paths, contains(endsWith('tome.epub')));
  });
}
