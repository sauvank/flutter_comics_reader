import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:comic_reader_app/services/cbz_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  });
}
