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

  test('persists an EPUB chapter position independently of pixel offsets', () {
    final book = BookItem.fromMap({
      'id': 'epub',
      'title': 'Roman',
      'localPath': '/tmp/roman.epub',
      'format': 'epub',
      'totalPages': 10,
      'currentPage': 2,
      'epubChapterProgress': 0.5,
      'addedDate': DateTime.utc(2026).toIso8601String(),
    });

    expect(book.currentPage, 2);
    expect(book.epubChapterProgress, 0.5);
    expect(book.progress, closeTo(0.25, 0.0001));

    final restored = BookItem.fromMap(book.toMap());
    expect(restored.epubChapterProgress, 0.5);
    expect(restored.progress, closeTo(0.25, 0.0001));
  });
}
