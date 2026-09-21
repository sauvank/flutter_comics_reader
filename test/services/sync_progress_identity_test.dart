import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/services/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

BookItem _localBook(BookFormat format) => BookItem(
      id: format.name,
      title: format.name,
      originalFilename: 'book.${format.name}',
      localPath: '/media/comics/book.${format.name}',
      format: format,
      addedDate: DateTime.utc(2026),
      contentHash: 'content-sha-256',
    );

void main() {
  test('synchronizes locally imported EPUB, PDF and CBZ by content hash', () {
    for (final format in [BookFormat.epub, BookFormat.pdf, BookFormat.cbz]) {
      expect(hasProgressIdentity(_localBook(format)), isTrue);
    }
  });

  test('does not synchronize a book with no stable identity', () {
    final book = BookItem(
      id: 'unknown',
      title: 'Unknown',
      originalFilename: 'unknown.cbz',
      localPath: '/media/comics/unknown.cbz',
      format: BookFormat.cbz,
      addedDate: DateTime.utc(2026),
    );

    expect(hasProgressIdentity(book), isFalse);
  });
}
