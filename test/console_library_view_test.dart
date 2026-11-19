import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/models/series_item.dart';
import 'package:comic_reader_app/providers/library_provider.dart';
import 'package:comic_reader_app/widgets/console_library_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

BookItem _book(String series, int n, {double progress = 0}) => BookItem(
      id: '$series-$n',
      title: '$series - Tome $n',
      originalFilename: '$series - Tome $n.cbz',
      localPath: '/nonexistent/$series-$n.cbz',
      format: BookFormat.cbz,
      totalPages: 10,
      progress: progress,
      addedDate: DateTime(2026, 1, 1),
    );

SeriesItem _series(String name, int count) => SeriesItem(
    name: name, books: [for (var i = 1; i <= count; i++) _book(name, i)]);

void main() {
  Future<List<BookItem>> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <BookItem>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConsoleLibraryView(
          series: [
            _series('Akira', 6),
            _series('Batman', 3),
            _series('Saga', 9)
          ],
          filter: LibraryFilter.all,
          onFilter: (_) {},
          onOpenBook: opened.add,
          onOpenSeries: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    return opened;
  }

  for (final size in const [Size(1440, 900), Size(1000, 640)]) {
    testWidgets('renders without overflow at $size', (tester) async {
      await pump(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Akira'), findsWidgets);
    });
  }

  testWidgets('keyboard: next series, then open its first volume',
      (tester) async {
    final opened = await pump(tester, const Size(1440, 900));
    Future<void> key(LogicalKeyboardKey k) async {
      await tester.sendKeyEvent(k);
      await tester.pump(const Duration(milliseconds: 600));
    }

    await key(LogicalKeyboardKey.arrowRight);
    expect(find.text('Batman'), findsWidgets);
    await key(LogicalKeyboardKey.enter); // series -> actions
    await key(LogicalKeyboardKey.enter); // primary action
    expect(opened.single.id, 'Batman-1');

    await key(LogicalKeyboardKey.arrowDown); // volumes row
    await key(LogicalKeyboardKey.arrowRight);
    await key(LogicalKeyboardKey.enter);
    expect(opened.last.id, 'Batman-2');
  });

  testWidgets('filter keys follow the layout: A/E printed in French',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final filters = <LibraryFilter>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConsoleLibraryView(
          series: [_series('Akira', 2)],
          filter: LibraryFilter.all,
          onFilter: filters.add,
          onOpenBook: (_) {},
          onOpenSeries: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('A'), findsWidgets);
    expect(find.text('Q'), findsNothing);

    // AZERTY: the key left of E is physically "KeyQ" and prints "a".
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyQ);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.pump(const Duration(milliseconds: 500));
    expect(filters, [LibraryFilter.completed, LibraryFilter.inProgress]);
  });
}
