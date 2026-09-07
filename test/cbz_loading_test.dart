import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:comic_reader_app/services/cbz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late String bookId;
  late File file;
  late List<Uint8List> pages;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cbz_queue_');
    bookId = temp.uri.pathSegments.where((part) => part.isNotEmpty).last;
    pages = List.generate(
        4,
        (page) => Uint8List.fromList(
            List.generate(256 * 1024, (index) => (index + page * 7) % 256)));
    final archive = Archive();
    // Deliberately unsorted input, different bytes on every page.
    for (final (index, name) in [
      (3, 'page10'),
      (1, 'page2'),
      (0, 'page1'),
      (2, 'page3')
    ]) {
      archive
          .addFile(ArchiveFile('$name.jpg', pages[index].length, pages[index]));
    }
    file = File('${temp.path}/comic.cbz');
    await file.writeAsBytes(
        ZipEncoder().encode(archive, level: DeflateLevel.bestCompression));
  });

  tearDown(() async {
    await CbzService.cleanCacheForBook(bookId);
    await temp.delete(recursive: true);
  });

  Future<String?> load(int index,
          [CbzPagePriority priority = CbzPagePriority.visible]) =>
      CbzService.loadAndCachePage(
        cbzFilePath: file.path,
        bookId: bookId,
        pageIndex: index,
        priority: priority,
      );

  test(
      'simultaneous requests share extraction and publish complete pages in natural order',
      () async {
    final first = load(3);
    final duplicate = load(3);
    expect(identical(first, duplicate), isTrue);
    final results =
        await Future.wait([first, load(0), load(2), load(1), duplicate]);
    for (final (position, index) in [(0, 3), (1, 0), (2, 2), (3, 1), (4, 3)]) {
      final path = results[position]!;
      expect(await File(path).readAsBytes(), pages[index]);
      expect(CbzService.getCachedPagePathSync(bookId, index), path);
      expect(await File('$path.part').exists(), isFalse);
    }
  });

  test(
      'visible pages overtake queued thumbnails and obsolete prefetch is cancelled',
      () async {
    final completed = <int>[];
    final active = load(0).then((path) {
      completed.add(0);
      return path;
    });
    final thumbnail = load(1, CbzPagePriority.thumbnail).then((path) {
      completed.add(1);
      return path;
    });
    final obsolete = load(2, CbzPagePriority.prefetch);
    final foreground = load(3, CbzPagePriority.prefetch);
    expect(identical(foreground, load(3)), isTrue);
    final promoted = foreground.then((path) {
      completed.add(3);
      return path;
    });
    CbzService.cancelPrefetch(bookId);
    expect(await obsolete, isNull);
    final results = await Future.wait([active, thumbnail, promoted]);
    expect(results, everyElement(isNotNull));
    expect(completed, [0, 3, 1]);
    expect(CbzService.getCachedPagePathSync(bookId, 2), isNull);
  });

  test(
      'invalid requests do not stall following pages and cache cleanup invalidates paths',
      () async {
    expect(await load(-1), isNull);
    expect(await load(100), isNull);
    final path = await load(1);
    expect(await File(path!).readAsBytes(), pages[1]);
    await CbzService.cleanCacheForBook(bookId);
    expect(CbzService.getCachedPagePathSync(bookId, 1), isNull);
    expect(await File((await load(1))!).readAsBytes(), pages[1]);
  });

  test('pages evicted from temporary storage are extracted again', () async {
    final cached = (await load(2))!;
    await File(cached).delete();
    expect(await File((await load(2))!).readAsBytes(), pages[2]);
  });
}
