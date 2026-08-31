import 'package:flutter_test/flutter_test.dart';
import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/models/series_item.dart';

void main() {
  group('SeriesItem Tests', () {
    test('Groups books by server directory correctly', () {
      final b1 = BookItem(
        id: '1',
        title: 'Batman - 01',
        originalFilename: 'Batman 01.cbz',
        localPath: '/local/1.cbz',
        serverRelativePath: '/Comics/Batman/Batman 01.cbz',
        format: BookFormat.cbz,
        addedDate: DateTime.now(),
      );
      final b2 = BookItem(
        id: '2',
        title: 'Batman - 02',
        originalFilename: 'Batman 02.cbz',
        localPath: '/local/2.cbz',
        serverRelativePath: '/Comics/Batman/Batman 02.cbz',
        format: BookFormat.cbz,
        addedDate: DateTime.now(),
      );
      final b3 = BookItem(
        id: '3',
        title: 'One Piece - Vol 1',
        originalFilename: 'OP 01.cbz',
        localPath: '/local/3.cbz',
        serverRelativePath: '/Manga/One Piece/OP 01.cbz',
        format: BookFormat.cbz,
        addedDate: DateTime.now(),
      );

      final seriesList = SeriesItem.groupFromBooks([b1, b2, b3]);
      expect(seriesList.length, 2);

      final batman = seriesList.firstWhere((s) => s.name == 'Batman');
      expect(batman.totalBooks, 2);

      final onePiece = seriesList.firstWhere((s) => s.name == 'One Piece');
      expect(onePiece.totalBooks, 1);
    });

    test('Groups books by title pattern when no server path exists', () {
      final b1 = BookItem(
        id: '1',
        title: 'Tintin - Tome 01 - Tintin au pays des Soviets',
        originalFilename: 'Tintin 01.cbz',
        localPath: '/local/1.cbz',
        format: BookFormat.cbz,
        addedDate: DateTime.now(),
      );
      final b2 = BookItem(
        id: '2',
        title: 'Tintin - Tome 02 - Tintin au Congo',
        originalFilename: 'Tintin 02.cbz',
        localPath: '/local/2.cbz',
        format: BookFormat.cbz,
        addedDate: DateTime.now(),
      );
      final b3 = BookItem(
        id: '3',
        title: 'Tintin - Tome 10 - L\'Etoile Mystérieuse',
        originalFilename: 'Tintin 10.cbz',
        localPath: '/local/3.cbz',
        format: BookFormat.cbz,
        addedDate: DateTime.now(),
      );

      final seriesList = SeriesItem.groupFromBooks([b3, b1, b2]);
      expect(seriesList.length, 1);

      final tintin = seriesList.first;
      expect(tintin.name, 'Tintin');
      expect(tintin.totalBooks, 3);
      // Verify natural sort (Tome 01 before Tome 02 before Tome 10)
      expect(tintin.books[0].id, '1');
      expect(tintin.books[1].id, '2');
      expect(tintin.books[2].id, '3');
    });

    test('Calculates overall progress and completion status correctly', () {
      final b1 = BookItem(
        id: '1',
        title: 'Spidey #1',
        originalFilename: 'spidey1.cbz',
        localPath: '/local/1.cbz',
        format: BookFormat.cbz,
        progress: 1.0,
        isCompleted: true,
        addedDate: DateTime.now(),
      );
      final b2 = BookItem(
        id: '2',
        title: 'Spidey #2',
        originalFilename: 'spidey2.cbz',
        localPath: '/local/2.cbz',
        format: BookFormat.cbz,
        progress: 0.5,
        isCompleted: false,
        addedDate: DateTime.now(),
      );

      final seriesList = SeriesItem.groupFromBooks([b1, b2]);
      final spidey = seriesList.first;

      expect(spidey.completedBooks, 1);
      expect(spidey.inProgressBooks, 1);
      expect(spidey.isCompleted, false);
      expect(spidey.overallProgress, 0.75);
      expect(spidey.nextToReadBook?.id, '2');
    });
  });
}
