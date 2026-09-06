import 'package:flutter_test/flutter_test.dart';
import 'package:comic_reader_app/utils/format_utils.dart';

void main() {
  group('NaturalSort & FormatUtils Tests', () {
    test('NaturalSort sorts page numbers correctly', () {
      final pages = ['page10.jpg', 'page2.jpg', 'page1.jpg', 'page20.jpg', 'page3.jpg'];
      pages.sort(NaturalSort.compare);

      expect(pages, ['page1.jpg', 'page2.jpg', 'page3.jpg', 'page10.jpg', 'page20.jpg']);
    });

    test('NaturalSort handles complex chapter and page names', () {
      final files = ['Tome_1_ch10_p02.png', 'Tome_1_ch2_p1.png', 'Tome_1_ch10_p01.png', 'Tome_1_ch2_p10.png'];
      files.sort(NaturalSort.compare);

      expect(files, ['Tome_1_ch2_p1.png', 'Tome_1_ch2_p10.png', 'Tome_1_ch10_p01.png', 'Tome_1_ch10_p02.png']);
    });

    test('NaturalSort sorts folder hierarchy correctly without shuffling', () {
      final paths = [
        'Chapter 02/02.jpg',
        'Chapter 01/01.jpg',
        'Chapter 02/01.jpg',
        'Chapter 01/02.jpg',
        'Chapter 01/03.jpg',
      ];
      paths.sort(NaturalSort.compare);

      expect(paths, [
        'Chapter 01/01.jpg',
        'Chapter 01/02.jpg',
        'Chapter 01/03.jpg',
        'Chapter 02/01.jpg',
        'Chapter 02/02.jpg',
      ]);
    });

    test('FormatUtils formats bytes correctly', () {
      expect(FormatUtils.formatBytes(500), '500.0 B');
      expect(FormatUtils.formatBytes(1024 * 1024 * 45), '45.0 MB');
      expect(FormatUtils.formatBytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('FormatUtils formats download speed', () {
      expect(FormatUtils.formatSpeed(1024 * 1024 * 5.5), '5.5 MB/s');
    });
  });
}
