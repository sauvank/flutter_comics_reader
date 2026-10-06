import 'package:comic_reader_app/screens/device_scan_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scan results group by folder and preselect likely books',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    const root = '/storage/emulated/0';
    final books = [
      const ScannedBook(
          path: '$root/Download/BD/Asterix/Asterix - T01.cbz',
          size: 1024 * 1024,
          alreadyInLibrary: false),
      const ScannedBook(
          path: '$root/Download/BD/Asterix/Asterix - T02.cbz',
          size: 1024 * 1024,
          alreadyInLibrary: true),
      const ScannedBook(
          path: '$root/Download/Facture.pdf',
          size: 2048,
          alreadyInLibrary: false),
    ];
    List<String>? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<List<String>>(
              MaterialPageRoute(
                builder: (_) =>
                    DeviceScanResultsScreen(books: books, rootPath: root),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('3 livres'), findsOneWidget);
    expect(find.text('Asterix'), findsOneWidget);
    expect(find.text('T01'), findsOneWidget);
    expect(find.text('Déjà importé'), findsOneWidget);
    // Imported books and loose PDFs are not preselected.
    expect(find.text('1 sélectionné(s)'), findsOneWidget);

    await tester.tap(find.text('Importer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(result, [books.first.path]);
  });
}
