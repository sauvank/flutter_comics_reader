import 'package:comic_reader_app/models/book_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores progress from the synchronized page count', () {
    final book = BookItem.fromMap({
      'id': 'book',
      'title': 'Test',
      'localPath': '/tmp/test.cbz',
      'format': 'cbz',
      'totalPages': 80,
      'currentPage': 37,
      // Simulates records written by versions that did not update progress.
      'progress': 0.0,
      'addedDate': DateTime.utc(2026).toIso8601String(),
    });

    expect(book.progress, closeTo(37 / 80, 0.0001));
  });
}
