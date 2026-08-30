import 'package:flutter_test/flutter_test.dart';
import 'package:comic_reader_app/models/book_item.dart';

void main() {
  group('BookFormat EPUB Tests', () {
    test('formatFromExtension recognizes .epub correctly', () {
      expect(BookItem.formatFromExtension('book.epub'), BookFormat.epub);
      expect(BookItem.formatFromExtension('Dune - T01.EPUB'), BookFormat.epub);
      expect(BookItem.formatFromExtension('/path/to/novel.epub'), BookFormat.epub);
    });

    test('formatString returns EPUB for BookFormat.epub', () {
      final book = BookItem(
        id: 'test_epub',
        title: 'Dune',
        originalFilename: 'dune.epub',
        localPath: '/books/dune.epub',
        format: BookFormat.epub,
        addedDate: DateTime.now(),
      );
      expect(book.formatString, 'EPUB');
    });
  });
}
