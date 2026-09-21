import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BookItem _book() => BookItem(
      id: 'shared-book',
      title: 'Livre partagé',
      originalFilename: 'shared.cbz',
      localPath: '/tmp/shared.cbz',
      format: BookFormat.cbz,
      totalPages: 20,
      addedDate: DateTime.utc(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService().saveBooks([]);
  });

  test('serializes concurrent progress writes and preserves the latest page',
      () async {
    final database = DatabaseService();
    await database.addBook(_book());

    final first = database.updateBookProgress(
      bookId: 'shared-book',
      currentPage: 4,
      totalPages: 20,
    );
    final second = database.updateBookProgress(
      bookId: 'shared-book',
      currentPage: 9,
      totalPages: 20,
    );
    await Future.wait([first, second]);

    final stored = (await database.getBooks()).single;
    expect(stored.currentPage, 9);
    expect(stored.progress, closeTo(9 / 20, 0.0001));
  });

  test('serializes reading state changes without losing a bookmark or favorite',
      () async {
    final database = DatabaseService();
    await database.addBook(_book());

    await Future.wait([
      database.updateBookProgress(
        bookId: 'shared-book',
        currentPage: 7,
        totalPages: 20,
      ),
      database.toggleBookmark(bookId: 'shared-book', pageNumber: 7),
      database.toggleFavoriteBook('shared-book'),
    ]);

    final stored = (await database.getBooks()).single;
    expect(stored.currentPage, 7);
    expect(stored.bookmarks, [7]);
    expect(stored.isFavorite, isTrue);
  });
}
