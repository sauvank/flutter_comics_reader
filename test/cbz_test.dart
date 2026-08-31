import 'dart:typed_data';
import 'package:archive/archive.dart';
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
  });
}
