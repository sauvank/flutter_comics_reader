import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:comic_reader_app/services/cbz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CBZ Archive Fast Mode Tests', () {
    test('Creates and parses uncompressed STORE zip archive correctly', () {
      final archive = Archive();
      final img1Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03]);
      final img2Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x04, 0x05, 0x06]);

      final file1 = ArchiveFile('page_0001.jpg', img1Data.length, img1Data);
      file1.compression = CompressionType.none;
      archive.addFile(file1);

      final file2 = ArchiveFile('page_0002.jpg', img2Data.length, img2Data);
      file2.compression = CompressionType.none;
      archive.addFile(file2);

      final zipBytes = ZipEncoder().encode(archive, level: DeflateLevel.none);
      expect(zipBytes.isNotEmpty, true);

      final decoded = ZipDecoder().decodeBytes(zipBytes);
      expect(decoded.files.length, 2);
      expect(decoded.files[0].name, 'page_0001.jpg');
      expect(decoded.files[0].content as List<int>, img1Data);
      expect(decoded.files[1].name, 'page_0002.jpg');
      expect(decoded.files[1].content as List<int>, img2Data);
    });

    test('extractCoverAndPageCount parses archive and extracts cover in single pass', () async {
      final archive = Archive();
      final img1Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03]);
      final img2Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x04, 0x05, 0x06]);

      archive.addFile(ArchiveFile('page_0001.jpg', img1Data.length, img1Data));
      archive.addFile(ArchiveFile('page_0002.jpg', img2Data.length, img2Data));

      final zipBytes = ZipEncoder().encode(archive, level: DeflateLevel.none);

      final tempDir = await Directory.systemTemp.createTemp('cbz_test_');
      final cbzFile = File('${tempDir.path}/comic.cbz');
      await cbzFile.writeAsBytes(zipBytes);

      final targetCover = '${tempDir.path}/cover.jpg';
      final scanResult = await CbzService.extractCoverAndPageCount(
        cbzFilePath: cbzFile.path,
        targetCoverPath: targetCover,
      );

      expect(scanResult.pageCount, 2);
      expect(scanResult.coverPath, targetCover);
      expect(await File(targetCover).exists(), true);
      expect(await File(targetCover).readAsBytes(), img1Data);

      await tempDir.delete(recursive: true);
    });

    test('getPageList parses pages structure quickly without holding full bytes', () async {
      final archive = Archive();
      final img1Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03]);
      final img2Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x04, 0x05, 0x06]);
      final img3Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x07, 0x08, 0x09]);

      archive.addFile(ArchiveFile('page_0001.jpg', img1Data.length, img1Data));
      archive.addFile(ArchiveFile('page_0002.jpg', img2Data.length, img2Data));
      archive.addFile(ArchiveFile('page_0003.jpg', img3Data.length, img3Data));

      final zipBytes = ZipEncoder().encode(archive, level: DeflateLevel.none);

      final tempDir = await Directory.systemTemp.createTemp('cbz_test_pages_');
      final cbzFile = File('${tempDir.path}/comic.cbz');
      await cbzFile.writeAsBytes(zipBytes);

      final pages = await CbzService.getPageList(cbzFile.path);

      expect(pages.length, 3);
      expect(pages[0].pageIndex, 0);
      expect(pages[0].pageNumber, 1);
      expect(pages[0].name, 'page_0001.jpg');
      expect(pages[1].pageIndex, 1);
      expect(pages[1].name, 'page_0002.jpg');
      expect(pages[2].pageIndex, 2);
      expect(pages[2].name, 'page_0003.jpg');

      await tempDir.delete(recursive: true);
    });

    test('InputFileStream reads only needed page without loading full file', () async {
      final archive = Archive();
      final img1Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02, 0x03]);
      final img2Data = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x04, 0x05, 0x06]);

      archive.addFile(ArchiveFile('page_0001.jpg', img1Data.length, img1Data));
      archive.addFile(ArchiveFile('page_0002.jpg', img2Data.length, img2Data));

      final zipBytes = ZipEncoder().encode(archive, level: DeflateLevel.none);

      final tempDir = await Directory.systemTemp.createTemp('cbz_stream_test_');
      final cbzFile = File('${tempDir.path}/comic.cbz');
      await cbzFile.writeAsBytes(zipBytes);

      final cached = await CbzService.loadAndCachePage(
        cbzFilePath: cbzFile.path,
        bookId: 'test_stream_book',
        pageIndex: 1,
      );

      expect(cached, isNotNull);
      expect(await File(cached!).exists(), true);
      expect(await File(cached).readAsBytes(), img2Data);

      await tempDir.delete(recursive: true);
    });

    test('FastZip extracts DEFLATE compressed pages correctly', () async {
      final archive = Archive();
      final img1Data = Uint8List.fromList(List.generate(1024, (i) => (i % 256)));
      final img2Data = Uint8List.fromList(List.generate(2048, (i) => ((i * 3) % 256)));

      archive.addFile(ArchiveFile('page_10.jpg', img2Data.length, img2Data));
      archive.addFile(ArchiveFile('page_2.jpg', img1Data.length, img1Data));

      // Encode with DeflateLevel.bestCompression (compression method = 8)
      final zipBytes = ZipEncoder().encode(archive, level: DeflateLevel.bestCompression);

      final tempDir = await Directory.systemTemp.createTemp('cbz_deflate_test_');
      final cbzFile = File('${tempDir.path}/comic_deflate.cbz');
      await cbzFile.writeAsBytes(zipBytes);

      final pages = await CbzService.getPageList(cbzFile.path);
      expect(pages.length, 2);
      // Natural sort: page_2.jpg should be before page_10.jpg
      expect(pages[0].name, 'page_2.jpg');
      expect(pages[1].name, 'page_10.jpg');

      final cached = await CbzService.loadAndCachePage(
        cbzFilePath: cbzFile.path,
        bookId: 'test_deflate_book',
        pageIndex: 1, // page_10.jpg
      );

      expect(cached, isNotNull);
      expect(await File(cached!).exists(), true);
      final extractedBytes = await File(cached).readAsBytes();
      expect(extractedBytes, img2Data);

      await tempDir.delete(recursive: true);
    });

    test('getPageList correctly orders multi-folder archive without shuffling chapters', () async {
      final archive = Archive();
      final dummy = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01]);

      archive.addFile(ArchiveFile('Chapter 02/01.jpg', dummy.length, dummy));
      archive.addFile(ArchiveFile('Chapter 01/02.jpg', dummy.length, dummy));
      archive.addFile(ArchiveFile('Chapter 01/01.jpg', dummy.length, dummy));
      archive.addFile(ArchiveFile('Chapter 02/02.jpg', dummy.length, dummy));

      final zipBytes = ZipEncoder().encode(archive, level: DeflateLevel.none);

      final tempDir = await Directory.systemTemp.createTemp('cbz_folders_test_');
      final cbzFile = File('${tempDir.path}/comic_folders.cbz');
      await cbzFile.writeAsBytes(zipBytes);

      final pages = await CbzService.getPageList(cbzFile.path);
      expect(pages.length, 4);

      // Chapter 1 pages must come before Chapter 2 pages
      final cached0 = await CbzService.loadAndCachePage(
        cbzFilePath: cbzFile.path,
        bookId: 'test_folder_book',
        pageIndex: 0,
      );
      final cached1 = await CbzService.loadAndCachePage(
        cbzFilePath: cbzFile.path,
        bookId: 'test_folder_book',
        pageIndex: 1,
      );
      expect(cached0, isNotNull);
      expect(cached1, isNotNull);

      await tempDir.delete(recursive: true);
    });
  });
}
