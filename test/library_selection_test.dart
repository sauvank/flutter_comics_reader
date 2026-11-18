import 'dart:convert';

import 'package:comic_reader_app/main.dart';
import 'package:comic_reader_app/models/book_item.dart';
import 'package:comic_reader_app/widgets/series_card.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

BookItem _book(String id, String title) => BookItem(
      id: id,
      title: title,
      originalFilename: '$title.cbz',
      localPath: '/nonexistent/$id.cbz',
      format: BookFormat.cbz,
      totalPages: 10,
      addedDate: DateTime(2026, 1, 1),
    );

/// Lets real file-system futures (library loading, deletion) complete.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }
}

void main() {
  late Directory docs;
  setUpAll(() {
    docs = Directory.systemTemp.createTempSync('selection_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => docs.path);
  });
  tearDownAll(() => docs.deleteSync(recursive: true));

  setUp(() => SharedPreferences.setMockInitialValues({
        'library_books_json': jsonEncode([
          _book('a1', 'Alpha - Tome 1').toMap(),
          _book('a2', 'Alpha - Tome 2').toMap(),
          _book('b1', 'Beta - Tome 1').toMap(),
        ]),
      }));

  testWidgets('long press selects, then books can be moved and deleted',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ComicStreamApp());
    await _settleIo(tester);
    expect(find.byType(SeriesCard), findsNWidgets(2));

    // Long press a series selects all its volumes.
    await tester.longPress(find.widgetWithText(SeriesCard, 'Beta'));
    await tester.pumpAndSettle();
    expect(find.text('1 sélectionné'), findsOneWidget);

    // Move it into "Alpha".
    await tester.tap(find.byTooltip('Déplacer vers une série'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Alpha'));
    await _settleIo(tester);
    expect(find.byType(SeriesCard), findsOneWidget);
    expect(find.text('1 sélectionné'), findsNothing);

    // Select the merged series and delete its 3 books.
    await tester.longPress(find.byType(SeriesCard));
    await tester.pumpAndSettle();
    expect(find.text('3 sélectionnés'), findsOneWidget);
    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer 3 livres ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await _settleIo(tester);
    expect(find.byType(SeriesCard), findsNothing);
  });
}
